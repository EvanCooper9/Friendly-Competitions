import Combine
import CombineExt
import Factory

final class CompetitionDetailsViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published var competition: Competition
    @Published var isInvitation = false

    // MARK: - Private Properties

    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.userManager) private var userManager

    // MARK: - Lifecycle

    init(competition: Competition) {
        self.competition = competition

        competitionsManager.competitionPublisher(for: competition.id)
            .catchErrorJustReturn(competition)
            .map { [weak self] in
                guard let self else { return false }
                return $0.pendingParticipants.contains(self.userManager.user.id)
            }
            .assign(to: &$isInvitation)
    }
}
