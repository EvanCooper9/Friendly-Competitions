import Combine
import CombineExt
import Resolver

final class CompetitionViewModel: ObservableObject {
    
    private enum ActionRequiringConfirmation {
        case delete
        case edit
        case leave
        
        var title: String {
            switch self {
            case .delete:
                return "Are you sure you want to delete?"
            case .edit:
                return "Are you sure? Editing competition dates will re-calculate scores."
            case .leave:
                return "Are you sure you want to leave?"
            }
        }
    }
    
    // MARK: - Public Properties
    
    @Published var canEdit = false
    var confirmationTitle: String { actionRequiringConfirmation?.title ?? "" }
    @Published var confirmationRequired = false
    @Published var competition: Competition
    @Published var editButtonTitle = "Edit"
    @Published var editing = false {
        didSet { editButtonTitle = editing ? "Cancel" : "Edit" }
    }
    @Published var standings = [CompetitionParticipantView.Config]()
    @Published var pendingParticipants = [CompetitionParticipantView.Config]()
    
    var showInviteButton: Bool {
        let joined = competition.participants.contains(userManager.user.id)
        let active = competition.repeats || !competition.ended
        return joined && active
    }
    var showDeleteButton: Bool { competition.owner == userManager.user.id }
    var showJoinButton: Bool { !showLeaveButton }
    var showLeaveButton: Bool { competition.participants.contains(userManager.user.id) }
    var showInvitedButtons: Bool { competition.pendingParticipants.contains(userManager.user.id) }
    
    // MARK: - Private Properties

    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var userManager: AnyUserManager
    
    private var actionRequiringConfirmation: ActionRequiringConfirmation? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    init(competition: Competition) {
        self.competition = competition
        canEdit = userManager.user.id == competition.owner
        
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
                    
                    let visibility = user?.visibility(by: self.userManager.user) ?? .hidden
                    
                    return CompetitionParticipantView.Config(
                        id: standing.id,
                        rank: standing.rank.ordinalString ?? "?",
                        name: user?.name ?? standing.userId,
                        idPillText: visibility == .visible ? user?.hashId : nil,
                        blurred: visibility == .hidden,
                        points: standing.points,
                        highlighted: standing.userId == self.userManager.user.id
                    )
                }
            }
            .assign(to: &$standings)
        
        competitionsManager.$pendingParticipants
            .map { [weak self] pendingParticipants in
                guard let self = self, let pendingParticipants = pendingParticipants[competition.id] else { return [] }
                return pendingParticipants.map { user in
                    let visibility = user.visibility(by: self.userManager.user)
                    return CompetitionParticipantView.Config(
                        id: user.id,
                        rank: nil,
                        name: user.name,
                        idPillText: visibility == .visible ? user.hashId : nil,
                        blurred: visibility == .hidden,
                        points: nil,
                        highlighted: user.id == self.userManager.user.id
                    )
                }
            }
            .assign(to: &$pendingParticipants)
    }
    
    // MARK: - Public Methods
    
    func editTapped() {
        editing.toggle()
    }
    
    func saveTapped() {
        guard let oldCompetition = competitionsManager.competitions.first(where: { $0.id == competition.id }) else { return }
        if oldCompetition.start != competition.start || oldCompetition.end != competition.end {
            actionRequiringConfirmation = .edit
        } else {
            editing.toggle()
            competitionsManager.update(competition)
        }
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
        actionRequiringConfirmation = .leave
    }
    
    func deleteTapped() {
        actionRequiringConfirmation = .delete
    }
    
    func invite(_ friend: User) {
        competitionsManager.invite(friend, to: competition)
    }
    
    func confirm() {
        guard let action = actionRequiringConfirmation else { return }
        switch action {
        case .delete:
            competitionsManager.delete(competition)
        case .edit:
            editing.toggle()
            competitionsManager.update(competition)
        case .leave:
            competitionsManager.leave(competition)
        }
    }
    
    func retract() {
        actionRequiringConfirmation = nil
    }
}
