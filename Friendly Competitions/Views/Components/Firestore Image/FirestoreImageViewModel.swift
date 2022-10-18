import Combine
import CombineExt
import Factory

final class FirestoreImageViewModel: ObservableObject {
    
    @Published private(set) var failed = false
    @Published private(set) var imageData: Data?
    
    private let path: String
    
    @LazyInjected(Container.storage) private var storage
    
    init(path: String) {
        self.path = path
    }
    
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
