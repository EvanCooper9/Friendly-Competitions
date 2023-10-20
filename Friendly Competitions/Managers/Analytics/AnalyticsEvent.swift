import Foundation

enum AnalyticsEvent: Codable {

    // competitions
    case acceptCompetition(id: String)
    case createCompetition(name: String)
    case declineCompetition(id: String)
    case deleteCompetition(id: String)
    case inviteFriendToCompetition(id: String, friendId: String)
    case joinCompetition(id: String)
    case leaveCompetition(id: String)

    // permissions
    case notificationPermissions(authorized: Bool)
    case healthKitPermissions(authorized: Bool)

    // premium
    case premiumPaywallPrimerViewed
    case premiumPaywallViewed
    case premiumSelected(id: String)
    case premiumPurchaseStarted(id: String)
    case premiumPurchaseCancelled(id: String)
    case premiumPurchased(id: String)
    case premiumBannerDismissed

    // database
    case databaseRead(path: String)
    case databaseWrite(path: String)
    case databaseDelete(path: String)

    // background jobs
    case backgroundNotificationReceived
    case backgroundNotificationFailedToParseJob
    case backgroundNotificationHandled
    case backgroundJobReceived(job: [String: String])
    case backgroundJobStarted(jobType: String)
    case backgroundJobEnded(jobType: String)

    // banners
    case bannerViewed(bannerID: String, file: String)
    case bannerTapped(bannerID: String, file: String)

    // HealthKit
    case healthKitShouldRequestPermissions(permissionsString: String, shouldRequest: Bool)
    case healthKitRegisterBGDeliverySuccess(permission: HealthKitPermissionType)
    case healthKitRegisterBGDeliveryFailure(permission: HealthKitPermissionType, error: String?)

    // misc
    case deepLinked(url: URL)
    case urlOpened(url: URL)
}
