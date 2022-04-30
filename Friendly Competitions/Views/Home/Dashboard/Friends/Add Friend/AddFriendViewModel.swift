import Combine
import CombineExt
import Resolver

final class AddFriendViewModel: ObservableObject {
    
    @Published private(set) var friendReferral: User?
    @Published var searchText = ""
    @Published var searchResults = [User]()
    @Published private(set) var user: User!

    private(set) var referralItems: [Any]!
    
    @Injected private var appState: AppState
    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var userManager: AnyUserManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.user = userManager.user
        self.referralItems = [
            "Add me in Friendly Competitions!",
            DeepLink.friendReferral(id: user.id).url
        ]
        
        userManager.$user
            .map { $0 as User? }
            .assign(to: &$user)
    
        $searchText
            .sinkAsync { [weak self] searchText in
                guard let self = self else { return }
                let searchResults = try await self.friendsManager.search(with: searchText)
                DispatchQueue.main.async { [searchResults] in
                    self.searchResults = searchResults
                }
            }
            .store(in: &cancellables)
        
        handleDeepLink()
    }
    
    func add(_ friend: User) {
        friendsManager.add(friend: friend)
    }
    
    // MARK: Private Methods
    
    private func handleDeepLink() {
        guard case let .friendReferral(referralId) = appState.deepLink else { return }
        Task { [weak self] in
            guard let self = self else { return }
            let friendReferral = try await self.friendsManager.user(withId: referralId)
            DispatchQueue.main.async { [friendReferral] in
                self.friendReferral = friendReferral
                self.appState.deepLink = nil
            }
        }
    }
}
