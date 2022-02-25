import Foundation
import UIKit

extension Bundle {
    var icon: UIImage! {
        let icons = infoDictionary!["CFBundleIcons"] as! [String: Any]
        let primaryIcon = icons["CFBundlePrimaryIcon"] as! [String: Any]
        let iconFiles = primaryIcon["CFBundleIconFiles"] as! [String]
        return UIImage(named: iconFiles.last!)
    }

    var name: String {
        infoDictionary!["CFBundleName"] as! String
    }

    var displayName: String {
        infoDictionary!["CFBundleDisplayName"] as! String
    }

    var version: String {
        infoDictionary!["CFBundleShortVersionString"] as! String
    }

    var id: String {
        let id = infoDictionary!["CFBundleIdentifier"] as! String
        return id.before(suffix: ".debug") ?? id
    }
}
