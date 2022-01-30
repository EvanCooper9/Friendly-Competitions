import SwiftUI
import Resolver

struct AddFriendView: View {

    var sharedFriendId: String?

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var user: User
    @StateObject private var viewModel = AddFriendViewModel()
    @State private var loading = false
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.searchResults) { user in
                    HStack {
                        Text(user.name)
                        Spacer()
                        if user.incomingFriendRequests.contains(self.user.id) {
                            Image(systemName: "clock")
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { viewModel.tapped(contact: user) }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("You can search for friends who have an account with us, and have a matching email account in your contacts.")
                            .padding(.bottom, 15)
                        Text("Having trouble?")
                        Text("• Verify contacts permissions are enabled.")
                        Text("• Verify your email from the Profile screen.")
                        Button("• Or send an invite link to your friend!") {
                            loading = true
                            Task {
                                let activityVC = UIActivityViewController(
                                    activityItems: [
                                        "Add me in Friendly Competitions!",
                                        "friendly-competitions://invite/\(user.id)"
                                    ],
                                    applicationActivities: nil
                                )
                                activityVC.excludedActivityTypes = [.mail]
                                activityVC.completionWithItemsHandler = { activityType, completed, returnedItems, error in
                                    DispatchQueue.main.async {
                                        loading = false
                                    }
                                }

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
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText)
        .navigationTitle("Search for Friends")
        .embeddedInNavigationView()
        .withLoadingOverlay(loading: $loading)
        .onAppear {
            viewModel.setup(sharedFriendId: sharedFriendId)
        }
    }
}

struct AddFriendView_Previews: PreviewProvider {
    static var previews: some View {
        Resolver.Name.mode = .mock
        return AddFriendView(sharedFriendId: User.gabby.id)
            .environmentObject(User.evan)
    }
}
