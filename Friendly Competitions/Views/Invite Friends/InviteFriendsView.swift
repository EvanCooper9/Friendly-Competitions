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
                HStack {
                    Text(L10n.InviteFriends.havingTrouble)
                    Button(L10n.InviteFriends.sendAnInviteLink, action: viewModel.sendInviteLink)
                }
                .font(.body)
            }
        }
        .listStyle(.insetGrouped)
        .withLoadingOverlay(isLoading: viewModel.loading)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle(L10n.InviteFriends.title)
        .embeddedInNavigationView()
    }
}

#if DEBUG
struct InviteFriends_Previews: PreviewProvider {
    static var previews: some View {
        InviteFriendsView(action: .addFriend)
            .setupMocks()
    }
}
#endif
