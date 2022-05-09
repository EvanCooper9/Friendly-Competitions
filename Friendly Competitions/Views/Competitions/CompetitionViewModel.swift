import Combine
import CombineExt
import Resolver

final class CompetitionViewModel: ObservableObject {
    
    private enum ActionRequiringConfirmation {
        case deleteCompetition
        case leaveCompetition
    }
    
    @Published var confirmationRequired = false
    @Published var competition: Competition
    @Published var standings = [CompetitionParticipantView.Config]()
    @Published var pendingParticipants = [CompetitionParticipantView.Config]()
    @Published var user: User!
    @Published var friends = [User]()
    @Published var competitionInfoConfig: CompetitionInfo.Config
    
    var showInviteButton: Bool {
        let joined = competition.participants.contains(userManager.user.id)
        let active = competition.repeats || !competition.ended
        return joined && active
    }
    var showDeleteButton: Bool { competition.owner == userManager.user.id }
    var showJoinButton: Bool { !showLeaveButton }
    var showLeaveButton: Bool { competition.participants.contains(userManager.user.id) }
    var showInvitedButtons: Bool { competition.pendingParticipants.contains(userManager.user.id) }

    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var friendsManager: AnyFriendsManager
    @Injected private var userManager: AnyUserManager
    
    private var actionRequiringConfirmation: ActionRequiringConfirmation? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(competition: Competition) {
        self.competition = competition
        self.competitionInfoConfig = .init(canEdit: false)
        user = userManager.user
        competitionInfoConfig.canEdit = user.id == competition.owner
        
        competitionsManager.$competitions
            .compactMap { $0.first { $0.id == competition.id } }
            .assign(to: &$competition)
        
        competitionsManager.$standings
            .map { [weak self] standings -> [CompetitionParticipantView.Config] in
                guard let self = self, let standings = standings[competition.id] else { return [] }
                let participants = self.competitionsManager.participants[competition.id] ?? []
                
                return standings.map { standing in
                    
                    let user = participants.first {
                        $0.id == standing.userId
                    }
                    
                    let visibility = user?.visibility(by: self.user) ?? .hidden
                    
                    return CompetitionParticipantView.Config(
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
            .assign(to: &$standings)
        
        competitionsManager.$pendingParticipants
            .map { [weak self] pendingParticipants in
                guard let self = self, let pendingParticipants = pendingParticipants[competition.id] else { return [] }
                return pendingParticipants.map { user in
                    let visibility = user.visibility(by: self.user)
                    return CompetitionParticipantView.Config(
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
            .assign(to: &$pendingParticipants)
        
        friendsManager.$friends.assign(to: &$friends)
        
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
    
    func leaveTapped() {
        actionRequiringConfirmation = .leaveCompetition
    }
    
    func deleteTapped() {
        actionRequiringConfirmation = .deleteCompetition
    }
    
    func invite(_ friend: User) {
        competitionsManager.invite(friend, to: competition)
    }
    
    func confirm() {
        guard let action = actionRequiringConfirmation else { return }
        switch action {
        case .deleteCompetition:
            competitionsManager.delete(competition)
        case .leaveCompetition:
            competitionsManager.leave(competition)
        }
    }
}
