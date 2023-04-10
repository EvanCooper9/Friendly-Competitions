import Foundation

protocol AppService {
    func didFinishLaunching()
    func didRegisterForRemoteNotifications(with deviceToken: Data)
}

extension AppService {
    func didFinishLaunching() {}
    func didRegisterForRemoteNotifications(with deviceToken: Data) {}
}
