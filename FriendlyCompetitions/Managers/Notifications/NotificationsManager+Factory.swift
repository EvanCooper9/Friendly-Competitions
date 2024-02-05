import Factory

extension Container {
    var notificationsManager: Factory<NotificationsManaging> {
        self { NotificationsManager() }.scope(.shared)
    }
}
