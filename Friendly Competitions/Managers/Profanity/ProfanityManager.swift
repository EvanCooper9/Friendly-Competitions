import Combine
import ECNetworking
import Foundation

// sourcery: AutoMockable
protocol ProfanityManaging {
    func filter(_ input: String) -> AnyPublisher<String, Error>
}

final class ProfanityManager: ProfanityManaging {
    
    private let network: Network
    
    init() {
        let configuration = NetworkConfiguration(
            baseURL: URL(string: "https://www.purgomalum.com/service/json")!,
            logging: true
        )
        network = URLSessionNetwork(configuration: configuration)
    }
    
    func filter(_ input: String) -> AnyPublisher<String, Error> {
        network
            .send(ProfanityRequest(query: input))
            .eraseToAnyPublisher()
    }
}
