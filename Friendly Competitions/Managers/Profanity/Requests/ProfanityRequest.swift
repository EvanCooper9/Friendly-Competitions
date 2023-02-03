import ECNetworking
import Foundation

struct ProfanityRequest: Request {
    
    private struct ResponseBody: Decodable {
        let result: String
    }
    
    let query: String
    
    func buildRequest(with baseURL: URL) -> NetworkRequest {
        .init(
            method: .get,
            url: baseURL.appendingQueryParameters([
                "text": query
            ])
        )
    }
    
    func response(from data: Data, with decoder: JSONDecoder) throws -> String {
        try decoder.decode(ResponseBody.self, from: data).result
    }
}
