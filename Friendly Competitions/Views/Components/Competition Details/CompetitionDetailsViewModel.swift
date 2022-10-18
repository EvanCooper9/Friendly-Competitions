import Combine
import CombineExt
import Factory

final class CompetitionDetailsViewModel: ObservableObject {
    
    @Published var competition: Competition
    @Published var isInvitation = false
    
    @Injected(Container.userManager) private var userManager
    
    init(competition: Competition) {
        self.competition = competition
        isInvitation = competition.pendingParticipants.contains(userManager.user.value.id)
    }
}
