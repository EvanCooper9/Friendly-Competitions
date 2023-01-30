import Factory
import SwiftUI

struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
        
    var body: some View {
        Form {
            Section {
                HStack {
                    Label("Name", systemImage: .personFill)
                    Spacer()
                    if viewModel.editing {
                        TextField(text: $viewModel.nameForEdititng)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text(viewModel.user.name)
                            .foregroundColor(.secondaryLabel)
                        IDPill(id: viewModel.user.hashId)
                    }
                }
                HStack {
                    Label("Email", systemImage: .envelopeFill)
                    Spacer()
                    if viewModel.editing {
                        TextField(text: $viewModel.emailForEditing)
                            .multilineTextAlignment(.trailing)
                    } else {
                        Text(viewModel.user.email)
                            .foregroundColor(.secondaryLabel)
                    }
                }
            } header: {
                HStack(spacing: 20) {
                    Text("Profile")
                    Spacer()
                    if viewModel.editing {
                        Button("Cancel", role: .destructive, action: viewModel.cancelTapped)
                        Button("Save", action: viewModel.saveTapped)
                    } else {
                        Button("Edit", action: viewModel.editTapped)
                    }
                }
                .font(.caption)
            }
            
            Button("Share invite link", systemImage: .personCropCircleBadgePlus, action: viewModel.shareInviteLinkTapped)
            
            Section("Medals") {
                MedalsView(statistics: viewModel.user.statistics ?? .zero)
            }
            
            if let premium = viewModel.premium {
                Section("Friendly Competitions Preimum") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text(premium.title)
                            Spacer()
                            Text(premium.price)
                                .foregroundColor(.secondaryLabel)
                        }
                        if let expiry = premium.expiry {
                            Text("\(premium.renews ? "Renews" : "Expires") on \(expiry.formatted(date: .long, time: .complete))")
                                .foregroundColor(.secondaryLabel)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical, .extraSmall)
                    Button("Manage", action: viewModel.manageSubscriptionTapped)
                }
            } else {
                Section(content: PremiumBanner.init)
                    .listRowInsets(.zero)
            }
            
            Section {
                Toggle("Searchable", isOn: $viewModel.user.searchable ?? true)
            } header: {
                Text("Privacy")
            } footer: {
                Text("Turn this off to prevent your account from showing up in search. Other people will not be able to add you as a friend.")
            }
            
            Section {
                Toggle("Show real name", isOn: $viewModel.user.showRealName ?? true)
            } footer: {
                Text("Turn this off to hide your name in competitions that you join. You will still earn medals, and friends will still see your real name.")
            }
            
            Section("Session") {
                Button("Sign out", systemImage: .personCropCircleBadgeMinus, action: viewModel.signOutTapped)
                Button(action: viewModel.deleteAccountTapped) {
                    Label("Delete account", systemImage: .trash)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Profile")
        .confirmationDialog(
            "Are you sure? This cannot be undone.",
            isPresented: $viewModel.confirmationRequired,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive, action: viewModel.confirmTapped)
            Button("Cancel", role: .cancel) {}
        }
        .withLoadingOverlay(isLoading: viewModel.loading)
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
