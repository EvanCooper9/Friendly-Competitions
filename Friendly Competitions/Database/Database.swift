import Combine

// MARK: Database

// sourcery: AutoMockable
protocol Database {
    func batch() -> Batch
    func collection(_ collectionPath: String) -> Collection
    func collectionGroup(_ collectionGroupID: String) -> Collection
    func document(_ documentPath: String) -> Document
}

// MARK: Collection

protocol Collection {
    func whereField<T: Decodable>(_ field: String, asArrayOf type: T.Type, in values: [Any]) -> AnyPublisher<[T], Error>
    func whereField(_ field: String, arrayContains value: Any) -> Collection
    func whereField(_ field: String, isEqualTo value: Any) -> Collection
    func publisher<T: Decodable>(asArrayOf type: T.Type) -> AnyPublisher<[T], Error>
    func getDocuments<T: Decodable>(ofType type: T.Type, source: DatabaseSource) -> AnyPublisher<[T], Error>
}

extension Collection {
    func getDocuments<T: Decodable>(ofType type: T.Type, source: DatabaseSource = .server) -> AnyPublisher<[T], Error> {
        getDocuments(ofType: T.self, source: source)
    }
}

// MARK: Document

protocol Document {

    var exists: AnyPublisher<Bool, Error> { get }

    func setData<T: Encodable>(from value: T) -> AnyPublisher<Void, Error>
    func updateData(from data: [String: Any]) -> AnyPublisher<Void, Error>
    func getDocument<T: Decodable>(as type: T.Type, source: DatabaseSource) -> AnyPublisher<T, Error>
    func getDocumentPublisher<T: Decodable>(as type: T.Type) -> AnyPublisher<T, Error>
}

extension Document {
    func getDocument<T: Decodable>(as type: T.Type, source: DatabaseSource = .server) -> AnyPublisher<T, Error> {
        getDocument(as: T.self, source: source)
    }
}

// MARK: Batch

protocol Batch {
    func commit() async throws
    func setData<T: Encodable>(from value: T, forDocument document: Document) throws
}

// MARK: Source

enum DatabaseSource {
    /// Fetch data only from cache
    case cache

    /// Fetch data from cache, fallback to server if it doesn't exist
    case cacheFirst

    /// Fetch data directly from server
    case server
}
