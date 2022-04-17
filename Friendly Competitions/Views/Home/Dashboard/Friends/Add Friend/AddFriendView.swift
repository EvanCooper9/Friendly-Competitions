import SwiftUI

struct AddFriendView: View {

    @StateObject private var viewModel = AddFriendViewModel()
    
    var body: some View {
        List {

            if let friendReferral = viewModel.friendReferral {
                Section("Shared with you") {
                    AddFriendListItem(
                        friend: friendReferral,
                        action: .friendRequest,
                        disabledIf: friendReferral
                            .incomingFriendRequests
                            .appending(contentsOf: friendReferral.friends)
                            .contains(viewModel.user.id)
                    ) { viewModel.add(friendReferral) }
                }
            }

            Section {
                ForEach(viewModel.searchResults) { friend in
                    AddFriendListItem(
                        friend: friend,
                        action: .friendRequest,
                        disabledIf: friend
                            .incomingFriendRequests
                            .appending(contentsOf: friend.friends)
                            .contains(viewModel.user.id)
                    ) { viewModel.add(friend) }
                }
            } header: {
                if !viewModel.searchResults.isEmpty {
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
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Search for Friends")
        .embeddedInNavigationView()
        .registerScreenView(name: "Add Friend")
    }

    private func share() {
        Task {
            let activityVC = UIActivityViewController(
                activityItems: viewModel.referralItems,
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

    private static func setupMocks() {
        let friend = User.gabby
        friendsManager.friends = [friend]
        friendsManager.friendActivitySummaries = [friend.id: .mock]
        friendsManager.friendRequests = [friend]
    }

    static var previews: some View {
        AddFriendView()
            .setupMocks(setupMocks)
    }
}
