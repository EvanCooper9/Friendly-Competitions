import Combine
import Factory
import SwiftUI
import SwiftUIX

enum Banner: Equatable, Identifiable {

    struct Configuration {

        struct Action {
            let cta: String
            let foreground: Color
            let background: Color
        }

        let icon: String?
        let message: String
        let action: Action?
        let foreground: Color
        let background: Color
    }

    // HealthKit Permissions & Data
    case healthKitPermissionsMissing(permissions: [HealthKitPermissionType])
    case healthKitDataMissing(dataType: [HealthKitPermissionType])

    // Notification Permissions
    case notificationPermissionsMissing
    case notificationPermissionsDenied

    // New competition results
    case newCompetitionResults(competition: Competition)

    var id: String {
        switch self {
        case .healthKitPermissionsMissing: return "healthKitPermissionsMissing"
        case .healthKitDataMissing: return "healthKitDataMissing"
        case .notificationPermissionsMissing: return "notificationPermissionsMissing"
        case .notificationPermissionsDenied: return "notificationPermissionsDenied"
        case .newCompetitionResults(let competition):
            return "newCompetitionResults-\(competition.id)"
        }
    }

    var configuration: Configuration {
        switch self {
        case .healthKitPermissionsMissing:
            return .error(message: L10n.Banner.HealthKitPermissionsMissing.message,
                          cta: L10n.Banner.HealthKitPermissionsMissing.cta)
        case .healthKitDataMissing:
            return .warning(message: L10n.Banner.HealthKitDataMissing.message,
                            cta: UIApplication.shared.canOpenURL(.health) ? L10n.Banner.HealthKitDataMissing.cta : nil)
        case .notificationPermissionsMissing:
            return .warning(message: L10n.Banner.NotificationPermissionsMissing.message,
                            cta: L10n.Banner.NotificationPermissionsMissing.cta)
        case .notificationPermissionsDenied:
            return .error(message: L10n.Banner.NotificationPermissionsDenied.message,
                          cta: L10n.Banner.NotificationPermissionsDenied.cta)
        case .newCompetitionResults(let competition):
            return .success(icon: "trophy.fill",
                            message: "New results posted for \(competition.name)",
                            cta: "View")
        }
    }

    func tapped() -> AnyPublisher<Void, Never> {
        let healthKitManager = Container.shared.healthKitManager.resolve()
        let notificationsManager = Container.shared.notificationsManager.resolve()
        let scheduler = Container.shared.scheduler.resolve()

        switch self {
        case .healthKitPermissionsMissing(let permissions):
            return healthKitManager.request(permissions)
                .catchErrorJustReturn(())
                .receive(on: scheduler)
                .eraseToAnyPublisher()
        case .healthKitDataMissing:
            UIApplication.shared.open(.health)
            return .just(())
        case .notificationPermissionsMissing:
            return notificationsManager.requestPermissions()
                .mapToVoid()
                .catchErrorJustReturn(())
                .receive(on: scheduler)
                .eraseToAnyPublisher()
        case .notificationPermissionsDenied:
            UIApplication.shared.open(.notificationSettings)
            return .just(())
        case .newCompetitionResults(let competition):
            let appState = Container.shared.appState.resolve()
            appState.push(deepLink: .competitionResults(id: competition.id))
            return .just(())
        }
    }
}

extension Banner.Configuration {
    static func error(message: String, cta: String? = nil) -> Banner.Configuration {
        var action: Action?
        if let cta {
            action = .init(cta: cta, foreground: .red, background: .white)
        }
        return .init(icon: "exclamationmark.circle.fill",
                     message: message,
                     action: action,
                     foreground: .white,
                     background: .red)
    }

    static func success(icon: String = "checkmark.fircle.fill", message: String, cta: String? = nil) -> Banner.Configuration {
        var action: Action?
        if let cta {
            action = .init(cta: cta, foreground: .green, background: .white)
        }
        return .init(icon: icon,
                     message: message,
                     action: action,
                     foreground: .white,
                     background: .green)
    }

    static func warning(message: String, cta: String? = nil) -> Banner.Configuration {
        var action: Action?
        if let cta {
            action = .init(cta: cta, foreground: .orange, background: .white)
        }
        return .init(icon: "exclamationmark.triangle.fill",
                     message: message,
                     action: action,
                     foreground: .white,
                     background: .orange)
    }
}

#if DEBUG
struct Banner_Previews: PreviewProvider {

    private static let banners: [Banner] = [
        .healthKitDataMissing(dataType: []),
        .healthKitPermissionsMissing(permissions: []),
        .notificationPermissionsMissing,
        .notificationPermissionsDenied,
        .newCompetitionResults(competition: .mock)
    ]

    static var previews: some View {
        VStack {
            ForEach(banners) { banner in
                banner.view {
                    // do nothing
                }
            }
        }
        .padding()
    }
}
#endif
