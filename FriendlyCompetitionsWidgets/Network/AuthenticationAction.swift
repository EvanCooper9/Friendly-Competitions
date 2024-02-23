import ECNetworking
import Factory
import FCKit
import FirebaseAuth

struct AuthenticationAction: RequestWillBeginAction {

    @Injected(\.environmentManager) private var environmentManager: EnvironmentManaging

    func requestWillBegin(_ request: NetworkRequest, completion: @escaping RequestCompletion) {
        guard request.requiresAuthentication && !environmentManager.environment.isDebug else {
            completion(.success(request))
            return
        }
        Auth.auth().currentUser?.getIDTokenForcingRefresh(true) { idToken, error in
            if let error {
                completion(.failure(error))
            } else if let idToken {
                var request = request
                request.headers["Authorization"] = "Bearer \(idToken)"
                completion(.success(request))
            }
        }
    }
}

protocol AuthenticatedRequest: Request {
    var requiresAuthentication: Bool { get }
}

extension AuthenticatedRequest {
    var requiresAuthentication: Bool { true }
    var customProperties: [AnyHashable : Any] {
        ["requiresAuthentication": requiresAuthentication]
    }
}

extension NetworkRequest {
    var requiresAuthentication: Bool {
        customProperties["requiresAuthentication"] as? Bool ?? false
    }
}
