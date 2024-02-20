import Combine

// MARK: Database

// sourcery: AutoMockable
public protocol Database {
    func batch() -> Batch
    func collection(_ collectionPath: String) -> Collection
    func collectionGroup(_ collectionGroupID: String) -> Collection
    func document(_ documentPath: String) -> Document
}

// MARK: Collection

public protocol Collection {
    func filter(_ filter: CollectionFilter, on field: String) -> Collection
    func sorted(by field: String, direction: CollectionSortDirection) -> Collection
    func limit(_ limit: Int) -> Collection
    func publisher<T: Decodable>(asArrayOf type: T.Type) -> AnyPublisher<[T], Error>
    func getDocuments<T: Decodable>(ofType type: T.Type, source: DatabaseSource) -> AnyPublisher<[T], Error>
    func count() -> AnyPublisher<Int, Error>
}

public enum CollectionFilter {
    case arrayContains(value: Any)
    case isEqualTo(value: Any)
    case notIn(values: [Any])
    case greaterThan(value: Any)
    case greaterThanOrEqualTo(value: Any)
    case lessThan(value: Any)
    case lessThanOrEqualTo(value: Any)
}

public enum CollectionSortDirection {
    case ascending
    case descending
}

public extension Collection {
    func sorted(by field: String, direction: CollectionSortDirection = .ascending) -> Collection {
        sorted(by: field, direction: direction)
    }

    func getDocuments<T: Decodable>(ofType type: T.Type, source: DatabaseSource = .default) -> AnyPublisher<[T], Error> {
        getDocuments(ofType: T.self, source: source)
    }
}

// MARK: Document

public protocol Document {

    var exists: AnyPublisher<Bool, Error> { get }

    func set<T: Encodable>(value: T) -> AnyPublisher<Void, Error>
    func update(fields data: [String: Any]) -> AnyPublisher<Void, Error>
    func get<T: Decodable>(as type: T.Type, source: DatabaseSource) -> AnyPublisher<T, Error>
    func publisher<T: Decodable>(as type: T.Type) -> AnyPublisher<T, Error>

    func cacheFromServer() -> AnyPublisher<Void, Error>
}

public extension Document {
    func get<T: Decodable>(as type: T.Type, source: DatabaseSource = .default) -> AnyPublisher<T, Error> {
        get(as: T.self, source: source)
    }
}

// MARK: Batch

public protocol Batch {
    func commit() -> AnyPublisher<Void, Error>
    func set<T: Encodable>(value: T, forDocument document: Document)
}

// MARK: Source

public enum DatabaseSource {
    /// Fetch data only from cache
    case cache

    /// Fetch data from cache, fallback to server if it doesn't exist
    case cacheFirst

    /// Fetch data directly from server
    case server

    /// Fetch from server first, then cache if failed
    case `default`
}
