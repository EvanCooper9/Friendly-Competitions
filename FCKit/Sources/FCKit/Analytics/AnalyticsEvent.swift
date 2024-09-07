import Foundation

public enum AnalyticsEvent: Codable, Equatable {

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
    case healthKitPermissionsFailed(permission: String, error: String?)
    case healthKitRegisterBGDeliverySuccess(permission: String)
    case healthKitRegisterBGDeliveryFailure(permission: String, error: String?)
    case healthKitBGDeliveryError(permission: String, error: String?)
    case healthKitBGDeliveryReceived(permission: String)
    case healthKitBGDelieveryMissingPublisher(permission: String)
    case healthKitBGDeliveryProcessing(permission: String)
    case healthKitBGDeliveryTimeout(permission: String)
    case healthKitBGDeliverySuccess(permission: String)

    // Ads
    case adLoadStarted
    case adLoadSuccess
    case adLoadError(error: String?)
    case adImpression
    case adClick

    // misc
    case deepLinked(url: URL)
    case urlOpened(url: URL)
}
