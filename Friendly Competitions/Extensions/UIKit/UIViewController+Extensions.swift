import UIKit

extension UIViewController {
    var topViewController: UIViewController {
        guard let presentedViewController = presentedViewController else { return self }
        return presentedViewController.topViewController
    }
}
