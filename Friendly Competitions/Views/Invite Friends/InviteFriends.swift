import Resolver
import SwiftUI

struct InviteFriends: View {
    
    @StateObject private var viewModel: InviteFriendsViewModel
    
    init(action: InviteFriendsAction) {
        let vm = Resolver.resolve(InviteFriendsViewModel.self, args: action)
        _viewModel = .init(wrappedValue: vm)
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
                        Button("Send an invite link", action: viewModel.sendInviteLink)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle("Invite a friend")
        .embeddedInNavigationView()
    }
}

struct InviteFriends_Previews: PreviewProvider {
    static var previews: some View {
        InviteFriends(action: .addFriend)
            .setupMocks()
    }
}
