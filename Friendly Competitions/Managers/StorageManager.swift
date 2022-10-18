import Combine
import Factory
import Files
import FirebaseStorage
import Foundation

// sourcery: AutoMockable
protocol StorageManaging {
    func data(for storagePath: String) async throws -> Data
}

final class StorageManager: StorageManaging {

    // MARK: - Private Properties

    @Injected(Container.storage) private var storage

    // MARK: - Lifecycle

    init() {
        try? cleanup()
    }

    // MARK: - Public Methods

    func data(for storagePath: String) async throws -> Data {
        guard let documents = Folder.documents?.url else {
            return try await storage.child(storagePath).data(maxSize: .max)
        }

        let localPath = documents.appendingPathComponent(storagePath)
        let localData = try? Data(contentsOf: localPath)
        if let localData, !localData.isEmpty {
            return localData
        }

        return try await withCheckedThrowingContinuation { continuation in
            storage.child(storagePath).write(toFile: localPath) { url, error in
                if let error {
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

    // MARK: - Private Methods

    private func cleanup() throws {
        guard let documents = Folder.documents else { return }
        try documents.files.forEach { file in
            try file.delete()
        }
        try documents.subfolders.forEach { folder in
            try folder.delete()
        }
    }
}
