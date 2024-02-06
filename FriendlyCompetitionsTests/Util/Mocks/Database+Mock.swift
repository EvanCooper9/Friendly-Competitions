import Combine

@testable import Friendly_Competitions

final class CollectionMock<Model: Decodable>: Collection {
    var whereFieldInClosure: (() -> AnyPublisher<[Model], Error>)?
    func whereField<T: Decodable>(_ field: String, asArrayOf type: T.Type, in values: [Any], source: DatabaseSource) -> AnyPublisher<[T], Error> {
        whereFieldInClosure!()
            .map { $0 as! [T] }
            .eraseToAnyPublisher()
    }

    var whereFieldArrayContainsClosure: (() -> Collection)?
    func whereField(_ field: String, arrayContains value: Any) -> Collection {
        whereFieldArrayContainsClosure!()
    }

    var whereFieldIsEqualToClosure: (() -> Collection)?
    func whereField(_ field: String, isEqualTo value: Any) -> Collection {
        whereFieldIsEqualToClosure!()
    }

    var whereFieldIsNotInClosure: (() -> Collection)?
    func whereField(_ field: String, notIn values: [Any]) -> Collection {
        whereFieldIsNotInClosure!()
    }

    var sortedClosure: ((String, CollectionSortDirection) -> Collection)?
    func sorted(by field: String, direction: CollectionSortDirection) -> Collection {
        sortedClosure!(field, direction)
    }

    var limitClosure: ((Int) -> Collection)?
    func limit(_ limit: Int) -> Collection {
        limitClosure!(limit)
    }

    var publisherCallCount = 0
    var publisherClosure: (() -> AnyPublisher<[Model], Error>)?
    func publisher<T: Decodable>(asArrayOf type: T.Type) -> AnyPublisher<[T], Error> {
        publisherCallCount += 1
        return publisherClosure!()
            .map { $0 as! [T] }
            .eraseToAnyPublisher()
    }

    var getDocumentsCallCount = 0
    var getDocumentsClosure: ((Model.Type, DatabaseSource) -> AnyPublisher<[Model], Error>)?
    func getDocuments<T>(ofType type: T.Type, source: DatabaseSource) -> AnyPublisher<[T], Error> where T : Decodable {
        getDocumentsCallCount += 1
        return getDocumentsClosure!(T.self as! Model.Type, source)
            .map { $0 as! [T] }
            .eraseToAnyPublisher()
    }

    var countReturnValue: AnyPublisher<Int, Error>!
    func count() -> AnyPublisher<Int, Error> {
        countReturnValue!
    }
}

final class DocumentMock<Model: Codable>: Document {

    private var underlyingExists: AnyPublisher<Bool, Error>!
    var exists: AnyPublisher<Bool, Error> {
        get { underlyingExists }
        set { underlyingExists = newValue }
    }

    var setClosure: ((Model) -> AnyPublisher<Void, Error>)?
    func set<T: Encodable>(value: T) -> AnyPublisher<Void, Error> {
        setClosure!(value as! Model)
    }

    var updateDataClosure: (([String: Any]) -> AnyPublisher<Void, Error>)?
    func update(fields data: [String: Any]) -> AnyPublisher<Void, Error> {
        updateDataClosure!(data)
    }

    var getClosure: ((Model.Type, DatabaseSource) -> AnyPublisher<Model, Error>)?
    func get<T: Decodable>(as type: T.Type, source: DatabaseSource) -> AnyPublisher<T, Error> {
        getClosure!(T.self as! Model.Type, source)
            .map { $0 as! T }
            .eraseToAnyPublisher()
    }

    var getDocumentPublisherClosure: ((Model.Type) -> AnyPublisher<Model, Error>)?
    func publisher<T: Decodable>(as type: T.Type) -> AnyPublisher<T, Error> {
        getDocumentPublisherClosure!(T.self as! Model.Type)
            .map { $0 as! T }
            .eraseToAnyPublisher()
    }

    var cacheFromServerClosure: (() -> AnyPublisher<Void, Error>)?
    func cacheFromServer() -> AnyPublisher<Void, Error> {
        cacheFromServerClosure!()
    }
}

final class BatchMock<Model: Decodable>: Batch {

    var commitCallCount = 0
    var commitClosure: (() -> AnyPublisher<Void, Error>)?
    func commit() -> AnyPublisher<Void, Error> {
        commitCallCount += 1
        return commitClosure!()
    }

    var setCallCount = 0
    var setClosure: ((Model, Document) -> Void)?
    func set<T: Encodable>(value: T, forDocument document: Document) {
        setCallCount += 1
        setClosure!(value as! Model, document)
    }
}
