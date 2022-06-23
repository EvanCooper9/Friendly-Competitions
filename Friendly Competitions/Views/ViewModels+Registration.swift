import Resolver


extension Resolver {
    static func registerViewModels() {
        register { (_, args) in CompetitionViewModel(competitionsManager: resolve(), userManager: resolve(), competition: args()) }
        register { DashboardViewModel(activitySummaryManager: resolve(), competitionsManager: resolve(), friendsManager: resolve(), permissionsManager: resolve(), userManager: resolve()) }
        register { ExploreViewModel(competitionsManager: resolve()) }
        register { HomeViewModel(competitionsManager: resolve(), friendsManager: resolve()) }
        register { (_, args) in InviteFriendsViewModel(competitionsManager: resolve(), friendsManager: resolve(), userManager: resolve(), action: args())}
        register { NewCompetitionViewModel(competitionsManager: resolve(), friendsManager: resolve(), userManager: resolve()) }
        register { PermissionsViewModel(permissionsManager: resolve()) }
        register { ProfileViewModel(authenticationManager: resolve(), userManager: resolve()) }
        register { SignInViewModel(appState: resolve(), authenticationManager: resolve()) }
        register { (_, args) in UserViewModel(friendsManager: resolve(), userManager: resolve(), user: args()) }
        register { VerifyEmailViewModel(appState: resolve(), authenticationManager: resolve(), userManager: resolve()) }
    }
}
