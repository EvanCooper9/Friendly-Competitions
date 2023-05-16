import Combine
import ECKit
import Foundation

protocol AppService {
    func didFinishLaunching()
    func didRegisterForRemoteNotifications(with deviceToken: Data)
    func didReceiveRemoteNotification(with data: [AnyHashable: Any]) -> AnyPublisher<Void, Never>
}

extension AppService {
    func didFinishLaunching() {}
    func didRegisterForRemoteNotifications(with deviceToken: Data) {}
    func didReceiveRemoteNotification(with data: [AnyHashable: Any]) -> AnyPublisher<Void, Never> { .just(()) }
}
