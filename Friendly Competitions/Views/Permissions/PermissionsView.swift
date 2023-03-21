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
                Text(L10n.Permissions.header)
            } footer: {
                Text(L10n.Permissions.footer)
            }
            .textCase(.none)
        }
        .navigationTitle(L10n.Permissions.title)
        .embeddedInNavigationView()
        .registerScreenView(name: "Permissions")
    }
}

#if DEBUG
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
#endif
