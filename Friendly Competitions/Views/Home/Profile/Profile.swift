import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Resolver

struct Profile: View {

    @EnvironmentObject private var user: User
    @EnvironmentObject private var userManager: AnyUserManager
    @State private var presentDeleteAccountAlert = false

    var body: some View {
        List {
            UserInfoSection(user: user)

            let stats = user.statistics ?? .zero
            Section("Stats") {
                StatisticsView(statistics: stats)
            }

            Section {
                Button(action: userManager.signOut) {
                    Label("Sign out", systemImage: "person.crop.circle.badge.minus")
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
            .environmentObject(User.evan)
            .environmentObject(AnyUserManager())
    }
}
