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
    @Published var editButtonTitle = L10n.Competition.Action.Edit.buttonTitle
    @Published var editing = false
    @Published var standings = [CompetitionParticipantRow.Config]()
    @Published var pendingParticipants = [CompetitionParticipantRow.Config]()
    @Published var actions = [CompetitionViewAction]()
    @Published var showInviteFriend = false
    @Published private(set) var showResults = false
    @Published private(set) var loading = false
    @Published private(set) var loadingStandings = false
    @Published private(set) var showShowMoreButton = false

    var details: [(value: String, valueType: ImmutableListItemView.ValueType)] {
        [
            (
                value: competition.start.formatted(date: .abbreviated, time: .omitted),
                valueType: .date(description: competition.started ? "Started" : "Starts")
            ),
            (
                value: competition.end.formatted(date: .abbreviated, time: .omitted),
                valueType: .date(description: competition.ended ? "Ended" : "Ends")
            ),
            (
                value: competition.scoringModel.displayName,
                valueType: .other(systemImage: .plusminusCircle, description: "Scoring")
            ),
            (
                value: competition.repeats ? L10n.Generics.yes : L10n.Generics.no,
                valueType: .other(systemImage: .repeatCircle, description: "Restarts")
            )
        ]
    }

    // MARK: - Private Properties

    private var competitionPreEdit: Competition
    @Published private var currentStandingsMaximum = 10

    private var actionRequiringConfirmation: CompetitionViewAction? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }

    @Injected(\.api) private var api
    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.scheduler) private var scheduler
    @Injected(\.userManager) private var userManager

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
            .map { $0  ? L10n.Generics.cancel : L10n.Competition.Action.Edit.buttonTitle }
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

        let fetchParticipants = PassthroughSubject<Void, Never>()
        let participants = fetchParticipants
            .prepend(())
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.competitionsManager
                    .participants(for: competition.id)
                    .catchErrorJustReturn([])
            }

        $competition
            .map(\.participants)
            .removeDuplicates()
            .dropFirst()
            .mapToVoid()
            .sink { fetchParticipants.send() }
            .store(in: &cancellables)

        Publishers
            .CombineLatest(
                competitionsManager.standingsPublisher(for: competition.id).catchErrorJustReturn([]),
                participants
            )
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
            .receive(on: scheduler)
            .handleEvents(
                withUnretained: self,
                receiveOutput: { strongSelf, _ in strongSelf.loadingStandings = false }
            )
            .assign(to: &$standings)

        competitionsManager.competitionPublisher(for: competition.id)
            .ignoreFailure()
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
                        .handleEvents(receiveOutput: { fetchParticipants.send() })
                        .isLoading { strongSelf.loading = $0 }
                        .eraseToAnyPublisher()
                default:
                    return .empty()
                }
            }
            .sink()
            .store(in: &cancellables)

        saveEditsSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
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
                        .handleEvents(receiveOutput: { fetchParticipants.send() })
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
                        .handleEvents(receiveOutput: { fetchParticipants.send() })
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
