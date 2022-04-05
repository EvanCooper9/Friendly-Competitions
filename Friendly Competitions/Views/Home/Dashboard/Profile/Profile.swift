import Resolver
import SwiftUI

struct Profile: View {

    @Environment(\.presentationMode) private var presentationMode
    @InjectedObject private var authenticationManager: AnyAuthenticationManager
    @InjectedObject private var userManager: AnyUserManager
    @State private var presentDeleteAccountAlert = false

    var body: some View {
        Form {
            UserInfoSection(user: userManager.user)

            Section("Statistics") {
                StatisticsView(statistics: userManager.user.statistics ?? .zero)
            }

            Section {
                Toggle("Searchable", isOn: $userManager.user.searchable ?? true)

            } header: {
                Text("Privacy")
            } footer: {
                Text("Turn this off to prevent your account from showing up in search. Other people will not be able to add you as a friend.")
            }

            Section {
                Toggle("Show real name", isOn: $userManager.user.showRealName ?? true)
            } footer: {
                Text("Turn this off to hide your name in competitions that you join. You will still earn medals, and friends will still see your real name.")
            }

            Section("Session") {
                Button("Sign out", systemImage: "person.crop.circle.badge.minus") {
                    Task {
                        try await authenticationManager.signOut()
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                Button(toggling: $presentDeleteAccountAlert) {
                    Label("Delete account", systemImage: "trash")
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
            Button("Yes", role: .destructive, action: userManager.deleteAccount)
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
