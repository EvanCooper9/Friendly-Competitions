import Combine
import Factory
import Files
import Foundation

// sourcery: AutoMockable
protocol StorageManaging {
    func data(for storagePath: String) -> AnyPublisher<Data, Error>
}

final class StorageManager: StorageManaging {

    // MARK: - Private Properties

    @Injected(\.storage) private var storage

    // MARK: - Lifecycle

    init() {
        try? cleanup()
    }

    // MARK: - Public Methods
    
    func data(for storagePath: String) -> AnyPublisher<Data, Error> {        
        guard let documents = Folder.documents?.url else {
            return storage.data(path: storagePath)
        }
        
        let localPath = documents.appendingPathComponent(storagePath)
        let localData = try? Data(contentsOf: localPath)
        if let localData, !localData.isEmpty {
            return .just(localData)
        }
        
        return storage.data(path: storagePath)
            .handleEvents(receiveOutput: { _ = try? Folder.documents?.createFileIfNeeded(at: storagePath, contents: $0) })
            .eraseToAnyPublisher()
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
