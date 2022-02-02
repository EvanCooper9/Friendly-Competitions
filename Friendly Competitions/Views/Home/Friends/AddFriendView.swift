import SwiftUI
import Resolver

struct AddFriendView: View {

    var sharedFriendId: String?

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var friendsManager: AnyFriendsManager
    @EnvironmentObject private var user: User

    var body: some View {
        List {
            Section {
                ForEach(friendsManager.searchResults) { friend in
                    AddFriendListItem(
                        friend: friend,
                        action: .friendRequest,
                        disabledIf: friend.incomingFriendRequests.contains(user.id)
                    ) { friendsManager.add(friend: friend) }
                }
            } footer: {
                HStack {
                    Text("Having trouble?")
                    Button("Send an invite link", action: share)
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $friendsManager.searchText)
        .navigationTitle("Search for Friends")
        .embeddedInNavigationView()
    }

    private func share() {
        Task {
            let activityVC = UIActivityViewController(
                activityItems: [
                    "Add me in Friendly Competitions!",
                    "friendly-competitions://invite/\(user.id)"
                ],
                applicationActivities: nil
            )
            activityVC.excludedActivityTypes = [.mail, .addToReadingList, .assignToContact, .markupAsPDF, .openInIBooks, .saveToCameraRoll, .print]

            DispatchQueue.main.async {
                let keyWindow = UIApplication.shared.connectedScenes
                        .filter { $0.activationState == .foregroundActive }
                        .compactMap { $0 as? UIWindowScene }
                        .first?
                        .windows
                        .filter(\.isKeyWindow)
                        .first

                keyWindow?.rootViewController?
                    .topViewController
                    .present(activityVC, animated: true, completion: nil)
            }
        }
    }
}

struct AddFriendView_Previews: PreviewProvider {

    private static let friendsManager: AnyFriendsManager = {
        let friend = User.gabby
        friend.tempActivitySummary = .mock
        let friendsManager = AnyFriendsManager()
        friendsManager.friends = [friend]
        friendsManager.friendRequests = [friend]
        friendsManager.searchResults = [.gabby, .evan]
        return friendsManager
    }()

    static var previews: some View {
        Resolver.Name.mode = .mock
        return AddFriendView()
            .environmentObject(User.evan)
            .environmentObject(friendsManager)
    }
}
