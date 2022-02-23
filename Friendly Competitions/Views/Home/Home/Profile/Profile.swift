import SwiftUI

struct Profile: View {

    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var authenticationManager: AnyAuthenticationManager
    @EnvironmentObject private var userManager: AnyUserManager
    @State private var presentDeleteAccountAlert = false

    var body: some View {
        List {
            UserInfoSection(user: userManager.user)

            let stats = userManager.user.statistics ?? .zero
            Section("Stats") {
                StatisticsView(statistics: stats)
            }

            Section {
                Button("Sign out", systemImage: "person.crop.circle.badge.minus") {
                    userManager.signOut()
                    presentationMode.wrappedValue.dismiss()
                }
                Button(toggling: $presentDeleteAccountAlert) {
                    Label("Delete account", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Profile")
        .embeddedInNavigationView()
        .confirmationDialog(
            "Are you sure? This cannot be undone.",
            isPresented: $presentDeleteAccountAlert,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive, action: userManager.deleteAccount)
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Profile()
            .environmentObject(AnyUserManager(user: .evan))
    }
}
