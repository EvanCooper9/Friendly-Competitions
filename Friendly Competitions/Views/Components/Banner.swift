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

        let icon: SFSymbolName?
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

    var id: String {
        switch self {
        case .healthKitPermissionsMissing: return "healthKitPermissionsMissing"
        case .healthKitDataMissing: return "healthKitDataMissing"
        case .notificationPermissionsMissing: return "notificationPermissionsMissing"
        case .notificationPermissionsDenied: return "notificationPermissionsDenied"
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
        }
    }

    func view(_ tapped: @escaping () -> Void, file: String = #file) -> some View {
        let fileName = (file as NSString).lastPathComponent
        return HStack(spacing: 10) {
            if let icon = configuration.icon {
                Image(systemName: icon)
                    .foregroundColor(configuration.foreground)
                    .font(.title2)
            }

            Text(configuration.message)
                .font(.footnote)
                .lineLimit(2)
                .bold()
                .foregroundColor(configuration.foreground)
                .frame(maxWidth: .infinity, alignment: .leading)
                .minimumScaleFactor(0.5)

            if let action = configuration.action {
                Button(action.cta) {
                    let analyticsManager = Container.shared.analyticsManager.resolve()
                    analyticsManager.log(event: .bannerTapped(bannerID: id, file: fileName))
                    tapped()
                }
                .font(.footnote)
                .bold()
                .foregroundColor(action.foreground)
                .padding(.small)
                .background(action.background)
                .cornerRadius(5)
            }
        }
        .padding(12)
        .background(configuration.background)
        .cornerRadius(10)
        .shadow(color: .gray.opacity(0.25), radius: 10)
        .onAppear {
            let analyticsManager = Container.shared.analyticsManager.resolve()
            analyticsManager.log(event: .bannerViewed(bannerID: id, file: fileName))
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
        }
    }
}

extension Banner.Configuration {
    static func error(message: String, cta: String? = nil) -> Banner.Configuration {
        var action: Action?
        if let cta {
            action = .init(cta: cta, foreground: .red, background: .white)
        }
        return .init(icon: .exclamationmarkCircleFill,
                     message: message,
                     action: action,
                     foreground: .white,
                     background: .red)
    }

    static func warning(message: String, cta: String? = nil) -> Banner.Configuration {
        var action: Action?
        if let cta {
            action = .init(cta: cta, foreground: .orange, background: .white)
        }
        return .init(icon: .exclamationmarkTriangleFill,
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
        .notificationPermissionsDenied
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
