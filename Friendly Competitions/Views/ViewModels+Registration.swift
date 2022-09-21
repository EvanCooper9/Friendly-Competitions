import Resolver
import ResolverAutoregistration

extension Resolver {
    static func registerViewModels() {
        autoregister(CompetitionViewModel.self, argument: Competition.self, initializer: CompetitionViewModel.init)
        autoregister(DashboardViewModel.self, initializer: DashboardViewModel.init)
        autoregister(DeveloperViewModel.self, initializer: DeveloperViewModel.init)
        autoregister(ExploreViewModel.self, initializer: ExploreViewModel.init)
        autoregister(HomeViewModel.self, initializer: HomeViewModel.init)
        autoregister(InviteFriendsViewModel.self, argument: InviteFriendsAction.self, initializer: InviteFriendsViewModel.init)
        autoregister(NewCompetitionViewModel.self, initializer: NewCompetitionViewModel.init)
        autoregister(PermissionsViewModel.self, initializer: PermissionsViewModel.init)
        autoregister(ProfileViewModel.self, initializer: ProfileViewModel.init)
        autoregister(SignInViewModel.self, initializer: SignInViewModel.init)
        autoregister(UserViewModel.self, argument: User.self, initializer: UserViewModel.init)
        autoregister(VerifyEmailViewModel.self, initializer: VerifyEmailViewModel.init)
    }
}
