import SwiftUI
import Resolver

struct PermissionsView: View {

    @ObservedObject private var viewModel = PermissionsViewModel()

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(Permission.allCases, id: \.self) { permission in
                        PermissionView(permission: permission, canRequestPermission: viewModel.shouldRequestPermission[permission] ?? true) {
                            viewModel.request(permission)
                        }
                    }
                } header: {
                    Text("To get the best experience in Friendly Competitions, we need access to a few things.")
                        .font(.subheadline)
                        .padding(.bottom)
                }
                .textCase(.none)
                .navigationTitle("Permissions needed")
            }
        }
    }
}

final class PermissionsViewModel: ObservableObject {

    @Published var shouldRequestPermission = [Permission: Bool]()

    @LazyInjected private var contactsManager: ContactsManaging
    @LazyInjected private var healthKitManager: HealthKitManaging
    @LazyInjected private var notificationManager: NotificationManaging

    init() {
        shouldRequestPermission = [
            .health: healthKitManager.shouldRequestPermissions,
            .notifications: false,
            .contacts: contactsManager.shouldRequestPermissions
        ]

        notificationManager.shouldRequestPermissions { [weak self] shouldRequestPermission in
            DispatchQueue.main.async {
                self?.shouldRequestPermission[.notifications] = shouldRequestPermission
            }
        }
    }

    func request(_ permission: Permission) {
        switch permission {
        case .health:
            healthKitManager.requestPermissions { [weak self] _, _ in
                self?.updateRequestedPermission(permission)
            }
        case .notifications:
            notificationManager.requestPermissions { [weak self] _, _ in
                self?.updateRequestedPermission(permission)
            }
        case .contacts:
            contactsManager.requestPermissions { [weak self] _ in
                self?.updateRequestedPermission(permission)
            }
        }
    }

    private func updateRequestedPermission(_ permission: Permission) {
        DispatchQueue.main.async { [weak self] in
            self?.shouldRequestPermission[permission] = false
        }
    }
}

struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsView()
    }
}
