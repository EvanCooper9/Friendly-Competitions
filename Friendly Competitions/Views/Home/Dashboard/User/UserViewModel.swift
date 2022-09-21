import Combine
import CombineExt
import ECKit

final class UserViewModel: ObservableObject {
    
    @Published var title: String
    @Published var activitySummary: ActivitySummary?
    @Published var showDeleteConfirmation = false
    @Published var statistics: User.Statistics
    @Published var actions = [UserViewAction]()
    @Published var confirmationRequired = false
    @Published var loading = false
    
    private var actionRequiringConfirmation: UserViewAction? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }

    private var _confirm = PassthroughSubject<Void, Never>()
    private var _perform = PassthroughSubject<UserViewAction, Never>()
    
    private let user: User
    private var cancellables = Cancellables()
    
    init(friendsManager: FriendsManaging, userManager: UserManaging, user: User) {
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
            .flatMapLatest(withUnretained: self) { strongSelf -> AnyPublisher<Void, Never> in
                switch strongSelf.actionRequiringConfirmation {
                case .deleteFriend:
                    return friendsManager
                        .delete(friend: strongSelf.user)
                        .receive(on: RunLoop.main)
                        .isLoading { [weak self] in self?.loading = $0 }
                        .ignoreFailure()
                default:
                    return .empty()
                }
            }
            .sink()
            .store(in: &cancellables)

        _perform
            .flatMapLatest(withUnretained: self) { strongSelf, action -> AnyPublisher<Void, Never> in
                switch action {
                case .acceptFriendRequest:
                    return friendsManager
                        .accept(friendRequest: user)
                        .receive(on: RunLoop.main)
                        .isLoading { [weak self] in self?.loading = $0 }
                        .ignoreFailure()
                case .denyFriendRequest:
                    return friendsManager
                        .decline(friendRequest: user)
                        .receive(on: RunLoop.main)
                        .isLoading { [weak self] in self?.loading = $0 }
                        .ignoreFailure()
                case .request:
                    return friendsManager
                        .add(user: user)
                        .receive(on: RunLoop.main)
                        .isLoading { [weak self] in self?.loading = $0 }
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
        _confirm.send()
    }
    
    func perform(_ action: UserViewAction) {
        _perform.send(action)
    }
}
