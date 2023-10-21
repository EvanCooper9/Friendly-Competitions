import Combine
import CombineExt
import Factory
import FirebaseFunctions
import FirebaseFunctionsCombineSwift

extension Functions: API {
    func call(_ endpoint: Endpoint) -> AnyPublisher<Void, Error> {
        httpsCallable(endpoint.name)
            .call(endpoint.data)
            .mapToVoid()
            .reportErrorToCrashlytics(userInfo: [
                "apiEndpoint": endpoint.name,
                "apiData": endpoint.data ?? "empty"
            ])
            .eraseToAnyPublisher()
    }
}
