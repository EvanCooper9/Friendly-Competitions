import Combine
import CombineExt
import Resolver

final class InviteFriendsViewModel: ObservableObject {
    
    struct RowConfig: Identifiable {
        let id: String
        let name: String
        let pillId: String
        var buttonTitle: String
        var buttonDisabled: Bool
        let buttonAction: () -> Void
    }
    
    @Published var footerText: String?
    @Published var rows = [RowConfig]()
    @Published var searchText = ""
    @Published var sharedDeepLink: DeepLink?

    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var userManager: AnyUserManager
    
    private var action: InviteFriendsAction
    
    init(action: InviteFriendsAction) {
        self.action = action
        
        let alreadyInvited: [String]
        let hidden: [String]
        
        switch action {
        case .addFriend:
            alreadyInvited = friendsManager.friends.map(\.id)
            hidden = friendsManager.friends.map(\.id).appending(userManager.user.id)
        case .competitionInvite(let competition):
            alreadyInvited = competition.participants + competition.pendingParticipants
            hidden = [userManager.user.id]
            footerText = "People who join in-progress competitions will have their scores from missed days retroactively uploaded."
        }
        
        $searchText
            .flatMapAsync { [weak self] searchText in
                guard let self = self else { return [] }
                guard !searchText.isEmpty else { return self.friendsManager.friends }
                return try await self.friendsManager.search(with: searchText)
            }
            .prepend(friendsManager.friends)
            .map { users -> [RowConfig] in
                users
                    .filter { !hidden.contains($0.id) }
                    .map { friend in
                        RowConfig(
                            id: friend.id,
                            name: friend.name,
                            pillId: friend.hashId,
                            buttonTitle: alreadyInvited.contains(friend.id) ? "Invited" : "Invite",
                            buttonDisabled: alreadyInvited.contains(friend.id),
                            buttonAction: { [friend] in
                                guard let index = self.rows.firstIndex(where: { $0.id == friend.id }) else { return }
                                self.rows[index].buttonDisabled.toggle()
                                self.rows[index].buttonTitle = self.rows[index].buttonDisabled ? "Invited" : "Invite"
                                self.invite(friend: friend)
                            }
                        )
                    }
            }
            .ignoreFailure()
            .assign(to: &$rows)
    }
    
    func sendInviteLink() {
        sharedDeepLink = nil
        switch action {
        case .addFriend:
            sharedDeepLink = .friendReferral(id: userManager.user.id)
        case .competitionInvite(let competition):
            sharedDeepLink = .competitionInvite(id: competition.id)
        }
    }
    
    private func invite(friend: User) {
        switch action {
        case .addFriend:
            friendsManager.add(friend: friend)
        case .competitionInvite(let competition):
            competitionsManager.invite(friend, to: competition)
        }
    }
}
