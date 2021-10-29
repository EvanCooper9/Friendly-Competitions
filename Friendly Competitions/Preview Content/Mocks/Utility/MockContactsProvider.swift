import Contacts

final class MockContactsManager: ContactsManaging {
    var contacts = [CNContact]()
    var shouldRequestPermissions = false
    func requestPermissions(completion: @escaping (Bool) -> Void) {}
}
