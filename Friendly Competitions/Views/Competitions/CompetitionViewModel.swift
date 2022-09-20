import Combine
import CombineExt
import ECKit

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

    private var competitionPreEdit: Competition
    
    private var actionRequiringConfirmation: CompetitionViewAction? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }

    private let _confirm = PassthroughSubject<Void, Error>()
    private let _perform = PassthroughSubject<CompetitionViewAction, Error>()
    private let _saveEdits = PassthroughSubject<Void, Error>()
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle
    
    init(competitionsManager: CompetitionsManaging, userManager: UserManaging, competition: Competition) {
        self.competition = competition
        self.competitionPreEdit = competition

        userManager.user
            .map { $0.id == competition.owner }
            .assign(to: &$canEdit)
        
        $competition
            .combineLatest(userManager.user)
            .map { competition, user -> [CompetitionViewAction] in
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
                    actions.append(.delete)
                }
                
                return actions
            }
            .assign(to: &$actions)
        
        competitionsManager.competitions
            .compactMap { $0.first { $0.id == competition.id } }
            .assign(to: &$competition)
        
        competitionsManager.standings
            .combineLatest(competitionsManager.participants, userManager.user)
            .map { standings, participants, currentUser -> [CompetitionParticipantView.Config] in
                guard let standings = standings[competition.id],
                      let participants = participants[competition.id]
                else { return [] }

                return standings.map { standing in
                    let user = participants.first { $0.id == standing.userId }
                    let visibility = user?.visibility(by: currentUser) ?? .hidden
                    return CompetitionParticipantView.Config(
                        id: standing.id,
                        rank: standing.rank.ordinalString ?? "?",
                        name: user?.name ?? standing.userId,
                        idPillText: visibility == .visible ? user?.hashId : nil,
                        blurred: visibility == .hidden,
                        points: standing.points,
                        highlighted: standing.userId == currentUser.id
                    )
                }
            }
            .assign(to: &$standings)
        
        competitionsManager.pendingParticipants
            .combineLatest(userManager.user)
            .map { pendingParticipants, user in
                guard let pendingParticipants = pendingParticipants[competition.id] else { return [] }
                return pendingParticipants.map { pendingParticipant in
                    let visibility = user.visibility(by: user)
                    return CompetitionParticipantView.Config(
                        id: pendingParticipant.id,
                        rank: nil,
                        name: pendingParticipant.name,
                        idPillText: visibility == .visible ? user.hashId : nil,
                        blurred: visibility == .hidden,
                        points: nil,
                        highlighted: pendingParticipant.id == user.id
                    )
                }
            }
            .assign(to: &$pendingParticipants)

        _confirm
            .flatMapLatest(withUnretained: self) { object -> AnyPublisher<Void, Error> in
                switch object.actionRequiringConfirmation {
                case .delete:
                    return competitionsManager.delete(competition)
                case .edit:
                    object._saveEdits.send()
                    return .just(())
                case .leave:
                    return competitionsManager.leave(competition)
                default:
                    return .empty()
                }
            }
            .sink()
            .store(in: &cancellables)

        _saveEdits
            .flatMapLatest(withUnretained: self) { strongSelf -> AnyPublisher<Void, Error> in
                strongSelf.editing.toggle()
                strongSelf.competitionPreEdit = strongSelf.competition
                return competitionsManager.update(strongSelf.competition)
            }
            .sink()
            .store(in: &cancellables)

        _perform
            .flatMapLatest(withUnretained: self) { object, action -> AnyPublisher<Void, Error> in
                switch action {
                case .acceptInvite:
                    return competitionsManager.accept(competition)
                case .declineInvite:
                    return competitionsManager.decline(competition)
                case .delete, .leave:
                    object.actionRequiringConfirmation = action
                    return .empty()
                case .edit:
                    object.editing.toggle()
                    return .empty()
                case .invite:
                    object.showInviteFriend.toggle()
                    return .empty()
                case .join:
                    return competitionsManager.join(competition)
                }
            }
            .sink()
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func editTapped() {
        if editing { // cancelling edit
            competition = competitionPreEdit
        }
        editing.toggle()
    }
    
    func saveTapped() {
        if competition.start != competitionPreEdit.start || competition.end != competitionPreEdit.end {
            actionRequiringConfirmation = .edit
        } else {
            _saveEdits.send()
        }
    }
    
    func confirm() {
        _confirm.send()
    }
    
    func perform(_ action: CompetitionViewAction) {
        _perform.send(action)
    }
}
