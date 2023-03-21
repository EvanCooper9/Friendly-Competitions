import Factory

extension Container {
    var notificationsManager: Factory<NotificationsManaging> {
        Factory(self) { NotificationsManager() }.scope(.shared)
    }
}
