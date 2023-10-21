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
            .handleEvents(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    error.reportToCrashlytics(userInfo: [
                        "apiEndpoint": endpoint.name,
                        "apiData": endpoint.data
                    ])
                }
            })
            .eraseToAnyPublisher()
    }
}
