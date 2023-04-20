import Combine
import CombineExt
import FirebaseFunctions
import FirebaseFunctionsCombineSwift

extension Functions: API {
    func call(_ endpoint: Endpoint, with data: [String : Any]?) -> AnyPublisher<Void, Error> {
        httpsCallable(endpoint.name)
            .call(data)
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}
