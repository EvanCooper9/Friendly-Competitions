import SwiftUI

enum NavigationDestination: Hashable {
    case competition(Competition, CompetitionResult?)
    case profile
    case user(User)
}

extension NavigationDestination: Identifiable {
    var id: String {
        switch self {
        case .competition(let competition, let result):
            return [competition.id, result?.id]
                .compacted()
                .joined(separator: "_")
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
        case .competition(let compeittion, let result):
            CompetitionContainerView(competition: compeittion, result: result)
        case .user(let user):
            UserView(user: user)
        case .profile:
            ProfileView()
        }
    }
}
