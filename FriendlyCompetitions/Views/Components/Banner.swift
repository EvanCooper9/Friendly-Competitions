import Combine
import Factory
import SwiftUI
import SwiftUIX

enum Banner: Comparable, Equatable, Identifiable {

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
    case healthKitDataMissing(competition: Competition, dataType: [HealthKitPermissionType])

    // Notification Permissions
    case notificationPermissionsMissing
    case notificationPermissionsDenied

    // New competition results
    case newCompetitionResults(competition: Competition, resultID: CompetitionResult.ID)
    case competitionResultsCalculating(competition: Competition)

    // Background refresh
    case backgroundRefreshDenied

    var id: String {
        switch self {
        case .healthKitPermissionsMissing(let permissions):
            let permissionIDs = permissions.map(\.rawValue).joined(separator: "-")
            return "healthKitPermissionsMissing-\(permissionIDs)"
        case .healthKitDataMissing(let competition, _):
            return "healthKitDataMissing-\(competition.id)"
        case .notificationPermissionsMissing: return "notificationPermissionsMissing"
        case .notificationPermissionsDenied: return "notificationPermissionsDenied"
        case .competitionResultsCalculating(let competition):
            return "competitionResultsCalculating-\(competition.id)"
        case .newCompetitionResults(let competition, let resultID):
            return ["newCompetitionResults", competition.id, resultID].joined(separator: "_")
        case .backgroundRefreshDenied: return "backgroundRefreshDenied"
        }
    }

    var configuration: Configuration {
        switch self {
        case .healthKitPermissionsMissing:
            return .error(message: L10n.Banner.HealthKitPermissionsMissing.message,
                          cta: L10n.Banner.HealthKitPermissionsMissing.cta)
        case .healthKitDataMissing(let competition, _):
            return .warning(message: L10n.Banner.HealthKitDataMissing.message(competition.name),
                            cta: UIApplication.shared.canOpenURL(.health) ? L10n.Banner.HealthKitDataMissing.cta : nil)
        case .notificationPermissionsMissing:
            return .warning(message: L10n.Banner.NotificationPermissionsMissing.message,
                            cta: L10n.Banner.NotificationPermissionsMissing.cta)
        case .notificationPermissionsDenied:
            return .error(message: L10n.Banner.NotificationPermissionsDenied.message,
                          cta: L10n.Banner.NotificationPermissionsDenied.cta)
        case .newCompetitionResults(let competition, _):
            return .success(message: "New results posted for \(competition.name)",
                            cta: "View")
        case .competitionResultsCalculating:
            if let targetDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: .now),
               targetDate.timeIntervalSinceNow > 0 {
                let formatter = RelativeDateTimeFormatter()
                let date = formatter.localizedString(for: targetDate, relativeTo: .now)
                return .info(message: "Results are being calculated. Check back \(date).")
            } else {
                return .info(message: "Results are being calculated. Check back soon.")
            }
        case .backgroundRefreshDenied:
            return .warning(message: "Background refresh is disabled. Your data might not upload",
                            cta: "Enable")
        }
    }

    var showsOnHomeScreen: Bool {
        switch self {
        case .healthKitPermissionsMissing,
             .notificationPermissionsMissing,
             .notificationPermissionsDenied,
             .backgroundRefreshDenied:
            return true
        case .competitionResultsCalculating,
             .newCompetitionResults,
             .healthKitDataMissing:
            return false
        }
    }

    func view(shadow: Bool = true, _ tapped: @escaping () -> Void, file: String = #file) -> some View {
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
        .if(shadow) { view in
            view.shadow(color: .gray.opacity(0.25), radius: 10)
        }
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
        case .healthKitDataMissing(_, let dataTypes):
            let url = dataTypes.first?.url ?? .health
            UIApplication.shared.open(url)
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
        case .newCompetitionResults(let competition, let resultID):
            let appState = Container.shared.appState.resolve()
            appState.push(deepLink: .competitionResult(id: competition.id, resultID: resultID))
            return .just(())
        case .competitionResultsCalculating:
            return .just(())
        case .backgroundRefreshDenied:
            UIApplication.shared.open(.settings)
            return .just(())
        }
    }

    static func < (lhs: Banner, rhs: Banner) -> Bool {
        lhs.rank < rhs.rank
    }

    private var rank: Int {
        switch self {
        case .healthKitPermissionsMissing:
            return 1
        case .backgroundRefreshDenied:
            return 2
        case .newCompetitionResults:
            return 3
        case .healthKitDataMissing:
            return 4
        case .notificationPermissionsDenied:
            return 5
        case .notificationPermissionsMissing:
            return 6
        case .competitionResultsCalculating:
            return 7
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

    static func success(message: String, cta: String? = nil) -> Banner.Configuration {
        var action: Action?
        if let cta {
            action = .init(cta: cta, foreground: .green, background: .white)
        }
        return .init(icon: .checkmarkCircleFill,
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
        return .init(icon: .exclamationmarkTriangleFill,
                     message: message,
                     action: action,
                     foreground: .white,
                     background: .orange)
    }

    static func info(message: String) -> Banner.Configuration {
        .init(icon: .infoCircleFill,
              message: message,
              action: nil,
              foreground: .white,
              background: .lightGray)
    }
}

#if DEBUG
struct Banner_Previews: PreviewProvider {

    private static let banners: [Banner] = [
        .healthKitDataMissing(competition: .mock, dataType: []),
        .healthKitPermissionsMissing(permissions: []),
        .notificationPermissionsMissing,
        .notificationPermissionsDenied,
        .newCompetitionResults(competition: .mock, resultID: "123"),
        .competitionResultsCalculating(competition: .mock)
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
