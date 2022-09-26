import Combine
import CombineExt
import Resolver

final class FirestoreImageViewModel: ObservableObject {
    
    @Published private(set) var failed = false
    @Published private(set) var imageData: Data?
    
    private let path: String
    
    @LazyInjected private var storageManager: StorageManaging
    
    init(path: String) {
        self.path = path
    }
    
    func downloadImage() {
        failed = false
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let data = try await self.storageManager.data(for: self.path)
                DispatchQueue.main.async {
                    self.imageData = data
                }
            } catch {
                DispatchQueue.main.async {
                    self.failed = true
                }
            }
        }
    }
}
