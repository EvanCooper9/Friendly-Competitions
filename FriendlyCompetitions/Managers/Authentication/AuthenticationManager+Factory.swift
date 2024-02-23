import Factory
import FCKit
import FirebaseAuth

extension Container {
    var authenticationCache: Factory<AuthenticationCache> {
        self { UserDefaults.standard }.scope(.shared)
    }

    var authenticationManager: Factory<AuthenticationManaging> {
        self { AuthenticationManager() }.scope(.shared)
    }

    var auth: Factory<AuthProviding> {
        self {
            let environment = self.environmentManager().environment
            let auth = Auth.auth()

            switch environment {
            case .prod:
                break
            case .debugLocal:
                auth.useEmulator(withHost: "localhost", port: 9099)
            case .debugRemote(let destination):
                auth.useEmulator(withHost: destination, port: 9099)
            }

            let currentUser = auth.currentUser
            do {
                try auth.useUserAccessGroup(AppGroup.id())
            } catch {
                print(error.localizedDescription)
                print((error as NSError).userInfo)
            }
            if let currentUser {
                auth.updateCurrentUser(currentUser) { error in
                    guard let error else { return }
                    print(error.localizedDescription)
                }
            }

            return auth
        }.scope(.shared)
    }

    var signInWithAppleProvider: Factory<SignInWithAppleProviding> {
        self { SignInWithAppleProvider() }
    }
}
