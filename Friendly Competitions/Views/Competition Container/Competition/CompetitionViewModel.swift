import Combine
import CombineExt
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

    @Injected(\.activitySummaryManager) private var activitySummaryManager
    @Injected(\.api) private var api
    @Injected(\.appState) private var appState
    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.healthKitManager) private var healthKitManager
    @Injected(\.notificationsManager) private var notificationManager
    @Injected(\.scheduler) private var scheduler
    @Injected(\.searchManager) private var searchManager
    @Injected(\.stepCountManager) private var stepCountManager
    @Injected(\.userManager) private var userManager
    @Injected(\.workoutManager) private var workoutManager

    private let confirmActionSubject = PassthroughSubject<Void, Error>()
    private let performActionSubject = PassthroughSubject<CompetitionViewAction, Error>()
    private let fetchParticipantsSubject = PassthroughSubject<[String], Never>()
    private let didRequestPermissions = CurrentValueSubject<Void, Never>(())
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init(competition: Competition) {
        self.competition = competition

        checkForPermissions()
        bindParticipants()

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

    // MARK: - Private Methods

    private func bindParticipants() {
        let participants = fetchParticipantsSubject
            .prepend(competition.participants)
            .flatMapLatest(withUnretained: self) { strongSelf, participants in
                strongSelf.searchManager
                    .searchForUsers(withIDs: participants)
                    .catchErrorJustReturn([])
            }

        let allStandings = competitionsManager
            .standingsPublisher(for: competition.id)
            .catchErrorJustReturn([])

        Publishers.CombineLatest(allStandings, $standings)
            .map { $0.count > $1.count }
            .assign(to: &$showShowMoreButton)

        Publishers
            .CombineLatest(allStandings, participants)
            .handleEvents(
                withUnretained: self,
                receiveSubscription: { strongSelf, _ in strongSelf.loadingStandings = true }
            )
            .combineLatest($currentStandingsMaximum)
            .map { [weak self] standingsAndParticipants, limit in
                guard let self else { return [] }
                let (standings, participants) = standingsAndParticipants
                let currentUser = self.userManager.user
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
    }

    private func checkForPermissions() {
        Publishers
            .CombineLatest3(appState.didBecomeActive, $competition, didRequestPermissions)
            .flatMapLatest { result in
                let (_, competition, _) = result
                return competition.banners
            }
            .delay(for: .seconds(1), scheduler: scheduler)
            .assign(to: &$banners)
    }

    func tapped(banner: Banner) {
        switch banner {
        case .healthKitPermissionsMissing:
            let requiredHealthPermissions = competition.scoringModel
                .requiredPermissions
                .compactMap { permission in
                    switch permission {
                    case .health(let healthKitPermissionType):
                        return healthKitPermissionType
                    case .notifications:
                        return nil
                    }
                }

            healthKitManager.request(requiredHealthPermissions)
                .catchErrorJustReturn(())
                .receive(on: scheduler)
                .sink(withUnretained: self) { strongSelf in
                    strongSelf.banners.remove(banner)
                    strongSelf.didRequestPermissions.send()
                }
                .store(in: &cancellables)
        case .healthKitDataMissing:
            UIApplication.shared.open(.health)
        case .notificationPermissionsMissing:
            notificationManager.requestPermissions()
                .mapToVoid()
                .catchErrorJustReturn(())
                .receive(on: scheduler)
                .sink(withUnretained: self) { strongSelf in
                    strongSelf.banners.remove(banner)
                    strongSelf.didRequestPermissions.send()
                }
                .store(in: &cancellables)
        case .notificationPermissionsDenied:
            UIApplication.shared.open(.notificationSettings)
        }
    }
}
