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
    @Published private(set) var loadingStandings = false
    @Published private(set) var showShowMoreButton = false
    
    // MARK: - Private Properties

    private var competitionPreEdit: Competition
    @Published private var currentStandingsMaximum = 10
    
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
        
        let fetchStandingsAndParticipants = PassthroughSubject<Void, Never>()
        fetchStandingsAndParticipants
            .prepend(())
            .flatMapLatest(withUnretained: self) { strongSelf in
                Publishers
                    .CombineLatest(
                        strongSelf.competitionsManager.standings(for: competition.id).catchErrorJustReturn([]),
                        strongSelf.competitionsManager.participants(for: competition.id).catchErrorJustReturn([])
                    )
                    .eraseToAnyPublisher()
            }
            .handleEvents(
                withUnretained: self,
                receiveSubscription: { strongSelf, _ in strongSelf.loadingStandings = true }
            )
            .combineLatest($currentStandingsMaximum)
            .map { [weak self] standingsAndParticipants, limit in
                guard let strongSelf = self else { return [] }
                let (standings, participants) = standingsAndParticipants
                let currentUser = strongSelf.userManager.user
                var rows = standings
                    .sorted(by: \.rank)
                    .dropLast(max(0, standings.count - limit))
                    .map { standing in
                        CompetitionParticipantRow.Config(
                            user: participants.first { $0.id == standing.userId },
                            currentUser: currentUser,
                            standing: standing
                        )
                    }

                if !rows.contains(where: { $0.id == currentUser.id }), let standing = standings.first(where: { $0.userId == currentUser.id }) {
                    rows.append(CompetitionParticipantRow.Config(
                        user: currentUser,
                        currentUser: currentUser,
                        standing: standing
                    ))
                }

                return rows
            }
            .handleEvents(
                withUnretained: self,
                receiveOutput: { strongSelf, _ in strongSelf.loadingStandings = false }
            )
            .assign(to: &$standings)
        
        competitionsManager.competitionPublisher(for: competition.id)
            .ignoreFailure()
            .handleEvents(receiveOutput: { _ in fetchStandingsAndParticipants.send() })
            .assign(to: &$competition)
        
        Publishers.CombineLatest($standings, $currentStandingsMaximum)
            .map { $0.count >= $1 }
            .assign(to: &$showShowMoreButton)

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
                        .handleEvents(receiveOutput: { fetchStandingsAndParticipants.send() })
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
                        .handleEvents(receiveOutput: { fetchStandingsAndParticipants.send() })
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
                        .handleEvents(receiveOutput: { fetchStandingsAndParticipants.send() })
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
    
    func showMoreTapped() {
        currentStandingsMaximum += 10
    }
}

private extension CompetitionParticipantRow.Config {
    init(user: User?, currentUser: User, standing: Competition.Standing) {
        let visibility = user?.visibility(by: currentUser) ?? .hidden
        self.init(
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
