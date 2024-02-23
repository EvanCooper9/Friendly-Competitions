import ECNetworking
import Factory
import FCKit
import FirebaseAuth

extension Container {
    var network: Factory<Network> {
        self {
            let environment = self.environmentManager.resolve().environment
            let host: String = {
                switch environment {
                case .prod: return "firestore.googleapis.com"
                case .debugLocal: return "localhost:8080"
                case .debugRemote(let destination): return "\(destination):8080"
                }
            }()

            let ssl: Bool = {
                switch environment {
                case .prod: return true
                case .debugLocal, .debugRemote: return false
                }
            }()

            let configuration = NetworkConfiguration(
                baseURL: URL(string: "\(ssl ? "https" : "http")://\(host)/v1/projects/compyboi-79ae0/databases/(default)/documents")!,
                logging: true
            )

            let customDecoder = JSONDecoder()
            customDecoder.dateDecodingStrategy = .formatted(DateFormatter.dateDashed)
            let customEncoder = JSONEncoder()
            customEncoder.dateEncodingStrategy = .formatted(DateFormatter.dateDashed)

            let authenticationAction = AuthenticationAction()

            return URLSessionNetwork(
                actions: [authenticationAction],
                configuration: configuration,
                decoder: customDecoder,
                encoder: customEncoder
            )
        }.scope(.shared)
    }
}
