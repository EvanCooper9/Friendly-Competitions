import Combine
import CombineExt
import ECKit
import Factory

final class NewCompetitionViewModel: ObservableObject {

    private enum Constants {
        static let defaultInterval: TimeInterval = 7
    }
    
    struct InviteFriendsRow: Identifiable {
        let id: String
        let name: String
        var invited: Bool
        let onTap: () -> Void
    }

    // MARK: - Public Properties
    
    @Published var competition: Competition
    @Published private(set) var friendRows = [InviteFriendsRow]()
    @Published private(set) var dismiss = false
    
    var createDisabled: Bool { disabledReason != nil }
    var disabledReason: String? {
        if competition.name.isEmpty {
            return "Please enter a name"
        } else if !competition.isPublic && competition.pendingParticipants.isEmpty {
            return "Please invite at least 1 friend"
        }
        return nil
    }

    // MARK: - Private Properties
    
    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.friendsManager) private var friendsManager
    @Injected(Container.userManager) private var userManager

    private let _create = PassthroughSubject<Void, Never>()
    private var cancellables = Cancellables()

    // MARK: - Lifecycle
        
    init() {
        competition = .init(
            name: "Test",
            owner: "",
            participants: [],
            pendingParticipants: [],
            scoringModel: .workout(.walking, [.distance, .heartRate, .steps]),
            start: .now.advanced(by: -10.days),
            end: .now.advanced(by: Constants.defaultInterval.days + 1.days),
            repeats: false,
            isPublic: true,
            banner: nil
        )

        Publishers
            .CombineLatest(friendsManager.friends, $competition)
            .map { friends, competition in
                friends.map { friend in
                    InviteFriendsRow(
                        id: friend.id,
                        name: friend.name,
                        invited: competition.pendingParticipants.contains(friend.id),
                        onTap: {
                            self.competition.pendingParticipants.toggle(friend.id)
                        }
                    )
                }
            }
            .assign(to: &$friendRows)

        _create
            .withLatestFrom(userManager.user)
            .setFailureType(to: Error.self)
            .flatMapLatest(withUnretained: self) { strongSelf, user -> AnyPublisher<Void, Error> in
                var competition = strongSelf.competition
                competition.owner = user.id
                competition.participants = [user.id]
                strongSelf.competition = competition
                return strongSelf.competitionsManager.create(competition)
            }
            .sink(withUnretained: self) { $0.dismiss = true }
            .store(in: &cancellables)
    }

    // MARK: - Public Properties
    
    func create() {
        _create.send()
    }
}
