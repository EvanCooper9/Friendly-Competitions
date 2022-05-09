import SwiftUI

struct InviteFriends: View {
    
    @StateObject private var viewModel: InviteFriendsViewModel
    
    init(action: InviteFriendsAction) {
        _viewModel = .init(wrappedValue: InviteFriendsViewModel(action: action))
    }
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.rows) { row in
                    HStack {
                        Text(row.name)
                        Spacer()
                        Button(row.buttonTitle, action: row.buttonAction)
                            .disabled(row.buttonDisabled)
                            .buttonStyle(.bordered)
                    }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 10) {
                    if let footerText = viewModel.footerText {
                        Text(footerText)
                    }
                    HStack {
                        Text("Having trouble?")
                        Button("Send an invite link", action: viewModel.sendInviteLink)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Invite a friend")
        .onChange(of: viewModel.sharedDeepLink) { deepLink in
            guard let deepLink = deepLink else { return }
            viewModel.sharedDeepLink = nil
            let activityVC = UIActivityViewController(
                activityItems: deepLink.itemsForSharing,
                applicationActivities: nil
            )
            activityVC.excludedActivityTypes = [.mail, .addToReadingList, .assignToContact, .markupAsPDF, .openInIBooks, .saveToCameraRoll, .print]

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
        .embeddedInNavigationView()
    }
}

struct InviteFriends_Previews: PreviewProvider {
    static var previews: some View {
        InviteFriends(action: .addFriend)
            .setupMocks()
    }
}
