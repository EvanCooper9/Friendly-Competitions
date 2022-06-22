import Combine
import CombineExt
import Resolver

final class UserViewModel: ObservableObject {
    
    @Published var title: String
    @Published var activitySummary: ActivitySummary?
    @Published var showDeleteConfirmation = false
    @Published var statistics: User.Statistics
    @Published var actions = [UserViewAction]()
    @Published var confirmationRequired = false
    
    private var actionRequiringConfirmation: UserViewAction? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }

    @Injected private var friendsManager: FriendsManaging
    @Injected private var userManager: UserManaging

    private var _confirm = PassthroughSubject<Void, Error>()
    private var _perform = PassthroughSubject<UserViewAction, Error>()
    
    private let user: User
    private var cancellables = Set<AnyCancellable>()
    
    init(user: User) {
        self.user = user
        title = user.name
        statistics = user.statistics ?? .zero
        
        friendsManager.friendActivitySummaries
            .compactMap { $0[user.id] }
            .assign(to: &$activitySummary)
        
        userManager.user
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

        _confirm
            .flatMapLatest(withUnretained: self) { object -> AnyPublisher<Void, Error> in
                switch object.actionRequiringConfirmation {
                case .deleteFriend:
                    return object.friendsManager.delete(friend: self.user)
                default:
                    return .empty()
                }
            }
            .sink()
            .store(in: &cancellables)

        _perform
            .flatMapLatest(withUnretained: self) { object, action -> AnyPublisher<Void, Error> in
                switch action {
                case .acceptFriendRequest:
                    return object.friendsManager.acceptFriendRequest(from: user)
                case .denyFriendRequest:
                    return object.friendsManager.declineFriendRequest(from: user)
                case .request:
                    return object.friendsManager.add(friend: user)
                case .deleteFriend:
                    object.actionRequiringConfirmation = .deleteFriend
                    return .empty()
                }
            }
            .sink()
            .store(in: &cancellables)
    }
    
    func confirm() {
        _confirm.send()
    }
    
    func perform(_ action: UserViewAction) {
        _perform.send(action)
    }
}
