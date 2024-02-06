import SwiftUI

enum WelcomeNavigationDestination: Hashable {
    case emailSignIn
}

extension WelcomeNavigationDestination {
    @ViewBuilder
    var view: some View {
        switch self {
        case .emailSignIn:
            EmailSignInView()
        }
    }
}
