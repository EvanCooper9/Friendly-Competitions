import UIKit

protocol Sharable {
    var itemsForSharing: [Any] { get }
}

extension Sharable {
    func share() {
        let activityVC = UIActivityViewController(
            activityItems: itemsForSharing,
            applicationActivities: nil
        )
        activityVC.excludedActivityTypes = [.mail, .addToReadingList, .assignToContact, .markupAsPDF, .openInIBooks, .saveToCameraRoll, .print]

        let keyWindow = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .filter(\.isKeyWindow)
            .first

        keyWindow?.rootViewController?
            .topViewController
            .present(activityVC, animated: true, completion: nil)
    }
}
