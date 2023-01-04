import Factory
import SwiftUI

struct ProfileView: View {
    
    @StateObject private var viewModel = ProfileViewModel()
        
    var body: some View {
        Form {
            UserInfoSection(user: viewModel.user)
            Button("Share invite link", systemImage: .personCropCircleBadgePlus, action: viewModel.shareInviteLinkTapped)
            
            Section("Medals") {
                MedalsView(statistics: viewModel.user.statistics ?? .zero)
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
