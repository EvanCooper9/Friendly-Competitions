import Factory

final class NotificationsAppService: AppService {

    @Injected(\.notificationsManager) private var notificationsManager: NotificationsManaging

    func didFinishLaunching() {
        notificationsManager.setUp()
    }
}
