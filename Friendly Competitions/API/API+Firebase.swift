import Combine
import CombineExt
import FirebaseFunctions
import FirebaseFunctionsCombineSwift

extension Functions: API {
    func call(_ endpoint: Endpoint) -> AnyPublisher<Void, Error> {
        httpsCallable(endpoint.name)
            .call(endpoint.data)
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}
