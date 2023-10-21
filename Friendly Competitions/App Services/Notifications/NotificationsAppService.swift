import Factory

final class NotificationsAppService: AppService {

    @Injected(\.notificationsManager) private var notificationsManager

    func willFinishLaunching() {
        notificationsManager.setUp()
    }
}
