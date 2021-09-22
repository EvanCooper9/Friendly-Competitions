import Contacts

final class MockContactsManager: ContactsManaging {
    var contacts = [CNContact]()
    var shouldRequestPermissions = false
}
