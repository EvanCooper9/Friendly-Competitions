import Resolver
import SwiftUI

struct Profile: View {
    
    @StateObject private var viewModel = Resolver.resolve(ProfileViewModel.self)
    
    @State private var presentDeleteAccountAlert = false
    
    var body: some View {
        Form {
            UserInfoSection(user: viewModel.user)
            Button("Share invite link", systemImage: .personCropCircleBadgePlus) { viewModel.sharedDeepLink.share() }
            
            Section("Statistics") {
                StatisticsView(statistics: viewModel.user.statistics ?? .zero)
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
                Button("Sign out", systemImage: .personCropCircleBadgeMinus) {
                    viewModel.signOut()
                }
                Button(toggling: $presentDeleteAccountAlert) {
                    Label("Delete account", systemImage: .trash)
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Profile")
        .confirmationDialog(
            "Are you sure? This cannot be undone.",
            isPresented: $presentDeleteAccountAlert,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive, action: viewModel.deleteAccount)
            Button("Cancel", role: .cancel) {}
        }
        .registerScreenView(name: "Profile")
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Profile()
            .setupMocks()
            .embeddedInNavigationView()
    }
}
