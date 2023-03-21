import Combine

@testable import Friendly_Competitions

final class CollectionMock<Model: Decodable>: Collection {
    var whereFieldInClosure: (() -> AnyPublisher<[Model], Error>)?
    func whereField<T: Decodable>(_ field: String, asArrayOf type: T.Type, in values: [Any]) -> AnyPublisher<[T], Error> {
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

    var publisherCallCount = 0
    var publisherClosure: (() -> AnyPublisher<[Model], Error>)?
    func publisher<T: Decodable>(asArrayOf type: T.Type) -> AnyPublisher<[T], Error> {
        publisherCallCount += 1
        return publisherClosure!()
            .map { $0 as! [T] }
            .eraseToAnyPublisher()
    }

    var getDocumentsClosure: (() -> AnyPublisher<[Model], Error>)?
    func getDocuments<T>(ofType type: T.Type) -> AnyPublisher<[T], Error> {
        getDocumentsClosure!()
            .map { $0 as! [T] }
            .eraseToAnyPublisher()
    }
}

final class DocumentMock<Model: Codable>: Document {
    var setDataClosure: ((Model) -> AnyPublisher<Void, Error>)?
    func setData<T: Encodable>(from value: T) -> AnyPublisher<Void, Error> {
        setDataClosure!(value as! Model)
    }

    var updateDataClosure: (([String: Any]) -> AnyPublisher<Void, Error>)?
    func updateData(from data: [String: Any]) -> AnyPublisher<Void, Error> {
        updateDataClosure!(data)
    }

    var getDocumentClosure: ((Model.Type) -> AnyPublisher<Model, Error>)?
    func getDocument<T: Decodable>(as type: T.Type) -> AnyPublisher<T, Error> {
        getDocumentClosure!(T.self as! Model.Type)
            .map { $0 as! T }
            .eraseToAnyPublisher()
    }

    var getDocumentPublisherClosure: ((Model.Type) -> AnyPublisher<Model, Error>)?
    func getDocumentPublisher<T: Decodable>(as type: T.Type) -> AnyPublisher<T, Error> {
        getDocumentPublisherClosure!(T.self as! Model.Type)
            .map { $0 as! T }
            .eraseToAnyPublisher()
    }
}

final class BatchMock<Model: Decodable>: Batch {

    var commitClosure: (() -> Void)?
    func commit() async throws {
        commitClosure!()
    }

    var setDataCallCount = 0
    var setDataClosure: ((Model, Document) -> Void)?
    func setData<T: Encodable>(from value: T, forDocument document: Document) throws {
        setDataCallCount += 1
        setDataClosure!(value as! Model, document)
    }
}
