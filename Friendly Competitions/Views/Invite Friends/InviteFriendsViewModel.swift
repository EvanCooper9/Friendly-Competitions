import Combine
import CombineExt
import ECKit
import Factory

final class InviteFriendsViewModel: ObservableObject {
    
    struct RowConfig: Identifiable {
        let id: String
        let name: String
        let pillId: String
        var buttonTitle: String
        var buttonDisabled: Bool
        let buttonAction: () -> Void
    }
    
    // MARK: - Public Properties

    @Published var loading = false
    @Published var footerText: String?
    @Published var rows = [RowConfig]()
    @Published var searchText = ""
    
    // MARK: - Private Properties
    
    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.friendsManager) private var friendsManager
    @Injected(Container.userManager) private var userManager

    private let acceptSubject = PassthroughSubject<User, Never>()
    private let inviteSubject = PassthroughSubject<User, Never>()
    private let shareSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle
    
    init(action: InviteFriendsAction) {
        let alreadyInvited: AnyPublisher<[User.ID], Never>
        let incomingRequests: AnyPublisher<[User.ID], Never>

        switch action {
        case .addFriend:
            alreadyInvited = userManager.userPublisher
                .map { $0.friends + $0.outgoingFriendRequests }
                .eraseToAnyPublisher()
            incomingRequests = userManager.userPublisher
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
                .share(replay: 1)
                .eraseToAnyPublisher()

            incomingRequests = .just([])
        }

        $searchText
            .flatMapLatest(withUnretained: self) { strongSelf, searchText -> AnyPublisher<[User], Never> in
                guard !searchText.isEmpty else { return .just([]) }
                return strongSelf.friendsManager.search(with: searchText).ignoreFailure()
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
                                    self.acceptSubject.send(friend)
                                } else {
                                    self.inviteSubject.send(friend)
                                }
                            case .competitionInvite:
                                self.inviteSubject.send(friend)
                            }
                        }
                    )
                }
            }
            .assign(to: &$rows)

        acceptSubject
            .flatMapLatest(withUnretained: self) { strongSelf, user -> AnyPublisher<Void, Never> in
                switch action {
                case .addFriend:
                    return strongSelf.friendsManager
                        .accept(friendRequest: user)
                        .isLoading { strongSelf.loading = $0 }
                        .ignoreFailure()
                case .competitionInvite:
                    return .never()
                }
            }
            .sink()
            .store(in: &cancellables)

        inviteSubject
            .flatMapLatest(withUnretained: self) { strongSelf, friend -> AnyPublisher<Void, Never> in
                switch action {
                case .addFriend:
                    return strongSelf.friendsManager
                        .add(user: friend)
                        .isLoading { strongSelf.loading = $0 }
                        .ignoreFailure()
                case .competitionInvite(let competition):
                    return strongSelf.competitionsManager
                        .invite(friend, to: competition)
                        .isLoading { strongSelf.loading = $0 }
                        .ignoreFailure()
                }
            }
            .sink()
            .store(in: &cancellables)

        shareSubject
            .sink(withUnretained: self) { strongSelf in
                let deepLink: DeepLink?
                switch action {
                case .addFriend:
                    deepLink = .user(id: strongSelf.userManager.user.id)
                case .competitionInvite(let competition):
                    deepLink = .competition(id: competition.id)
                }
                deepLink?.share()
            }
            .store(in: &cancellables)
    }

    // MARK: - Publie Methods
    
    func sendInviteLink() {
        shareSubject.send()
    }
}
