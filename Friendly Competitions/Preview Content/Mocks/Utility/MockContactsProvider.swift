import Contacts

final class MockContactsManager: ContactsManaging {
    var contacts = [CNContact]()
    var permissionStatus: PermissionStatus = .notDetermined
    func requestPermissions(completion: @escaping (PermissionStatus) -> Void) {}
}
