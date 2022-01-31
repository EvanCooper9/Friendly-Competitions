import Firebase
import FirebaseAuth
import FirebaseFirestore
import SwiftUI
import Resolver

struct Profile: View {
    
    @EnvironmentObject private var user: User
    @StateObject private var viewModel = ProfileViewModel()
    @State private var presentDeleteAccountAlert = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            List {
                UserInfoSection(user: user)
                
                let stats = user.statistics ?? .zero
                Section("Stats") {
                    StatisticsView(statistics: stats)
                }
                
                Section {
                    Button(action: { try? Auth.auth().signOut() }) {
                        Label("Sign out", systemImage: "person.crop.circle.badge.minus")
                    }
                }
                
                Section {
                    Button(toggling: $presentDeleteAccountAlert) {
                        Label("Delete account", systemImage: "trash")
                    }
                    .foregroundColor(.red)
                } footer: {
                    Text("You will also be signed out")
                }
            }
            .navigationTitle("Profile")
            .embeddedInNavigationView()
            
            VStack {
                Text("Made with ❤️ by")
                    .foregroundColor(.gray)
                Link("Evan Cooper", destination: URL(string: "https://evancooper.tech")!)
            }
            .font(.footnote)
        }
        .confirmationDialog(
            "Are you sure? This cannot be undone.",
            isPresented: $presentDeleteAccountAlert,
            titleVisibility: .visible
        ) {
            Button("Yes", role: .destructive, action: viewModel.deleteAccount)
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        Resolver.Name.mode = .mock
        return Profile()
            .environmentObject(User.evan)
    }
}
