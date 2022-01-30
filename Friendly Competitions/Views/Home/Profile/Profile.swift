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
                Section("Profile") {
                    ImmutableListItemView(value: user.name, valueType: .name)
                    ImmutableListItemView(value: user.email, valueType: .email)
                }

                Section {
                    Button(action: { try? Auth.auth().signOut() }) {
                        Label("Sign out", systemImage: "person.crop.circle.badge.minus")
                    }
                }

                Section {
                    Button(action: { presentDeleteAccountAlert.toggle() }) {
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
