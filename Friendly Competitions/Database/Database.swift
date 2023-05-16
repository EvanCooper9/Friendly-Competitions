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
    func whereField<T: Decodable>(_ field: String, asArrayOf type: T.Type, in values: [Any], source: DatabaseSource) -> AnyPublisher<[T], Error>
    func whereField(_ field: String, arrayContains value: Any) -> Collection
    func whereField(_ field: String, isEqualTo value: Any) -> Collection
    func whereField(_ field: String, notIn values: [Any]) -> Collection
    func sorted(by field: String, direction: CollectionSortDirection) -> Collection
    func limit(_ limit: Int) -> Collection
    func publisher<T: Decodable>(asArrayOf type: T.Type) -> AnyPublisher<[T], Error>
    func getDocuments<T: Decodable>(ofType type: T.Type, source: DatabaseSource) -> AnyPublisher<[T], Error>
    func count() -> AnyPublisher<Int, Error>
}

enum CollectionSortDirection {
    case ascending
    case descending
}

extension Collection {
    func whereField<T: Decodable>(_ field: String, asArrayOf type: T.Type, in values: [Any], source: DatabaseSource = .default) -> AnyPublisher<[T], Error> {
        whereField(field, asArrayOf: T.self, in: values, source: source)
    }

    func sorted(by field: String, direction: CollectionSortDirection = .ascending) -> Collection {
        sorted(by: field, direction: direction)
    }

    func getDocuments<T: Decodable>(ofType type: T.Type, source: DatabaseSource = .default) -> AnyPublisher<[T], Error> {
        getDocuments(ofType: T.self, source: source)
    }
}

// MARK: Document

protocol Document {

    var exists: AnyPublisher<Bool, Error> { get }

    func set<T: Encodable>(value: T) -> AnyPublisher<Void, Error>
    func update(fields data: [String: Any]) -> AnyPublisher<Void, Error>
    func get<T: Decodable>(as type: T.Type, source: DatabaseSource) -> AnyPublisher<T, Error>
    func publisher<T: Decodable>(as type: T.Type) -> AnyPublisher<T, Error>

    func cacheFromServer() -> AnyPublisher<Void, Error>
}

extension Document {
    func get<T: Decodable>(as type: T.Type, source: DatabaseSource = .default) -> AnyPublisher<T, Error> {
        get(as: T.self, source: source)
    }
}

// MARK: Batch

protocol Batch {
    func commit() -> AnyPublisher<Void, Error>
    func set<T: Encodable>(value: T, forDocument document: Document)
}

// MARK: Source

enum DatabaseSource {
    /// Fetch data only from cache
    case cache

    /// Fetch data from cache, fallback to server if it doesn't exist
    case cacheFirst

    /// Fetch data directly from server
    case server

    /// Fetch from server first, then cache if failed
    case `default`
}
