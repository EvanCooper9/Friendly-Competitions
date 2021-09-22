import Contacts

protocol ContactsManaging {
    var contacts: [CNContact] { get }
    var shouldRequestPermissions: Bool { get }
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

    var shouldRequestPermissions: Bool { CNContactStore.authorizationStatus(for: .contacts) == .notDetermined }
}
