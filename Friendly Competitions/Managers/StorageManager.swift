import Combine
import FirebaseStorage
import Foundation
import Resolver

// sourcery: AutoMockable
protocol StorageManaging {
    func data(for storagePath: String) async throws -> Data
}

final class StorageManager: StorageManaging {
    
    // MARK: - Lifecycle
    
    deinit {
        // remove storage
    }

    // MARK: - Private Properties

    @Injected private var storageRef: StorageReference
    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    // MARK: - Public Methods

    func data(for storagePath: String) async throws -> Data {
        let localPath = documentsDirectory.appendingPathComponent(storagePath)
        let localData = try? Data(contentsOf: localPath)
        if let localData = localData, !localData.isEmpty {
            return localData
        }

        return try await withCheckedThrowingContinuation { continuation in
            storageRef.child(storagePath).write(toFile: localPath) { url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                do {
                    continuation.resume(returning: try Data(contentsOf: url!))
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
