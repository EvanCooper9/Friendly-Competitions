import Combine
import ECKit
import Factory
import FirebaseStorage
import FirebaseStorageCombineSwift
import Foundation

// sourcery: AutoMockable
protocol StorageManaging {
    func get(_ path: String) -> AnyPublisher<Data, Error>
    func set(_ path: String, data: Data?) -> AnyPublisher<Void, Error>
    func clear(ttl: TimeInterval)
}

extension StorageManaging {
    func clear(ttl: TimeInterval = 0) {
        clear(ttl: ttl)
    }
}

final class StorageManager: StorageManaging {

    enum StorageManagerError: Error {
        case unknown
        case fileNotFound
    }

    private struct FileMetadata: Codable {
        let accessed: Date
        let updated: Date
    }

    // MARK: - Private Properties

    private let fileManager = FileManager.default
    private let storage = Storage.storage()

    @UserDefault("file-metadata", defaultValue: [:]) private var fileMetadata: [String: FileMetadata]

    init() {
        let environment = Container.shared.environmentManager.resolve().environment
        switch environment {
        case .prod:
            break
        case .debugLocal:
            storage.useEmulator(withHost: "localhost", port: 9199)
        case .debugRemote(let destination):
            storage.useEmulator(withHost: destination, port: 9199)
        }
    }

    // MARK: - Public Methods

    func get(_ path: String) -> AnyPublisher<Data, any Error> {
        let url = URL.cachesDirectory.appending(path: path)
        let cachedData = fileManager.contents(atPath: url.path(percentEncoded: false))

        return .fromAsync { [weak self, fileManager, storage] in
            guard let self else { throw StorageManagerError.unknown }

            let reference = storage.reference(withPath: path)
            let serverMetadata = try await reference.getMetadata()
            let serverMetadataDate = serverMetadata.updated ?? serverMetadata.timeCreated ?? .now
            defer { fileMetadata[path] = FileMetadata(accessed: .now, updated: serverMetadataDate) }
            let url = URL.cachesDirectory.appending(path: path)

            if let fileMetadata = fileMetadata[path],
               serverMetadataDate <= fileMetadata.updated,
               fileManager.fileExists(atPath: url.path(percentEncoded: false)),
               let contents = fileManager.contents(atPath: url.path(percentEncoded: false)) {
                return contents
            } else {
                let url = try await reference.writeAsync(toFile: url)
                guard let contents = fileManager.contents(atPath: url.path(percentEncoded: false)) else {
                    throw StorageManagerError.fileNotFound
                }
                return contents
            }
        }
        .prepend([cachedData].compacted())
        .eraseToAnyPublisher()
    }

    func set(_ path: String, data: Data?) -> AnyPublisher<Void, any Error> {
        Future { [fileManager, storage] promise in
            let reference = storage.reference(withPath: path)
            if let data {
                reference.putData(data, metadata: nil) { result in
                    switch result {
                    case .success(let success):
                        let url = URL.cachesDirectory.appending(path: path)
                        fileManager.createFile(atPath: url.path, contents: data)
                        promise(.success(()))
                    case .failure(let error):
                        promise(.failure(error))
                    }
                }
            } else {
                reference.delete { error in
                    if let error {
                        promise(.failure(error))
                    } else {
                        let url = URL.cachesDirectory.appending(path: path)
                        try? fileManager.removeItem(at: url)
                        promise(.success(()))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func clear(ttl: TimeInterval) {
        let paths = fileMetadata
            .filter { _, metadata in metadata.accessed.addingTimeInterval(ttl) < .now }
            .keys

        paths.forEach { path in
            fileMetadata.removeValue(forKey: path)
            let url = URL.cachesDirectory.appending(path: path)
            try? fileManager.removeItem(at: url)
        }
    }
}

private extension Int64 {
    var bytes: Int64 { self }
    var kb: Int64 { bytes * 1024 }
    var mb: Int64 { kb * 1024 }
}
