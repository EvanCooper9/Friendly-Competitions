import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class CompetitionViewModel: ObservableObject {
    
    private enum ActionRequiringConfirmation {
        case delete
        case edit
        case leave
    }
    
    // MARK: - Public Properties
    
    @Published private(set) var canEdit = false
    var confirmationTitle: String { actionRequiringConfirmation?.confirmationTitle ?? "" }
    @Published var confirmationRequired = false
    @Published var competition: Competition
    @Published var editButtonTitle = "Edit"
    @Published var editing = false
    @Published var standings = [CompetitionParticipantRow.Config]()
    @Published var pendingParticipants = [CompetitionParticipantRow.Config]()
    @Published var actions = [CompetitionViewAction]()
    @Published var showInviteFriend = false
    @Published private(set) var showResults = false
    @Published private(set) var loading = false
    
    // MARK: - Private Properties

    private var competitionPreEdit: Competition
    
    private var actionRequiringConfirmation: CompetitionViewAction? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }
    
    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.functions) private var functions
    @Injected(Container.userManager) private var userManager

    private let confirmActionSubject = PassthroughSubject<Void, Error>()
    private let performActionSubject = PassthroughSubject<CompetitionViewAction, Error>()
    private let saveEditsSubject = PassthroughSubject<Void, Error>()
    private let recordResultsSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle
    
    init(competition: Competition) {
        self.competition = competition
        competitionPreEdit = competition

        userManager.userPublisher
            .map { $0.id == competition.owner }
            .assign(to: &$canEdit)
        
        competitionsManager.results(for: competition.id)
            .map(\.isNotEmpty)
            .ignoreFailure()
            .assign(to: &$showResults)
        
        $editing
            .map { $0  ? "Cancel" : "Edit" }
            .assign(to: &$editButtonTitle)
        
        $competition
            .combineLatest(userManager.userPublisher)
            .map { competition, user -> [CompetitionViewAction] in
                .build {
                    if competition.repeats || !competition.ended {
                        .invite
                    }
                    if competition.pendingParticipants.contains(user.id) {
                        CompetitionViewAction.acceptInvite
                        CompetitionViewAction.declineInvite
                    } else if competition.participants.contains(user.id) {
                        .leave
                    } else {
                        .join
                    }
                    if competition.owner == user.id {
                        .delete
                    }
                }
            }
            .assign(to: &$actions)
        
        competitionsManager.competitions
            .compactMap { $0.first { $0.id == competition.id } }
            .receive(on: RunLoop.main)
            .assign(to: &$competition)
        
        competitionsManager.standings
            .combineLatest(competitionsManager.participants, userManager.userPublisher)
            .map { standings, participants, currentUser -> [CompetitionParticipantRow.Config] in
                guard let standings = standings[competition.id],
                      let participants = participants[competition.id]
                else { return [] }

                return standings.map { standing in
                    let user = participants.first { $0.id == standing.userId }
                    let visibility = user?.visibility(by: currentUser) ?? .hidden
                    return CompetitionParticipantRow.Config(
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
            .receive(on: RunLoop.main)
            .assign(to: &$standings)
        
        competitionsManager.pendingParticipants
            .combineLatest(userManager.userPublisher)
            .map { pendingParticipants, user in
                guard let pendingParticipants = pendingParticipants[competition.id] else { return [] }
                return pendingParticipants.map { pendingParticipant in
                    let visibility = user.visibility(by: user)
                    return CompetitionParticipantRow.Config(
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
            .receive(on: RunLoop.main)
            .assign(to: &$pendingParticipants)

        confirmActionSubject
            .flatMapLatest(withUnretained: self) { strongSelf -> AnyPublisher<Void, Error> in
                switch strongSelf.actionRequiringConfirmation {
                case .delete:
                    return strongSelf.competitionsManager
                        .delete(competition)
                        .isLoading { strongSelf.loading = $0 }
                        .eraseToAnyPublisher()
                case .edit:
                    strongSelf.saveEditsSubject.send()
                    return .just(())
                case .leave:
                    return strongSelf.competitionsManager
                        .leave(competition)
                        .isLoading { strongSelf.loading = $0 }
                        .eraseToAnyPublisher()
                default:
                    return .empty()
                }
            }
            .sink()
            .store(in: &cancellables)

        saveEditsSubject
            .flatMapLatest(withUnretained: self) { strongSelf -> AnyPublisher<Void, Error> in
                strongSelf.editing.toggle()
                strongSelf.competitionPreEdit = strongSelf.competition
                return strongSelf.competitionsManager
                    .update(strongSelf.competition)
                    .isLoading { strongSelf.loading = $0 }
                    .eraseToAnyPublisher()
            }
            .sink()
            .store(in: &cancellables)

        performActionSubject
            .flatMapLatest(withUnretained: self) { strongSelf, action -> AnyPublisher<Void, Error> in
                switch action {
                case .acceptInvite:
                    return strongSelf.competitionsManager
                        .accept(competition)
                        .isLoading { strongSelf.loading = $0 }
                        .eraseToAnyPublisher()
                case .declineInvite:
                    return strongSelf.competitionsManager
                        .decline(competition)
                        .isLoading { strongSelf.loading = $0 }
                        .eraseToAnyPublisher()
                case .delete, .leave:
                    strongSelf.actionRequiringConfirmation = action
                    return .empty()
                case .edit:
                    strongSelf.editing.toggle()
                    return .empty()
                case .invite:
                    strongSelf.showInviteFriend.toggle()
                    return .empty()
                case .join:
                    return strongSelf.competitionsManager
                        .join(competition)
                        .isLoading { strongSelf.loading = $0 }
                        .eraseToAnyPublisher()
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
            saveEditsSubject.send()
        }
    }
    
    func confirm() {
        confirmActionSubject.send()
    }
    
    func perform(_ action: CompetitionViewAction) {
        performActionSubject.send(action)
    }
}
