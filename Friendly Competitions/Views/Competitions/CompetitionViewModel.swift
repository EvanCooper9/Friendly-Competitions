import Combine
import CombineExt
import Resolver

final class CompetitionViewModel: ObservableObject {
    
    private enum ActionRequiringConfirmation {
        case delete
        case edit
        case leave
    }
    
    // MARK: - Public Properties
    
    @Published var canEdit = false
    var confirmationTitle: String { actionRequiringConfirmation?.confirmationTitle ?? "" }
    @Published var confirmationRequired = false
    @Published var competition: Competition
    @Published var editButtonTitle = "Edit"
    @Published var editing = false {
        didSet { editButtonTitle = editing ? "Cancel" : "Edit" }
    }
    @Published var standings = [CompetitionParticipantView.Config]()
    @Published var pendingParticipants = [CompetitionParticipantView.Config]()
    @Published var actions = [CompetitionViewAction]()
    @Published var showInviteFriend = false
    
    // MARK: - Private Properties

    @Injected private var competitionsManager: AnyCompetitionsManager
    @Injected private var userManager: AnyUserManager
    
    private var actionRequiringConfirmation: CompetitionViewAction? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    init(competition: Competition) {
        self.competition = competition
        canEdit = userManager.user.id == competition.owner
        
        $competition
            .map { [weak self] competition -> [CompetitionViewAction] in
                guard let user = self?.userManager.user else { return [] }
                
                var actions = [CompetitionViewAction]()
                if competition.pendingParticipants.contains(user.id) {
                    actions.append(contentsOf: [.acceptInvite, .declineInvite])
                } else if competition.participants.contains(user.id) {
                    actions.append(.leave)
                } else {
                    actions.append(.join)
                }
                
                if competition.repeats || !competition.ended {
                    actions.append(.invite)
                }
                
                if competition.owner == user.id {
                    actions.append(contentsOf: [.delete])
                }
                
                return actions
            }
            .assign(to: &$actions)
        
        $competition
            .map { [weak self] in $0.owner == self?.userManager.user.id }
            .assign(to: &$canEdit)
        
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
            confirm()
        }
    }
    
    func confirm() {
        switch actionRequiringConfirmation {
        case .delete:
            competitionsManager.delete(competition)
        case .edit:
            editing.toggle()
            competitionsManager.update(competition)
        case .leave:
            competitionsManager.leave(competition)
        default:
            break
        }
    }
    
    func perform(_ action: CompetitionViewAction) {
        switch action {
        case .acceptInvite:
            competitionsManager.accept(competition)
        case .declineInvite:
            competitionsManager.decline(competition)
        case .delete, .leave:
            actionRequiringConfirmation = action
        case .edit:
            editing.toggle()
        case .invite:
            showInviteFriend.toggle()
        case .join:
            competitionsManager.join(competition)
        }
    }
}
