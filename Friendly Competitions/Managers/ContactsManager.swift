import Contacts

protocol ContactsManaging {
    var contacts: [CNContact] { get }
    var permissionStatus: PermissionStatus { get }
    func requestPermissions(completion: @escaping (PermissionStatus) -> Void)
}

final class ContactsManager: ContactsManaging {
    var contacts: [CNContact] {
        let store = CNContactStore()
        let contacts = try? store.unifiedContacts(
            matching: CNContact.predicateForContactsInContainer(withIdentifier: store.defaultContainerIdentifier()),
            keysToFetch: [CNContactEmailAddressesKey as CNKeyDescriptor]
        )

        return contacts ?? []
    }

    var permissionStatus: PermissionStatus { CNContactStore.authorizationStatus(for: .contacts).permissionStatus }

    private let contactStore = CNContactStore()

    func requestPermissions(completion: @escaping (PermissionStatus) -> Void) {
        contactStore.requestAccess(for: .contacts) { [weak self] authorized, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                completion(self.permissionStatus)
            }
        }
    }
}

extension CNAuthorizationStatus {
    var permissionStatus: PermissionStatus {
        switch self {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized, .restricted:
            return .authorized
        @unknown default:
            return .notDetermined
        }
    }
}
