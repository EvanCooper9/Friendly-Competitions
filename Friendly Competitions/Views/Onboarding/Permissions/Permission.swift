enum Permission: CaseIterable {
    case health
    case notifications
    case contacts

    var title: String {
        switch self {
        case .health:
            return "Health"
        case .notifications:
            return "Notifications"
        case .contacts:
            return "Contacts"
        }
    }

    var description: String {
        switch self {
        case .health:
            return "So we can count score"
        case .notifications:
            return "So you can stay up to date"
        case .contacts:
            return "So you can find friends"
        }
    }

    var imageName: String {
        switch self {
        case .health:
            return Asset.health.name
        case .notifications:
            return Asset.notifications.name
        case .contacts:
            return Asset.contacts.name
        }
    }
}
