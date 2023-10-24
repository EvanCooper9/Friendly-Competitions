import ECKit
import Factory
import SwiftUI

struct InviteFriendsView: View {

    @StateObject private var viewModel: InviteFriendsViewModel

    init(action: InviteFriendsAction) {
        _viewModel = .init(wrappedValue: .init(action: action))
    }

    var body: some View {
        ScrollView {
            if viewModel.rows.isNotEmpty {
                CustomListSection {
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
                }

                shareInviteLink
            } else {
                VStack(spacing: 10) {
                    if viewModel.showEmpty {
                        Text(L10n.InviteFriends.noResults)
                            .bold()
                            .padding(.top)
                        Text(L10n.InviteFriends.noResultsMessage(viewModel.searchText))
                            .foregroundStyle(.secondary)
                        Divider()
                            .padding(.vertical)
                    }

                    shareInviteLink
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            }
        }
        .withLoadingOverlay(isLoading: viewModel.loading)
        .maxWidth(.infinity)
        .background(Color.listBackground.ignoresSafeArea())
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always))
        .navigationTitle(L10n.InviteFriends.title)
        .embeddedInNavigationView()
    }

    private var shareInviteLink: some View {
        VStack(spacing: 10) {
            Text(L10n.InviteFriends.ShareInviteLink.message)
                .foregroundStyle(.secondary)
            Button(L10n.InviteFriends.ShareInviteLink.buttonTitle, action: viewModel.sendInviteLink)
                .buttonStyle(.bordered)
        }
        .multilineTextAlignment(.center)
    }
}

#if DEBUG
struct InviteFriends_Previews: PreviewProvider {

    private static func setupMocks() {
        searchManager.searchForUsersByNameReturnValue = .just([])
    }

    static var previews: some View {
        InviteFriendsView(action: .addFriend)
            .setupMocks(setupMocks)
    }
}
#endif
