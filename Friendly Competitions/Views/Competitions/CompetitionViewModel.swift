import Combine
import CombineExt
import Resolver

final class CompetitionViewModel: ObservableObject {
    
    struct StandingViewConfig: Identifiable {
        let id: String
        let rank: String
        let name: String
        let blurred: Bool
        let points: Int
        let highlighted: Bool
    }
    
    @Published var standings = [StandingViewConfig]()
    @Published var pendingParticipants = [User]()
    @Published var user: User!

    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var userManager: AnyUserManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(competition: Competition) {
        user = userManager.user
        
        competitionsManager.$standings
            .map { [weak self] standings -> [StandingViewConfig] in
                guard let self = self, let standings = standings[competition.id] else { return [] }
                let participants = self.competitionsManager.participants[competition.id] ?? []
                
                return standings.map { standing in
                    
                    let user = participants.first {
                        $0.id == standing.userId
                    }
                    
                    let visibility = user?.visibility(by: self.user) ?? .hidden
                    
                    return StandingViewConfig(
                        id: standing.id,
                        rank: standing.rank.ordinalString ?? "?",
                        name: user?.name ?? standing.userId,
                        blurred: visibility == .hidden,
                        points: standing.points,
                        highlighted: standing.userId == self.user.id
                    )
                }
            }
            .assign(to: \.standings, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        userManager.$user
            .assign(to: \.user, on: self, ownership: .weak)
            .store(in: &cancellables)
    }
    
    func accept(_ competition: Competition) {
        competitionsManager.accept(competition)
    }
    
    func decline(_ competition: Competition) {
        competitionsManager.decline(competition)
    }
    
    func join(_ competition: Competition) {
        competitionsManager.join(competition)
    }
    
    func leave(_ competition: Competition) {
        
    }
    
    func delete(_ competition: Competition) {
        
    }
}
