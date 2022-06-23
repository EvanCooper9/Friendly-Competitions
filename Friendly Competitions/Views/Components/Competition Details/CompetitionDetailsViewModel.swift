import Combine
import CombineExt
import Resolver

final class CompetitionDetailsViewModel: ObservableObject {
    
    @Published var competition: Competition
    @Published var isInvitation = false
    
    @Injected private var userManager: UserManaging
    
    init(competition: Competition) {
        self.competition = competition
        isInvitation = competition.pendingParticipants.contains(userManager.user.value.id)
    }
}
