import Combine
import CombineExt

final class InviteFriendsViewModel: ObservableObject {
    
    struct RowConfig: Identifiable {
        let id: String
        let name: String
        let pillId: String
        var buttonTitle: String
        var buttonDisabled: Bool
        let buttonAction: () -> Void
    }

    @Published var loading = false
    @Published var footerText: String?
    @Published var rows = [RowConfig]()
    @Published var searchText = ""

    private var _invite = PassthroughSubject<User, Never>()
    private var _share = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()
    
    init(competitionsManager: CompetitionsManaging, friendsManager: FriendsManaging, userManager: UserManaging, action: InviteFriendsAction) {
        let alreadyInvited: AnyPublisher<[User.ID], Never>

        switch action {
        case .addFriend:
            alreadyInvited = friendsManager.friends
                .mapMany(\.id)
                .eraseToAnyPublisher()
        case .competitionInvite(let competition):
            alreadyInvited = Publishers
                .CombineLatest(competitionsManager.participants, competitionsManager.pendingParticipants)
                .map { participants, pendingParticipants in
                    let participants = participants[competition.id] ?? []
                    let pendingParticipants = pendingParticipants[competition.id] ?? []
                    return (participants + pendingParticipants).map(\.id)
                }
                .eraseToAnyPublisher()
        }
        
        $searchText
            .setFailureType(to: Error.self)
            .flatMapLatest(friendsManager.search(with:))
            .ignoreFailure()
            .prepend(friendsManager.friends)
            .combineLatest(alreadyInvited)
            .map { users, alreadyInvited -> [RowConfig] in
                users.map { friend in
                    RowConfig(
                        id: friend.id,
                        name: friend.name,
                        pillId: friend.hashId,
                        buttonTitle: alreadyInvited.contains(friend.id) ? "Invited" : "Invite",
                        buttonDisabled: alreadyInvited.contains(friend.id),
                        buttonAction: { [weak self, friend] in
                            guard let self = self, let index = self.rows.firstIndex(where: { $0.id == friend.id }) else { return }
                            self.rows[index].buttonDisabled.toggle()
                            self.rows[index].buttonTitle = self.rows[index].buttonDisabled ? "Invited" : "Invite"
                            self._invite.send(friend)
                        }
                    )
                }
            }
            .assign(to: &$rows)

        _invite
            .handleEvents(withUnretained: self, receiveOutput: { owner, _ in owner.loading = true })
            .flatMapLatest { friend -> AnyPublisher<Void, Never> in
                switch action {
                case .addFriend:
                    return friendsManager
                        .add(friend: friend)
                        .ignoreFailure()
                case .competitionInvite(let competition):
                    return competitionsManager
                        .invite(friend, to: competition)
                        .ignoreFailure()
                }
            }
            .handleEvents(withUnretained: self, receiveOutput: { $0.loading = false })
            .sink()
            .store(in: &cancellables)

        _share
            .receive(on: RunLoop.main)
            .sink {
                let deepLink: DeepLink?
                switch action {
                case .addFriend:
                    deepLink = .friendReferral(id: userManager.user.value.id)
                case .competitionInvite(let competition):
                    deepLink = .competitionInvite(id: competition.id)
                }
                deepLink?.share()
            }
            .store(in: &cancellables)
    }
    
    func sendInviteLink() {
        _share.send()
    }
}
