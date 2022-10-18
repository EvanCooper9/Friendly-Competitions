import Combine
import CombineExt
import Factory

final class CompetitionDetailsViewModel: ObservableObject {
    
    // MARK: - Public Properties
    
    @Published var competition: Competition
    @Published var isInvitation = false
    
    // MARK: - Private Properties
    
    @Injected(Container.userManager) private var userManager
    
    // MARK: - Lifecycle
    
    init(competition: Competition) {
        self.competition = competition
        isInvitation = competition.pendingParticipants.contains(userManager.user.value.id)
    }
}
