import SwiftUI

enum NavigationDestination: Hashable {
    case competition(Competition)
    case competitionHistory(Competition)
    case profile
    case user(User)
}

extension NavigationDestination {
    @ViewBuilder
    var view: some View {
        switch self {
        case .competition(let compeittion):
            CompetitionView(competition: compeittion)
        case .competitionHistory(let competition):
            CompetitionHistoryView(competition: competition)
        case .user(let user):
            UserView(user: user)
        case .profile:
            ProfileView()
        }
    }
}
