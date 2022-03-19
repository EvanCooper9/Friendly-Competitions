import SwiftUI

struct PermissionsView: View {

    @EnvironmentObject private var permissionsManager: AnyPermissionsManager

    var body: some View {
        List {
            Section {
                ForEach(Array(permissionsManager.permissionStatus.keys)) { permission in
                    PermissionView(permission: permission, status: permissionsManager.permissionStatus[permission]!) {
                        permissionsManager.request(permission)
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
    }
}

struct PermissionsView_Previews: PreviewProvider {

    private static func setupMocks() {
        permissionsManager.permissionStatus = [
            .health: .done,
            .notifications: .authorized
        ]
    }
    
    static var previews: some View {
        PermissionsView()
            .withEnvironmentObjects(setupMocks: setupMocks)
    }
}
