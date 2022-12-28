import ECKit
import Factory
import SwiftUI

struct InviteFriendsView: View {
    
    @StateObject private var viewModel: InviteFriendsViewModel
    
    init(action: InviteFriendsAction) {
        _viewModel = .init(wrappedValue: .init(action: action))
    }
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.rows) { row in
                    HStack {
                        Text(row.name)
                        IDPill(id: row.pillId)
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
                            .font(.body)
                        Button("Send an invite link", action: viewModel.sendInviteLink)
                            .font(.body)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Invite a friend")
        .embeddedInNavigationView()
        .withLoadingOverlay(isLoading: viewModel.loading)
    }
}

struct InviteFriends_Previews: PreviewProvider {
    static var previews: some View {
        InviteFriendsView(action: .addFriend)
            .setupMocks()
    }
}
