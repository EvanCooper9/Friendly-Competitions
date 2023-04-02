import AuthenticationServices
import Combine

// sourcery: AutoMockable
protocol AuthProviding {
    var user: AuthUser? { get }
    func userPublisher() -> AnyPublisher<AuthUser?, Never>
    func signIn(withEmail email: String, password: String) -> AnyPublisher<Void, Error>
    func signIn(with credential: AuthCredential) -> AnyPublisher<AuthUser, Error>
    func signUp(withEmail email: String, password: String) -> AnyPublisher<AuthUser, Error>
    func signOut() throws
    func sendPasswordReset(withEmail email: String) -> AnyPublisher<Void, Error>
}

// sourcery: AutoMockable
protocol AuthUser {
    var id: String { get }
    var displayName: String? { get }
    var email: String? { get }
    var isEmailVerified: Bool { get }
    func sendEmailVerification() -> AnyPublisher<Void, Error>
    func set(displayName: String) -> AnyPublisher<AuthUser, Error>
    func reload() async throws
    func delete() async throws
}

enum AuthCredential {
    case apple(id: String, nonce: String?, fullName: PersonNameComponents?)
}
