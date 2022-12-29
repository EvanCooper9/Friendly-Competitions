enum TutorialStep: String, CaseIterable, Codable, CustomStringConvertible {
    
    enum Category {
        case tabBar
        case dashboard
        case explore
    }
    
    // Tab bar
    case tabBarDashboard
    case tabBarExplore
    
    // Home
    case dashboardCreateCompetition
    case dashboardAddFriends
    case dashboardProfile
    
    // Explore
    
    var category: Category {
        switch self {
        case .tabBarDashboard,
                .tabBarExplore:
            return .tabBar
        case .dashboardCreateCompetition,
                .dashboardAddFriends,
                .dashboardProfile:
            return .dashboard
        }
    }
    
    var description: String {
        switch self {
        case .tabBarDashboard:
            return "See your rings, competitions and friends at a glance"
        case .tabBarExplore:
            return "Explore and search for public competitions"
        case .dashboardCreateCompetition:
            return "Create new competitions"
        case .dashboardAddFriends:
            return "Search for and add friends"
        case .dashboardProfile:
            return "View your profile & settings"
        }
    }
}

extension Array where Element == TutorialStep {
    static var all: [TutorialStep] {
        [
            .dashboardCreateCompetition,
            .dashboardAddFriends
        ]
    }
}
