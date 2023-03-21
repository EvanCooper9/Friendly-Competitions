import Combine
import CombineExt
import FirebaseFunctions
import FirebaseFunctionsCombineSwift

extension Functions: API {
    func call(_ endpoint: String, with data: [String : Any]?) -> AnyPublisher<Void, Error> {
        httpsCallable(endpoint)
            .call(data)
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}
