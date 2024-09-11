import ECKit
import Factory

final class StorageAppService: AppService {

    // MARK: - AppService

    func didFinishLaunching() {
        Task { [storageManager] in
            storageManager.clear(ttl: 60.days)
        }
    }

    // MARK: - Private

    @LazyInjected(\.storageManager) private var storageManager: StorageManaging
}
