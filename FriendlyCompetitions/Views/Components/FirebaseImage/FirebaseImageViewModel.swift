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

    private let downloadImageSubject = PassthroughSubject<Void, Error>()

    // MARK: - Lifecycle

    init(path: String) {
        self.path = path

        downloadImageSubject
            .handleEvents(withUnretained: self, receiveOutput: { $0.failed = false })
            .flatMapLatest(withUnretained: self) { $0.storageManager.data(for: path) }
            .map { $0 as Data? }
            .receive(on: scheduler)
            .catch { [weak self] _ -> AnyPublisher<Data?, Never> in
                self?.failed = true
                return .just(nil)
            }
            .assign(to: &$imageData)

        downloadImage()
    }

    // MARK: - Public Properties

    func downloadImage() {
        downloadImageSubject.send()
    }
}
