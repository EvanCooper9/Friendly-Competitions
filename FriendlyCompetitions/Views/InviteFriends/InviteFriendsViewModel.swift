import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class InviteFriendsViewModel: ObservableObject {

    struct RowConfig: Identifiable {
        let id: String
        let name: String
        let pillId: String
        var buttonTitle: String
        var buttonDisabled: Bool
        let buttonAction: () -> Void
    }

    // MARK: - Public Properties

    @Published var loading = false
    @Published var showEmpty = false
    @Published var rows = [RowConfig]()
    @Published var searchText = ""

    // MARK: - Private Properties

    @Injected(\.api) private var api
    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.friendsManager) private var friendsManager
    @Injected(\.scheduler) private var scheduler
    @Injected(\.searchManager) private var searchManager
    @Injected(\.userManager) private var userManager

    private let acceptSubject = PassthroughSubject<User, Never>()
    private let inviteSubject = PassthroughSubject<User, Never>()
    private let shareSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(action: InviteFriendsAction) {
        let alreadyInvited: AnyPublisher<[User.ID], Never>
        let incomingRequests: AnyPublisher<[User.ID], Never>

        switch action {
        case .addFriend:
            alreadyInvited = userManager.userPublisher
                .map { $0.friends + $0.outgoingFriendRequests }
                .eraseToAnyPublisher()
            incomingRequests = userManager.userPublisher
                .map(\.incomingFriendRequests)
                .eraseToAnyPublisher()
        case .competitionInvite(let competition):
            alreadyInvited = competitionsManager.competitionPublisher(for: competition.id)
                .map { $0.participants + $0.pendingParticipants }
                .catchErrorJustReturn([])
                .share(replay: 1)
                .eraseToAnyPublisher()
            incomingRequests = .just([])
        }

        $searchText
            .handleEvents(withUnretained: self, receiveOutput: { strongSelf, searchText in
                strongSelf.loading = !searchText.isEmpty
                strongSelf.showEmpty = false
            })
            .debounce(for: .seconds(0.5), scheduler: scheduler)
            .flatMapLatest(withUnretained: self) { strongSelf, searchText -> AnyPublisher<[User], Never> in
                guard !searchText.isEmpty else {
                    strongSelf.loading = false
                    return .just([])
                }
                return strongSelf.searchManager
                    .searchForUsers(byName: searchText)
                    .isLoading { strongSelf.loading = $0 }
                    .catchErrorJustReturn([])
                    .eraseToAnyPublisher()
            }
            .prepend([])
            .combineLatest(alreadyInvited.print("already"), incomingRequests.print("incoming"), friendsManager.friends.print("friends"))
            .map { [weak self] users, alreadyInvited, incomingRequests, friends -> [RowConfig] in
                (users + friends).map { friend in
                    let hasIncomingInvite = incomingRequests.contains(friend.id)
                    return RowConfig(
                        id: friend.id,
                        name: friend.name,
                        pillId: friend.hashId,
                        buttonTitle: hasIncomingInvite ?
                            L10n.InviteFriends.accept :
                            (alreadyInvited.contains(friend.id) ? L10n.InviteFriends.invited : L10n.InviteFriends.invite),
                        buttonDisabled: alreadyInvited.contains(friend.id),
                        buttonAction: { [friend] in
                            switch action {
                            case .addFriend:
                                if hasIncomingInvite {
                                    self?.acceptSubject.send(friend)
                                } else {
                                    self?.inviteSubject.send(friend)
                                }
                            case .competitionInvite:
                                self?.inviteSubject.send(friend)
                            }
                        }
                    )
                }
            }
            .receive(on: scheduler)
            .assign(to: &$rows)

        acceptSubject
            .flatMapLatest(withUnretained: self) { strongSelf, user -> AnyPublisher<Void, Never> in
                switch action {
                case .addFriend:
                    return strongSelf.api
                        .call(.respondToFriendRequest(from: user.id, accept: true))
                        .isLoading { strongSelf.loading = $0 }
                        .ignoreFailure()
                case .competitionInvite:
                    return .never()
                }
            }
            .sink()
            .store(in: &cancellables)

        inviteSubject
            .flatMapLatest(withUnretained: self) { strongSelf, user -> AnyPublisher<Void, Never> in
                switch action {
                case .addFriend:
                    return strongSelf.api
                        .call(.sendFriendRequest(id: user.id))
                        .isLoading { strongSelf.loading = $0 }
                        .ignoreFailure()
                case .competitionInvite(let competition):
                    return strongSelf.api
                        .call(.inviteUserToCompetition(competitionID: competition.id, userID: user.id))
                        .isLoading { strongSelf.loading = $0 }
                        .ignoreFailure()
                }
            }
            .sink()
            .store(in: &cancellables)

        shareSubject
            .sink(withUnretained: self) { strongSelf in
                let deepLink: DeepLink?
                switch action {
                case .addFriend:
                    deepLink = .user(id: strongSelf.userManager.user.id)
                case .competitionInvite(let competition):
                    deepLink = .competition(id: competition.id)
                }
                deepLink?.share()
            }
            .store(in: &cancellables)

        $rows
            .withLatestFrom($searchText) { ($0, $1) }
            .map { rows, searchText in
                !searchText.isEmpty && rows.isEmpty
            }
            .assign(to: &$showEmpty)
    }

    // MARK: - Publie Methods

    func sendInviteLink() {
        shareSubject.send()
    }
}
