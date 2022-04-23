import Combine
import CombineExt
import Resolver

final class CompetitionViewModel: ObservableObject {

    struct StandingViewConfig: Identifiable {
        let id: String
        let rank: String?
        let name: String
        let idPillText: String?
        let blurred: Bool
        let points: Int?
        let highlighted: Bool
    }
    
    @Published var competition: Competition
    @Published var standings = [StandingViewConfig]()
    @Published var pendingParticipants = [StandingViewConfig]()
    @Published var user: User!
    @Published var friends = [User]()
        
    @Published var competitionInfoConfig: CompetitionInfo.Config

    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var userManager: AnyUserManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init(competition: Competition) {
        self.competition = competition
        self.competitionInfoConfig = .init(canEdit: false)
        user = userManager.user
        competitionInfoConfig.canEdit = user.id == competition.owner
        
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
                        idPillText: visibility == .visible ? user?.hashId : nil,
                        blurred: visibility == .hidden,
                        points: standing.points,
                        highlighted: standing.userId == self.user.id
                    )
                }
            }
            .assign(to: \.standings, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        competitionsManager.$pendingParticipants
            .map { [weak self] pendingParticipants in
                guard let self = self, let pendingParticipants = pendingParticipants[competition.id] else { return [] }
                return pendingParticipants.map { user in
                    let visibility = user.visibility(by: self.user)
                    return StandingViewConfig(
                        id: user.id,
                        rank: nil,
                        name: user.name,
                        idPillText: visibility == .visible ? user.hashId : nil,
                        blurred: visibility == .hidden,
                        points: nil,
                        highlighted: user.id == self.user.id
                    )
                }
            }
            .assign(to: \.pendingParticipants, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        friendsManager.$friends
            .assign(to: \.friends, on: self, ownership: .weak)
            .store(in: &cancellables)
        
        userManager.$user
            .assign(to: \.user, on: self, ownership: .weak)
            .store(in: &cancellables)
    }
    
    func editTapped() {
        competitionInfoConfig.editing.toggle()
    }
    
    func saveTapped() {
        competitionInfoConfig.editing.toggle()
        competitionsManager.update(competition)
    }
    
    func accept() {
        competitionsManager.accept(competition)
    }
    
    func decline() {
        competitionsManager.decline(competition)
    }
    
    func join() {
        competitionsManager.join(competition)
    }
    
    func leave() {
        competitionsManager.leave(competition)
    }
    
    func delete() {
        competitionsManager.delete(competition)
    }
    
    func invite(_ friend: User) {
        competitionsManager.invite(friend, to: competition)
    }
}
