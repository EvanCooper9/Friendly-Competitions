import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class NewCompetitionViewModel: ObservableObject {

    private enum Constants {
        static let defaultInterval: TimeInterval = 7.days
    }

    struct InviteFriendsRow: Identifiable {
        let id: String
        let name: String
        var invited: Bool

        mutating func onTap() {
            invited.toggle()
        }
    }

    // MARK: - Public Properties

    @Published var name = ""
    @Published var scoringModel: Competition.ScoringModel = .percentOfGoals
    @Published var start: Date = .now.advanced(by: 1.days)
    @Published var end: Date = .now.advanced(by: 8.days)
    @Published var repeats = true
    @Published var isPublic = false
    @Published var friendRows = [InviteFriendsRow]()
    @Published private(set) var createDisabled = true
    @Published private(set) var disabledReason: String?

    @Published private(set) var loading = false
    @Published private(set) var dismiss = false

    // MARK: - Private Properties

    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.friendsManager) private var friendsManager
    @Injected(\.userManager) private var userManager

    private let createSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {

        friendsManager.friends
            .mapMany { friend in
                InviteFriendsRow(
                    id: friend.id,
                    name: friend.name,
                    invited: false
                )
            }
            .assign(to: &$friendRows)

        let inputs = Publishers
            .CombineLatest3(
                Publishers.CombineLatest4($name, $scoringModel, $start, $end),
                Publishers.CombineLatest3($repeats, $isPublic, $friendRows),
                userManager.userPublisher
            )
            .map { result1, result2, user in
                let (name, scoringModel, start, end) = result1
                let (repeats, isPublic, friendRows) = result2
                return (name, scoringModel, start, end, repeats, isPublic, friendRows, user)
            }

        let disabledReason = inputs
            .map { name, _, _, _, _, isPublic, friendRows, _ -> String? in
                if name.isEmpty {
                    return L10n.NewCompetition.Disabled.name
                } else if !isPublic && friendRows.filter(\.invited).isEmpty {
                    return L10n.NewCompetition.Disabled.inviteFriend
                }
                return nil
            }
        disabledReason.assign(to: &$disabledReason)
        disabledReason.map { $0 != nil }.assign(to: &$createDisabled)

        let competition = inputs
            .map { name, scoringModel, start, end, repeats, isPublic, friendRows, user in
                Competition(
                    name: name,
                    owner: user.id,
                    participants: [user.id],
                    pendingParticipants: friendRows.filter(\.invited).map(\.id),
                    scoringModel: scoringModel,
                    start: start,
                    end: end,
                    repeats: repeats,
                    isPublic: isPublic,
                    banner: nil
                )
            }

        createSubject
            .withLatestFrom(competition)
            .setFailureType(to: Error.self)
            .flatMapLatest(withUnretained: self) { strongSelf, competition in
                strongSelf.competitionsManager
                    .create(competition)
                    .isLoading { strongSelf.loading = $0 }
                    .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .sink(withUnretained: self) { $0.dismiss = true }
            .store(in: &cancellables)
    }

    // MARK: - Public Properties

    func create() {
        createSubject.send()
    }
}
