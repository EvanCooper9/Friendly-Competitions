import ECKit
import Foundation

extension URL {
    static let termsOfService = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    static let privacyPolicy = URL(string: "https://www.termsfeed.com/live/83fffe02-9426-43f1-94ca-aedea5df3d24")!
    static let developer = URL(string: "https://evancooper.tech")!

    static func featureRequest(with userID: User.ID) -> URL {
        URL(string: "https://www.reddit.com/r/friendlycompetitions/submit")!
            .appending(queryItems: [
                .init(name: "title", value: "Feature request"),
                .init(name: "text", value: body(with: userID))
            ])
    }

    static func bugReport(with userID: User.ID) -> URL {
        URL(string: "https://www.reddit.com/r/friendlycompetitions/submit")!
            .appending(queryItems: [
                .init(name: "title", value: "Bug report"),
                .init(name: "text", value: body(with: userID))
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
