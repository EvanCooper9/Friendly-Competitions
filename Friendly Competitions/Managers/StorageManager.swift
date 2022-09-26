import Combine
import Files
import FirebaseStorage
import Foundation
import Resolver

// sourcery: AutoMockable
protocol StorageManaging {
    func data(for storagePath: String) async throws -> Data
}

final class StorageManager: StorageManaging {

    // MARK: - Private Properties

    @Injected private var storageRef: StorageReference
    private let fileManager = FileManager.default

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Lifecycle

    init() {
        try? cleanup()
    }

    // MARK: - Public Methods

    func data(for storagePath: String) async throws -> Data {
        let localPath = documentsDirectory.appendingPathComponent(storagePath)
        let localData = try? Data(contentsOf: localPath)
        if let localData, !localData.isEmpty {
            return localData
        }

        return try await withCheckedThrowingContinuation { continuation in
            storageRef.child(storagePath).write(toFile: localPath) { url, error in
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
        let folder = try Folder(path: documentsDirectory.absoluteString)
        try folder.files.forEach { file in
            try file.delete()
        }
        try folder.subfolders.forEach { folder in
            try folder.delete()
        }
    }
}
