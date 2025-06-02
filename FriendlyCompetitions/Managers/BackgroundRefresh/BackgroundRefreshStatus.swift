import UIKit

enum BackgroundRefreshStatus: String, Codable {
    case denied
    case restricted
    case available
    case unknown

    init(from status: UIBackgroundRefreshStatus) {
        switch status {
        case .restricted:
            self = .restricted
        case .denied:
            self = .denied
        case .available:
            self = .available
        @unknown default:
            self = .unknown
        }
    }
}
