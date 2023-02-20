import Factory

extension Container {
    static let notificationsManager = Factory<NotificationsManaging>(scope: .shared, factory: NotificationsManager.init)
}
