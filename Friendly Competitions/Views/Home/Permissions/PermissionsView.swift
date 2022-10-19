import SwiftUI

struct PermissionsView: View {

    @StateObject private var viewModel = PermissionsViewModel()

    var body: some View {
        List {
            Section {
                ForEach(viewModel.permissionStatuses, id: \.0) { permission, permissionStatus in
                    PermissionView(permission: permission, status: permissionStatus) {
                        viewModel.request(permission)
                    }
                }
            } header: {
                Text("To get the best experience in Friendly Competitions, we need access to a few things.")
            } footer: {
                Text("You can change your responses in the settings app.")
            }
            .textCase(.none)
        }
        .navigationTitle("Permissions needed")
        .embeddedInNavigationView()
        .registerScreenView(name: "Permissions")
    }
}

struct PermissionsView_Previews: PreviewProvider {

    private static func setupMocks() {
        permissionsManager.permissionStatus = .just([
            .health: .done,
            .notifications: .authorized
        ])
    }
    
    static var previews: some View {
        PermissionsView()
            .setupMocks(setupMocks)
    }
}
