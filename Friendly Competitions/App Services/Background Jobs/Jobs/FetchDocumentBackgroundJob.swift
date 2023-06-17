import Combine
import CombineExt
import Factory
import Foundation

final class FetchDocumentBackgroundJob: BackgroundJob {

    private enum CodingKeys: String, CodingKey {
        case documentPath
    }

    private let documentPath: String

    @LazyInjected(\.database) private var database

    func execute() -> AnyPublisher<Void, Never> {
        database
            .document(documentPath)
            .cacheFromServer()
            .ignoreFailure()
    }
}
