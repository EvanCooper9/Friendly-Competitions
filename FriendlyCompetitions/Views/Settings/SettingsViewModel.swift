import Combine
import CombineExt
import ECKit
import Factory
import FCKit
import Foundation

final class SettingsViewModel: ObservableObject {

    @Published var profilePictureImageData: Data? {
        didSet { uploadProfilePicture(data: profilePictureImageData) }
    }

    @Published var user: User!
    @Published var confirmationRequired = false
    @Published var loading = false
    @Published var showHideNameLearnMore = false
    @Published var showNewIssueReportingForm = false

    @Published var showCreateAccount = false
    @Published var isAnonymousAccount = false

    // MARK: - Private Properties

    @Injected(\.authenticationManager) private var authenticationManager: AuthenticationManaging
    @Injected(\.database) private var database: Database
    @Injected(\.featureFlagManager) private var featureFlagManager: FeatureFlagManaging
    @Injected(\.storageManager) private var storageManager: StorageManaging
    @Injected(\.userManager) private var userManager: UserManaging

    private let deleteAccountSubject = PassthroughSubject<Void, Never>()
    private let signOutSubject = PassthroughSubject<Void, Never>()
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        $user
            .unwrap()
            .removeDuplicates()
            .dropFirst()
            .flatMapLatest(withUnretained: self) { strongSelf, user in
                strongSelf.userManager
                    .update(with: user)
                    .ignoreFailure()
            }
            .sink()
            .store(in: &cancellables)

        $user
            .unwrap()
            .map { $0.isAnonymous == true }
            .assign(to: &$isAnonymousAccount)

        userManager.userPublisher
            .removeDuplicates()
            .map(User?.init)
            .assign(to: &$user)

        deleteAccountSubject
            .flatMapLatest(withUnretained: self) { strongSelf in
                strongSelf.authenticationManager
                    .shouldReauthenticate()
                    .flatMapLatest { shouldReauthenticate -> AnyPublisher<Void, Error> in
                        guard shouldReauthenticate else { return .just(()) }
                        return strongSelf.authenticationManager.reauthenticate()
                    }
                    .flatMapLatest { strongSelf.authenticationManager.deleteAccount() }
                    .isLoading { strongSelf.loading = $0 }
                    .ignoreFailure()
            }
            .sink()
            .store(in: &cancellables)

        showNewIssueReportingForm = featureFlagManager.value(forBool: .newResultsBannerEnabled)

        getProfilePictureData()
    }

    // MARK: - Public Methods

    func confirmTapped() {
        deleteAccountSubject.send()
    }

    func deleteAccountTapped() {
        confirmationRequired.toggle()
    }

    func shareInviteLinkTapped() {
        DeepLink.user(id: userManager.user.id).share()
    }

    func signUpTapped() {
        showCreateAccount.toggle()
    }

    func signOutTapped() {
        try? authenticationManager.signOut()
    }

    func hideNameLearnMoreTapped() {
        showHideNameLearnMore.toggle()
    }

    // MARK: - Private

    private func getProfilePictureData() {
        userManager.userPublisher
            .map(\.profilePicturePath)
            .removeDuplicates()
            .flatMapLatest { [storageManager] path -> AnyPublisher<Data?, Never> in
                guard let path else { return .just(nil) }
                return storageManager.get(path)
                    .asOptional()
                    .ignoreFailure()
                    .eraseToAnyPublisher()
            }
            .receive(on: RunLoop.main)
            .assign(to: &$profilePictureImageData)
    }

    private func uploadProfilePicture(data: Data?) {
        let path = "users/\(userManager.user.id)/profilePicture.jpg"
        return storageManager.set(path, data: data)
            .flatMapLatest { [database, userManager] in
                return database.document("users/\(userManager.user.id)")
                    .update(fields: ["profilePicturePath": data == nil ? nil : path as Any])
            }
            .sink()
            .store(in: &cancellables)
    }
}
