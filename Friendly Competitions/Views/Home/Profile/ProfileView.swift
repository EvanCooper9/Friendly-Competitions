import Factory
import SwiftUI
import SwiftUIX

struct ProfileView: View {

    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        Form {
            UserInfoSection(user: viewModel.user)
            Button(L10n.Profile.shareInviteLink, systemImage: .personCropCircleBadgePlus, action: viewModel.shareInviteLinkTapped)

            Section {
                MedalsView(statistics: viewModel.user.statistics ?? .zero)
            } header: {
                Text(L10n.Profile.Medals.title)
            }

            if let premium = viewModel.premium {
                Section {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(premium.title)
                            Spacer()
                            Text(premium.price)
                                .foregroundColor(.secondaryLabel)
                        }
                        if let expiry = premium.expiry {
                            let expiry = expiry.formatted(date: .long, time: .omitted)
                            let title = premium.renews ?
                                L10n.Profile.Premium.renewsOn(expiry) :
                                L10n.Profile.Premium.expiresOn(expiry)
                            Text(title)
                                .foregroundColor(.secondaryLabel)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, .extraSmall)
                    Button(L10n.Profile.Premium.manage, action: viewModel.manageSubscriptionTapped)
                } header: {
                    Text(L10n.Profile.Premium.title)
                }
            } else {
                Section(content: PremiumBanner.init)
                    .listRowInsets(.zero)
            }

            Section {
                Toggle(L10n.Profile.Privacy.Searchable.title, isOn: $viewModel.user.searchable ?? true)
            } header: {
                Text(L10n.Profile.Privacy.title)
            } footer: {
                Text(L10n.Profile.Privacy.Searchable.description)
            }

            Section {
                Toggle(L10n.Profile.Privacy.HideName.title, isOn: $viewModel.user.showRealName ?? true)
            } footer: {
                Group {
                    Text(L10n.Profile.Privacy.HideName.description) +
                    Text(" Learn more")
                        .foregroundColor(.accentColor)
                }
                .onTapGesture(perform: viewModel.hideNameLearnMoreTapped)
            }
            .sheet(isPresented: $viewModel.showHideNameLearnMore) {
                HideNameLearnMoreView(showName: $viewModel.user.showRealName ?? true)
            }

            Section {
                Button(L10n.Profile.Session.signOut, systemImage: .personCropCircleBadgeMinus, action: viewModel.signOutTapped)
                Button(action: viewModel.deleteAccountTapped) {
                    Label(L10n.Profile.Session.deleteAccount, systemImage: .trash)
                        .foregroundColor(.red)
                }
            } header: {
                Text(L10n.Profile.Session.title)
            }
        }
        .navigationTitle(L10n.Profile.title)
        .confirmationDialog(
            L10n.Confirmation.areYouSureCannotBeUndone,
            isPresented: $viewModel.confirmationRequired,
            titleVisibility: .visible
        ) {
            Button(L10n.Generics.yes, role: .destructive, action: viewModel.confirmTapped)
            Button(L10n.Generics.cancel, role: .cancel) {}
        }
        .registerScreenView(name: "Profile")
    }
}

#if DEBUG
struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .setupMocks()
            .embeddedInNavigationView()
    }
}
#endif
