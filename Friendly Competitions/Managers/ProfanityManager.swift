import Combine
import Foundation

class AnyProfanityManager: ObservableObject {
    func checkProfanity(_ input: String) async throws { }
}

final class ProfanityManager: AnyProfanityManager {

    enum Error: LocalizedError {
        case invalidURL
        case containsProfanity

        var errorDescription: String? { localizedDescription }

        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case .containsProfanity:
                return "Contains profanity"
            }
        }
    }

    private struct Response: Decodable {
        let result: String
    }

    private enum Constants {
        static let profanityURL = "https://www.purgomalum.com/service/json"
    }

    private let session = URLSession.shared

    override func checkProfanity(_ input: String) async throws {
        guard var urlComponents = URLComponents(string: Constants.profanityURL) else { throw Error.invalidURL }
        urlComponents.queryItems?.append(.init(name: "text", value: input))
        guard let url = urlComponents.url else { throw Error.invalidURL }
        let request = URLRequest(url: url)
        let (data, _) = try await session.data(for: request)
        let containsProfanity = try Response.decoded(from: data).result == input
        if containsProfanity {
            throw Error.containsProfanity
        }
    }
}
