import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class CompetitionEditViewModel: ObservableObject {

    struct FriendRow: Identifiable {
        let user: User
        var selected: Bool

        var id: User.ID { user.id }

        mutating func select() {
            selected.toggle()
        }
    }

    private enum EditState {
        case new
        case update(Competition)
    }

    // MARK: - Public Properties

    @Published var name: String
    @Published var scoringModel: Competition.ScoringModel
    @Published var start: Date
    @Published var end: Date
    @Published var repeats: Bool
    @Published var isPublic: Bool

    @Published var showInviteFriends = false
    @Published var friendRows = [FriendRow]()
    var invitedFriendsCount: Int { friendRows.filter(\.selected).count }

    let title: String
    let submitButtonTitle: String

    @Published private(set) var loading = false
    @Published private(set) var dismiss = false
    @Published private(set) var submitDisabled = false

    // MARK: - Private Properties

    private let editState: EditState

    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.searchManager) private var searchManager
    @Injected(\.userManager) private var userManager

    private let createSubject = PassthroughSubject<Void, Never>()
    private let updateSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(competition: Competition?) {
        if let competition {
            name = competition.name
            scoringModel = competition.scoringModel
            start = competition.start
            end = competition.end
            repeats = competition.repeats
            isPublic = competition.isPublic

            title = "Edit Competition"
            submitButtonTitle = "Update"

            editState = .update(competition)
        } else {
            name = ""
            scoringModel = .percentOfGoals
            start = .now.advanced(by: 1.days)
            end = .now.advanced(by: 8.days)
            repeats = true
            isPublic = false

            showInviteFriends = true

            title = "New Competition"
            submitButtonTitle = "Create"

            editState = .new

            userManager.userPublisher
                .map(\.friends)
                .flatMapLatest(withUnretained: self) { strongSelf, friendIDs in
                    strongSelf.searchManager
                        .searchForUsers(withIDs: friendIDs)
                        .ignoreFailure()
                        .eraseToAnyPublisher()
                }
                .mapMany { FriendRow(user: $0, selected: false) }
                .assign(to: &$friendRows)
        }

        createSubject
            .flatMapLatest(withUnretained: self) { strongSelf -> AnyPublisher<Void, Never> in
                let invitedFriends = strongSelf.friendRows
                    .filter(\.selected)
                    .map(\.user.id)

                let competition = Competition(
                    name: strongSelf.name,
                    owner: strongSelf.userManager.user.id,
                    participants: [strongSelf.userManager.user.id],
                    pendingParticipants: invitedFriends,
                    scoringModel: strongSelf.scoringModel,
                    start: strongSelf.start,
                    end: strongSelf.end,
                    repeats: strongSelf.repeats,
                    isPublic: strongSelf.isPublic,
                    banner: nil
                )

                return strongSelf.competitionsManager
                    .create(competition)
                    .isLoading { strongSelf.loading = $0 }
                    .ignoreFailure()
                    .eraseToAnyPublisher()
            }
            .sink(withUnretained: self) { $0.dismiss = true }
            .store(in: &cancellables)

        updateSubject
            .flatMapLatest(withUnretained: self) { strongSelf -> AnyPublisher<Void, Never> in
                guard var competition = competition else { return  .never() }
                competition.name = strongSelf.name
                competition.scoringModel = strongSelf.scoringModel
                competition.start = strongSelf.start
                competition.end = strongSelf.end
                competition.repeats = strongSelf.repeats
                competition.isPublic = strongSelf.isPublic

                return strongSelf.competitionsManager
                    .update(competition)
                    .isLoading { strongSelf.loading = $0 }
                    .ignoreFailure()
                    .eraseToAnyPublisher()
            }
            .sink(withUnretained: self) { $0.dismiss = true }
            .store(in: &cancellables)

        $name
            .map { $0.isEmpty }
            .assign(to: &$submitDisabled)
    }

    // MARK: - Public Methods

    func inviteFriendsTapped() {
        showInviteFriends.toggle()
    }

    func cancelTapped() {
        dismiss = true
    }

    func submitTapped() {
        switch editState {
        case .new:
            createSubject.send()
        case .update:
            updateSubject.send()
        }
    }
}
