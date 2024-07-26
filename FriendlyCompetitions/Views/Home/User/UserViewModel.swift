import Combine
import CombineExt
import ECKit
import Factory

final class UserViewModel: ObservableObject {

    @Published var title: String
    @Published var activitySummary: ActivitySummary?
    @Published var showDeleteConfirmation = false
    @Published var medals: User.Medals
    @Published var actions = [UserViewAction]()
    @Published var confirmationRequired = false
    @Published var loading = false
    @Published private(set) var dismiss = false

    // MARK: - Private Properties

    private var actionRequiringConfirmation: UserViewAction? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }

    @Injected(\.api) private var api: API
    @Injected(\.friendsManager) private var friendsManager: FriendsManaging
    @Injected(\.userManager) private var userManager: UserManaging

    private var confimActionSubject = PassthroughSubject<Void, Never>()
    private var performActionSubject = PassthroughSubject<UserViewAction, Never>()
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(user: User) {
        title = user.name
        medals = user.statistics ?? .zero

        friendsManager.friendActivitySummaries
            .compactMap { $0[user.id] }
            .assign(to: &$activitySummary)

        userManager.userPublisher
            .map { loggedInUser in
                if loggedInUser.friends.contains(user.id) {
                    return [.deleteFriend]
                } else if loggedInUser.incomingFriendRequests.contains(user.id) {
                    return [.acceptFriendRequest, .denyFriendRequest]
                } else {
                    return [.request]
                }
            }
            .assign(to: &$actions)

        confimActionSubject
            .flatMapLatest(withUnretained: self) { strongSelf -> AnyPublisher<Void, Never> in
                switch strongSelf.actionRequiringConfirmation {
                case .deleteFriend:
                    return strongSelf.api
                        .call(.deleteFriend(id: user.id))
                        .isLoading { strongSelf.loading = $0 }
                        .handleEvents(withUnretained: self, receiveOutput: { strongSelf in
                            strongSelf.dismiss = true
                        })
                        .ignoreFailure()
                default:
                    return .empty()
                }
            }
            .sink()
            .store(in: &cancellables)

        performActionSubject
            .flatMapLatest(withUnretained: self) { strongSelf, action -> AnyPublisher<Void, Never> in
                switch action {
                case .acceptFriendRequest:
                    return strongSelf.api
                        .call(.respondToFriendRequest(from: user.id, accept: true))
                        .isLoading { strongSelf.loading = $0 }
                        .ignoreFailure()
                case .denyFriendRequest:
                    return strongSelf.api
                        .call(.respondToFriendRequest(from: user.id, accept: false))
                        .isLoading { strongSelf.loading = $0 }
                        .handleEvents(withUnretained: self, receiveOutput: { strongSelf in
                            strongSelf.dismiss = true
                        })
                        .ignoreFailure()
                case .request:
                    return strongSelf.api
                        .call(.sendFriendRequest(id: user.id))
                        .isLoading { strongSelf.loading = $0 }
                        .ignoreFailure()
                case .deleteFriend:
                    strongSelf.actionRequiringConfirmation = .deleteFriend
                    return .empty()
                }
            }
            .sink()
            .store(in: &cancellables)
    }

    func confirm() {
        confimActionSubject.send()
    }

    func perform(_ action: UserViewAction) {
        performActionSubject.send(action)
    }
}
