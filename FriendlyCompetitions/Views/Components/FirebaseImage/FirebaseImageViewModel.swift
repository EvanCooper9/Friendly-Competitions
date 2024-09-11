import Combine
import CombineExt
import CombineSchedulers
import Factory
import Foundation

final class FirebaseImageViewModel: ObservableObject {

    // MARK: - Private Properties

    @Published private(set) var failed = false
    @Published private(set) var imageData: Data?

    // MARK: - Private Properties

    private let path: String

    @Injected(\.scheduler) private var scheduler: AnySchedulerOf<RunLoop>
    @Injected(\.storageManager) private var storageManager: StorageManaging

    // MARK: - Lifecycle

    init(path: String) {
        self.path = path
        downloadImage()
    }

    // MARK: - Private Methods

    private func downloadImage() {
        storageManager.get(path)
            .asOptional()
            .retry(3)
            .catch { [weak self] _ -> AnyPublisher<Data?, Never> in
                self?.failed = true
                return .just(nil)
            }
            .receive(on: RunLoop.main)
            .assign(to: &$imageData)
    }
}
