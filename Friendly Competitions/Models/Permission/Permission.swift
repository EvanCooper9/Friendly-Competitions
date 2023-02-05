enum Permission: String, CaseIterable, Identifiable {
    case health
    case notifications

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health:
            return L10n.Permission.Health.title
        case .notifications:
            return L10n.Permission.Notifications.titile
        }
    }

    var description: String {
        switch self {
        case .health:
            return L10n.Permission.Health.description
        case .notifications:
            return L10n.Permission.Notifications.desciption
        }
    }

    var imageName: String {
        switch self {
        case .health:
            return Asset.Images.Permissions.health.name
        case .notifications:
            return Asset.Images.Permissions.notifications.name
        }
    }
}
