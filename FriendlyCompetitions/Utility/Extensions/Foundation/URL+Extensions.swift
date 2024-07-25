import ECKit
import Foundation
import UIKit

extension URL {
    static let termsOfService = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyPolicy = URL(string: "https://www.termsfeed.com/live/83fffe02-9426-43f1-94ca-aedea5df3d24")!
    static let developer = URL(string: "https://evancooper.tech")!
    static let buyMeCoffee = URL(string: "https://www.buymeacoffee.com/ntxzfb2w5ni")!
    static let gitHub = URL(string: "https://github.com/EvanCooper9/Friendly-Competitions")!
    static let health = URL(string: "x-apple-health://")!
    static let notificationSettings = URL(string: UIApplication.openNotificationSettingsURLString)!
    static let settings = URL(string: UIApplication.openSettingsURLString)!

    static func featureRequest(with userID: User.ID) -> URL {
        URL(string: "mailto:ideas@friendly-competitions.app")!
            .appending(queryItems: [
                .init(name: "subject", value: "Feature request"),
                .init(name: "body", value: body(with: userID))
            ])
    }

    static func bugReport(with userID: User.ID) -> URL {
        URL(string: "mailto:help@friendly-competitions.app")!
            .appending(queryItems: [
                .init(name: "subject", value: "Bug report"),
                .init(name: "body", value: body(with: userID))
            ])
    }

    // MARK: - Private

    private static func body(with userID: User.ID) -> String {
        """
        Description:


        ------------------------------
        App info (Please don't delete)
        App version: \(Bundle.main.version)
        iOS version: \(Device.iOSVersion)
        Device model: \(Device.modelName)
        Trace: \(userID)
        """
    }
}
