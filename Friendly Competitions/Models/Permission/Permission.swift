enum Permission: String, CaseIterable, Identifiable {
    case health
    case notifications

    var id: String { rawValue }

    var title: String {
        switch self {
        case .health:
            return "Health"
        case .notifications:
            return "Notifications"
        }
    }

    var description: String {
        switch self {
        case .health:
            return "So we can count score"
        case .notifications:
            return "So you can stay up to date"
        }
    }

    var imageName: String {
        switch self {
        case .health:
            return Asset.Images.health.name
        case .notifications:
            return Asset.Images.notifications.name
        }
    }
}
