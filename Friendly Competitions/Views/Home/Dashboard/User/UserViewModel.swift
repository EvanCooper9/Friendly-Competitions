import Combine
import CombineExt
import ECKit
import Factory

final class UserViewModel: ObservableObject {
    
    @Published var title: String
    @Published var activitySummary: ActivitySummary?
    @Published var showDeleteConfirmation = false
    @Published var statistics: User.Statistics
    @Published var actions = [UserViewAction]()
    @Published var confirmationRequired = false
    @Published var loading = false
    
    // MARK: - Private Properties
    
    private var actionRequiringConfirmation: UserViewAction? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }
    
    @Injected(Container.friendsManager) private var friendsManager
    @Injected(Container.userManager) private var userManager

    private var _confirm = PassthroughSubject<Void, Never>()
    private var _perform = PassthroughSubject<UserViewAction, Never>()
    
    private let user: User
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle
    
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
            .flatMapLatest(withUnretained: self) { strongSelf -> AnyPublisher<Void, Never> in
                switch strongSelf.actionRequiringConfirmation {
                case .deleteFriend:
                    return strongSelf.friendsManager
                        .delete(friend: strongSelf.user)
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
                    return strongSelf.friendsManager
                        .accept(friendRequest: user)
                        .isLoading { [weak self] in self?.loading = $0 }
                        .ignoreFailure()
                case .denyFriendRequest:
                    return strongSelf.friendsManager
                        .decline(friendRequest: user)
                        .isLoading { [weak self] in self?.loading = $0 }
                        .ignoreFailure()
                case .request:
                    return strongSelf.friendsManager
                        .add(user: user)
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
