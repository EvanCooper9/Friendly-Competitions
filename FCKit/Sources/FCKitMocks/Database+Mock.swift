import Combine
import FCKit

public final class CollectionMock<Model: Decodable>: Collection {

    public init() {}

    public var filterOnClosure: ((CollectionFilter, String) -> Collection)?
    public func filter(_ filter: CollectionFilter, on field: String) -> Collection {
        filterOnClosure!(filter, field)
    }

    public var sortedClosure: ((String, CollectionSortDirection) -> Collection)?
    public func sorted(by field: String, direction: CollectionSortDirection) -> Collection {
        sortedClosure!(field, direction)
    }

    public var limitClosure: ((Int) -> Collection)?
    public func limit(_ limit: Int) -> Collection {
        limitClosure!(limit)
    }

    public var publisherCallCount = 0
    public var publisherClosure: (() -> AnyPublisher<[Model], Error>)?
    public func publisher<T: Decodable>(asArrayOf type: T.Type) -> AnyPublisher<[T], Error> {
        publisherCallCount += 1
        return publisherClosure!()
            .map { $0 as! [T] }
            .eraseToAnyPublisher()
    }

    public var getDocumentsCallCount = 0
    public var getDocumentsClosure: ((Model.Type, DatabaseSource) -> AnyPublisher<[Model], Error>)?
    public func getDocuments<T>(ofType type: T.Type, source: DatabaseSource) -> AnyPublisher<[T], Error> where T : Decodable {
        getDocumentsCallCount += 1
        return getDocumentsClosure!(T.self as! Model.Type, source)
            .map { $0 as! [T] }
            .eraseToAnyPublisher()
    }

    public var countReturnValue: AnyPublisher<Int, Error>!
    public func count() -> AnyPublisher<Int, Error> {
        countReturnValue!
    }
}

public final class DocumentMock<Model: Codable>: Document {

    public init() {}

    private var underlyingExists: AnyPublisher<Bool, Error>!
    public var exists: AnyPublisher<Bool, Error> {
        get { underlyingExists }
        set { underlyingExists = newValue }
    }

    public var setClosure: ((Model) -> AnyPublisher<Void, Error>)?
    public func set<T: Encodable>(value: T) -> AnyPublisher<Void, Error> {
        setClosure!(value as! Model)
    }

    public var updateDataClosure: (([String: Any]) -> AnyPublisher<Void, Error>)?
    public func update(fields data: [String: Any]) -> AnyPublisher<Void, Error> {
        updateDataClosure!(data)
    }

    public var getClosure: ((Model.Type, DatabaseSource) -> AnyPublisher<Model, Error>)?
    public func get<T: Decodable>(as type: T.Type, source: DatabaseSource, reportErrors: Bool) -> AnyPublisher<T, Error> {
        getClosure!(T.self as! Model.Type, source)
            .map { $0 as! T }
            .eraseToAnyPublisher()
    }

    public var getDocumentPublisherClosure: ((Model.Type) -> AnyPublisher<Model, Error>)?
    public func publisher<T: Decodable>(as type: T.Type) -> AnyPublisher<T, Error> {
        getDocumentPublisherClosure!(T.self as! Model.Type)
            .map { $0 as! T }
            .eraseToAnyPublisher()
    }

    public var cacheFromServerClosure: (() -> AnyPublisher<Void, Error>)?
    public func cacheFromServer() -> AnyPublisher<Void, Error> {
        cacheFromServerClosure!()
    }
}

public final class BatchMock<Model: Decodable>: Batch {

    public init() {}

    public var commitCallCount = 0
    public var commitClosure: (() -> AnyPublisher<Void, Error>)?
    public func commit() -> AnyPublisher<Void, Error> {
        commitCallCount += 1
        return commitClosure!()
    }

    public var setCallCount = 0
    public var setClosure: ((Model, Document) -> Void)?
    public func set<T: Encodable>(value: T, forDocument document: Document) {
        setCallCount += 1
        setClosure!(value as! Model, document)
    }
}
