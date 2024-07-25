import Combine
import CombineExt
import CombineSchedulers
import ECKit
import Factory
import Foundation
import UIKit

final class CompetitionViewModel: ObservableObject {

    private enum ActionRequiringConfirmation {
        case delete
        case leave
    }

    // MARK: - Public Properties

    @Published private(set) var banners = [Banner]()
    @Published private(set) var canEdit = false
    var confirmationTitle: String { actionRequiringConfirmation?.confirmationTitle ?? "" }
    @Published var confirmationRequired = false
    @Published var competition: Competition
    @Published var editing = false
    @Published var standings = [CompetitionParticipantRow.Config]()
    @Published var pendingParticipants = [CompetitionParticipantRow.Config]()
    @Published var actions = [CompetitionViewAction]()
    @Published var showInviteFriend = false
    @Published private(set) var loading = false
    @Published private(set) var loadingStandings = false
    @Published private(set) var showShowMoreButton = false
    @Published private(set) var dismiss = false

    var details: [(value: String, valueType: ImmutableListItemView.ValueType)] {
        [
            (value: competition.start.formatted(date: .abbreviated, time: .omitted), valueType: .date(description: competition.started ? L10n.Competition.Details.started : L10n.Competition.Details.starts)),
            (value: competition.end.formatted(date: .abbreviated, time: .omitted), valueType: .date(description: competition.ended ? L10n.Competition.Details.ended : L10n.Competition.Details.ends)),
            (value: competition.scoringModel.displayName, valueType: .other(systemImage: .plusminusCircle, description: L10n.Competition.Details.scoringModel)),
            (value: competition.repeats ? L10n.Generics.yes : L10n.Generics.no, valueType: .other(systemImage: .repeatCircle, description: L10n.Competition.Details.repeats))
        ]
    }

    // MARK: - Private Properties

    @Published private var currentStandingsMaximum = 10

    private var actionRequiringConfirmation: CompetitionViewAction? {
        didSet { confirmationRequired = actionRequiringConfirmation != nil }
    }

    @Injected(\.activitySummaryManager) private var activitySummaryManager: ActivitySummaryManaging
    @Injected(\.api) private var api: API
    @Injected(\.appState) private var appState: AppStateProviding
    @Injected(\.bannerManager) private var bannerManager: BannerManaging
    @Injected(\.competitionsManager) private var competitionsManager: CompetitionsManaging
    @Injected(\.healthKitManager) private var healthKitManager: HealthKitManaging
    @Injected(\.notificationsManager) private var notificationManager: NotificationsManaging
    @Injected(\.scheduler) private var scheduler: AnySchedulerOf<RunLoop>
    @Injected(\.searchManager) private var searchManager: SearchManaging
    @Injected(\.stepCountManager) private var stepCountManager: StepCountManaging
    @Injected(\.userManager) private var userManager: UserManaging
    @Injected(\.workoutManager) private var workoutManager: WorkoutManaging

    private let confirmActionSubject = PassthroughSubject<Void, Error>()
    private let performActionSubject = PassthroughSubject<CompetitionViewAction, Error>()
    private let fetchParticipantsSubject = PassthroughSubject<[String], Never>()
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(competition: Competition) {
        self.competition = competition

        bindBanners()
        bindStandings()

        userManager.userPublisher
            .map { $0.id == competition.owner }
            .assign(to: &$canEdit)

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

        $competition
            .map(\.participants)
            .removeDuplicates()
            .dropFirst()
            .sink(withUnretained: self) { $0.fetchParticipantsSubject.send($1) }
            .store(in: &cancellables)

        competitionsManager.competitionPublisher(for: competition.id)
            .ignoreFailure()
            .assign(to: &$competition)

        confirmActionSubject
            .flatMapLatest(withUnretained: self) { strongSelf -> AnyPublisher<Void, Error> in
                switch strongSelf.actionRequiringConfirmation {
                case .delete:
                    return strongSelf.api
                        .call(.deleteCompetition(id: competition.id))
                        .isLoading { strongSelf.loading = $0 }
                        .handleEvents(withUnretained: self, receiveOutput: { strongSelf in
                            strongSelf.dismiss = true
                        })
                        .eraseToAnyPublisher()
                case .leave:
                    return strongSelf.api
                        .call(.leaveCompetition(id: competition.id))
                        .isLoading { strongSelf.loading = $0 }
                        .handleEvents(withUnretained: self, receiveOutput: { strongSelf in
                            strongSelf.dismiss = true
                        })
                        .eraseToAnyPublisher()
                default:
                    return .empty()
                }
            }
            .sink()
            .store(in: &cancellables)

        performActionSubject
            .flatMapLatest(withUnretained: self) { strongSelf, action -> AnyPublisher<Void, Error> in
                switch action {
                case .acceptInvite:
                    return strongSelf.api
                        .call(.respondToCompetitionInvite(id: competition.id, accept: true))
                        .isLoading { strongSelf.loading = $0 }
                        .eraseToAnyPublisher()
                case .declineInvite:
                    return strongSelf.api
                        .call(.respondToCompetitionInvite(id: competition.id, accept: false))
                        .isLoading { strongSelf.loading = $0 }
                        .eraseToAnyPublisher()
                case .delete, .leave:
                    strongSelf.actionRequiringConfirmation = action
                    return .empty()
                case .invite:
                    strongSelf.showInviteFriend.toggle()
                    return .empty()
                case .join:
                    return strongSelf.api
                        .call(.joinCompetition(id: competition.id))
                        .isLoading { strongSelf.loading = $0 }
                        .eraseToAnyPublisher()
                }
            }
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func confirm() {
        confirmActionSubject.send()
    }

    func editTapped() {
        editing.toggle()
    }

    func perform(_ action: CompetitionViewAction) {
        performActionSubject.send(action)
    }

    func showMoreTapped() {
        currentStandingsMaximum += 10
    }

    func tapped(_ banner: Banner) {
        bannerManager.tapped(banner)
            .sink()
            .store(in: &cancellables)
    }

    func dismissed(_ banner: Banner) {
        bannerManager.dismissed(banner)
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func bindBanners() {
        bannerManager.banners
            .filterMany { banner in
                switch banner {
                case .healthKitPermissionsMissing(let permissions):
                    return true
                case .healthKitDataMissing(let competition, _):
                    return competition.id == self.competition.id
                case .notificationPermissionsDenied,
                    .notificationPermissionsMissing,
                    .backgroundRefreshDenied:
                    return true
                case .newCompetitionResults(let competition, _):
                    return competition.id == self.competition.id
                case .competitionResultsCalculating(let competition):
                    return competition.id == self.competition.id
                }
            }
            .assign(to: &$banners)
    }

    private func bindStandings() {
        $currentStandingsMaximum
            .handleEvents(
                withUnretained: self,
                receiveSubscription: { strongSelf, _ in strongSelf.loadingStandings = true }
            )
            .flatMapLatest(withUnretained: self) { strongSelf, limit -> AnyPublisher<[Competition.Standing], Never> in
                strongSelf.competitionsManager.standingsPublisher(for: strongSelf.competition.id, limit: limit)
                    .catchErrorJustReturn([])
                    .flatMapLatest { standings -> AnyPublisher<[Competition.Standing], Never> in
                        let userID = strongSelf.userManager.user.id
                        if standings.contains(where: { $0.id == userID }) {
                            return .just(standings)
                        } else {
                            return strongSelf.competitionsManager.standing(for: strongSelf.competition.id, userID: userID)
                                .map { $0 as Competition.Standing? }
                                .catchErrorJustReturn(nil)
                                .map { standing in
                                    guard let standing else { return standings }
                                    return standings.appending(standing)
                                }
                                .eraseToAnyPublisher()
                        }
                    }
                    .eraseToAnyPublisher()
            }
            .flatMapLatest { [searchManager] standings in
                searchManager.searchForUsers(withIDs: standings.map(\.id))
                    .map { (standings, $0 ) }
                    .catchErrorJustReturn(([], []))
            }
            .map { [userManager] (standings: [Competition.Standing], users: [User]) in
                let currentUser = userManager.user
                return standings
                    .sorted(by: \.rank)
                    .map { standing in
                        CompetitionParticipantRow.Config(
                            user: users.first { $0.id == standing.userId },
                            currentUser: currentUser,
                            standing: standing
                        )
                    }
            }
            .receive(on: scheduler)
            .handleEvents(
                withUnretained: self,
                receiveOutput: { strongSelf, _ in strongSelf.loadingStandings = false }
            )
            .assign(to: &$standings)

        $standings
            .map { [weak self] standings in standings.count < (self?.competition.participants.count ?? 0) }
            .assign(to: &$showShowMoreButton)
    }
}
