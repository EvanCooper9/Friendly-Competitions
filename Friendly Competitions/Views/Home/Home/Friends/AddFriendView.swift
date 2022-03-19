import SwiftUI

struct AddFriendView: View {

    @State private var friendReferral: User?

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var friendsManager: AnyFriendsManager
    @EnvironmentObject private var userManager: AnyUserManager

    var body: some View {
        List {

            if let friendReferral = friendReferral, friendReferral.id != userManager.user.id {
                Section("Shared with you") {
                    AddFriendListItem(
                        friend: friendReferral,
                        action: .friendRequest,
                        disabledIf: friendReferral
                            .incomingFriendRequests
                            .appending(contentsOf: friendReferral.friends)
                            .contains(userManager.user.id)
                    ) { friendsManager.add(friend: friendReferral) }
                }
            }

            Section {
                ForEach(friendsManager.searchResults) { friend in
                    AddFriendListItem(
                        friend: friend,
                        action: .friendRequest,
                        disabledIf: friend
                            .incomingFriendRequests
                            .appending(contentsOf: friend.friends)
                            .contains(userManager.user.id)
                    ) { friendsManager.add(friend: friend) }
                }
            } header: {
                if !friendsManager.searchResults.isEmpty {
                    Text("Search results")
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
        .onAppear(perform: handleDeepLink)
        .embeddedInNavigationView()
    }

    private func share() {
        Task {
            let activityItems: [Any] = [
                "Add me in Friendly Competitions!",
                URL(string: "https://friendly-competitions.evancooper.tech/invite/\(userManager.user.id)")!
            ]
            let activityVC = UIActivityViewController(
                activityItems: activityItems,
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

    private func handleDeepLink() {
        guard case let .friendReferral(referralId) = appState.deepLink else { return }
        Task {
            let friendReferral = try await friendsManager.user(withId: referralId)
            DispatchQueue.main.async {
                self.friendReferral = friendReferral
                self.appState.deepLink = nil
            }
        }
    }
}

struct AddFriendView_Previews: PreviewProvider {

    private static func setupMocks() {
        let friend = User.gabby
        friendsManager.friends = [friend]
        friendsManager.friendActivitySummaries = [friend.id: .mock]
        friendsManager.friendRequests = [friend]
        friendsManager.searchResults = [.gabby, .evan]
    }

    static var previews: some View {
        AddFriendView()
            .withEnvironmentObjects(setupMocks: setupMocks)
    }
}
