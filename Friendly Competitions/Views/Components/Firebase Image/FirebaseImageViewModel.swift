import Combine
import CombineExt
import Factory

final class FirebaseImageViewModel: ObservableObject {
    
    // MARK: - Private Properties
    
    @Published private(set) var failed = false
    @Published private(set) var imageData: Data?
    
    // MARK: - Private Properties
    
    private let path: String
    
    @LazyInjected(Container.storage) private var storage
    
    // MARK: - Lifecycle
    
    init(path: String) {
        self.path = path
    }
    
    // MARK: - Public Properties
    
    func downloadImage() {
        failed = false
        Task { [weak self] in
            guard let strongSelf = self else { return }
            do {
                let data = try await strongSelf.storage.child(path).data(maxSize: .max)
                DispatchQueue.main.async {
                    strongSelf.imageData = data
                }
            } catch {
                DispatchQueue.main.async {
                    strongSelf.failed = true
                }
            }
        }
    }
}
