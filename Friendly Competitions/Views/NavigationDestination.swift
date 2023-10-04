import SwiftUI

enum NavigationDestination: Hashable {
    case competition(Competition)
    case profile
    case user(User)
}

extension NavigationDestination: Identifiable {
    var id: String {
        switch self {
        case .competition(let competition):
            return competition.id
        case .profile:
            return "profile"
        case .user(let user):
            return user.id
        }
    }
}

extension NavigationDestination {
    @ViewBuilder
    var view: some View {
        switch self {
        case .competition(let compeittion):
            CompetitionContainerView(competition: compeittion)
        case .user(let user):
            UserView(user: user)
        case .profile:
            ProfileView()
        }
    }
}
