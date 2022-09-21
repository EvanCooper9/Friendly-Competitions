import Combine
import CombineExt
import ECKit

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

    private let _accept = PassthroughSubject<User, Never>()
    private let _invite = PassthroughSubject<User, Never>()
    private let _share = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()
    
    init(competitionsManager: CompetitionsManaging, friendsManager: FriendsManaging, userManager: UserManaging, action: InviteFriendsAction) {
        let alreadyInvited: AnyPublisher<[User.ID], Never>
        let incomingRequests: AnyPublisher<[User.ID], Never>

        switch action {
        case .addFriend:
            alreadyInvited = Publishers
                .CombineLatest(
                    friendsManager.friends.mapMany(\.id),
                    userManager.user.map(\.outgoingFriendRequests)
                )
                .map { $0 + $1 }
                .eraseToAnyPublisher()

            incomingRequests = userManager.user
                .map(\.incomingFriendRequests)
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

            incomingRequests = .just([])
        }

        $searchText
            .flatMapLatest { searchText -> AnyPublisher<[User], Never> in
                guard !searchText.isEmpty else { return .just([]) }
                return friendsManager.search(with: searchText).ignoreFailure()
            }
            .combineLatest(alreadyInvited, incomingRequests)
            .map { [weak self] users, alreadyInvited, incomingRequests -> [RowConfig] in
                users.map { friend in
                    let hasIncomingInvite = incomingRequests.contains(friend.id)
                    return RowConfig(
                        id: friend.id,
                        name: friend.name,
                        pillId: friend.hashId,
                        buttonTitle: hasIncomingInvite ? "Accept" : (alreadyInvited.contains(friend.id) ? "Invited" : "Invite"),
                        buttonDisabled: alreadyInvited.contains(friend.id),
                        buttonAction: { [weak self, friend] in
                            guard let self = self, let index = self.rows.firstIndex(where: { $0.id == friend.id }) else { return }
                            self.rows[index].buttonDisabled.toggle()
                            self.rows[index].buttonTitle = self.rows[index].buttonDisabled ? "Invited" : "Invite"
                            switch action {
                            case .addFriend:
                                if hasIncomingInvite {
                                    self._accept.send(friend)
                                } else {
                                    self._invite.send(friend)
                                }
                            case .competitionInvite:
                                self._invite.send(friend)
                            }
                        }
                    )
                }
            }
            .assign(to: &$rows)

        _accept
            .flatMapLatest { [weak self] user in
                switch action {
                case .addFriend:
                    return friendsManager
                        .accept(friendRequest: user)
                        .receive(on: RunLoop.main)
                        .isLoading { [weak self] in self?.loading = $0 }
                        .ignoreFailure()
                case .competitionInvite:
                    return .never()
                }
            }
            .sink()
            .store(in: &cancellables)

        _invite
            .flatMapLatest { [weak self] friend -> AnyPublisher<Void, Never> in
                switch action {
                case .addFriend:
                    return friendsManager
                        .add(user: friend)
                        .isLoading { [weak self] in self?.loading = $0 }
                        .ignoreFailure()
                case .competitionInvite(let competition):
                    return competitionsManager
                        .invite(friend, to: competition)
                        .isLoading { [weak self] in self?.loading = $0 }
                        .ignoreFailure()
                }
            }
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

    // MARK: - Publie Methods
    
    func sendInviteLink() {
        _share.send()
    }
}
