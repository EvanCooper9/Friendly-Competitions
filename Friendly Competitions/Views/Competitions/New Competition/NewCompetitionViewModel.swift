import Combine
import CombineExt
import Resolver

final class NewCompetitionViewModel: ObservableObject {

    private enum Constants {
        static let defaultInterval: TimeInterval = 7
    }
    
    struct InviteFriendsRow: Identifiable {
        let id: String
        let name: String
        var invited: Bool
        let onTap: () -> Void
    }

    // MARK: - Public Properties
    
    @Published var competition: Competition
    @Published var constrainToWorkout = false
    @Published var friendRows = [InviteFriendsRow]()
    
    var createDisabled: Bool { disabledReason != nil }
    var disabledReason: String? {
        if competition.name.isEmpty {
            return "Please enter a name"
        } else if !competition.isPublic && competition.pendingParticipants.isEmpty {
            return "Please invite at least 1 friend"
        }
        return nil
    }

    // MARK: - Private Properties
    
    @Injected private var competitionsManager: CompetitionsManaging
    @Injected private var friendsManager: FriendsManaging
    @Injected private var userManager: UserManaging

    private let _create = PassthroughSubject<Void, Never>()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle
        
    init() {
        competition = .init(
            name: "",
            owner: "",
            participants: [],
            pendingParticipants: [],
            scoringModel: .percentOfGoals,
            start: .now.advanced(by: 1.days),
            end: .now.advanced(by: Constants.defaultInterval.days + 1.days),
            repeats: false,
            isPublic: false,
            banner: nil
        )

        Publishers
            .CombineLatest(friendsManager.friends, $competition)
            .map { friends, competition in
                friends.map { friend in
                    InviteFriendsRow(
                        id: friend.id,
                        name: friend.name,
                        invited: competition.pendingParticipants.contains(friend.id),
                        onTap: {
                            self.competition.pendingParticipants.toggle(friend.id)
                        }
                    )
                }
            }
            .assign(to: &$friendRows)

        _create
            .withLatestFrom(userManager.user)
            .setFailureType(to: Error.self)
            .flatMapLatest(withUnretained: self) { object, user -> AnyPublisher<Void, Error> in
                var competition = object.competition
                if object.constrainToWorkout {
                    competition.scoringModel = nil
                } else {
                    competition.workoutType = nil
                }
                competition.owner = user.id
                competition.participants = [user.id]
                object.competition = competition
                return object.competitionsManager.create(competition)
            }
            .sink()
            .store(in: &cancellables)
    }

    // MARK: - Public Properties
    
    func create() {
        _create.send()
    }
}
