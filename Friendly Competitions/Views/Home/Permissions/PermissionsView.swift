import SwiftUI
import Resolver

struct PermissionsView: View {

    @StateObject private var viewModel = PermissionsViewModel()

    var body: some View {
        List {
            Section {
                ForEach(Permission.allCases) { permission in
                    PermissionView(permission: permission, status: viewModel.permissionStatus[permission]!) {
                        viewModel.request(permission)
                    }
                }
            } header: {
                Text("To get the best experience in Friendly Competitions, we need access to a few things.")
            } footer: {
                Text("You can change permissions in the settings app.")
            }
            .textCase(.none)
        }
        .navigationTitle("Permissions needed")
        .embeddedInNavigationView()
    }
}

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsView()
    }
}
