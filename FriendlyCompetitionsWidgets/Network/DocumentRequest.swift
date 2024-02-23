import ECNetworking
import Foundation

struct DocumentRequest<R: Decodable>: AuthenticatedRequest {
    typealias Response = R

    let path: String

    func response(from data: Data, with decoder: JSONDecoder) throws -> R {
        let document = try decoder.decode(FirestoreDocument.self, from: data)
        let pairs = document.fields.compactMap { key, value -> (String, Any)? in
            (key, value.convertValueForJson)
        }
        let dictionary = Dictionary<String, Any>(uniqueKeysWithValues: pairs)
        let jsonData = try JSONSerialization.data(withJSONObject: dictionary)
        return try R.decoded(from: jsonData, using: decoder)
    }

    func buildRequest(with baseURL: URL) -> NetworkRequest {
        .init(method: .get, url: baseURL.appendingPathComponent(path))
    }
}
