import Factory
import SwiftUI

struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
        
    var body: some View {
        Form {
            UserInfoSection(user: viewModel.user)
            Button(L10n.Profile.shareInviteLink, systemImage: .personCropCircleBadgePlus, action: viewModel.shareInviteLinkTapped)
            
            Section(L10n.Profile.Medals.title) {
                MedalsView(statistics: viewModel.user.statistics ?? .zero)
            }
            
            if let premium = viewModel.premium {
                Section(L10n.Profile.Premium.title) {
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
                Text(L10n.Profile.Privacy.HideName.description)
            }
            
            Section(L10n.Profile.Session.title) {
                Button(L10n.Profile.Session.signOut, systemImage: .personCropCircleBadgeMinus, action: viewModel.signOutTapped)
                Button(action: viewModel.deleteAccountTapped) {
                    Label(L10n.Profile.Session.deleteAccount, systemImage: .trash)
                        .foregroundColor(.red)
                }
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
