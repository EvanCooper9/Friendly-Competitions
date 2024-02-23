import Combine
import CombineExt
import Factory
import FirebaseCrashlytics
import FirebaseFirestore
import FirebaseFirestoreCombineSwift

extension JSONDecoder {
    public static let custom: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.dateDashed)
        return decoder
    }()
}

extension JSONEncoder {
    public static let custom: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(.dateDashed)
        return encoder
    }()
}

extension Firestore.Encoder {
    public static let custom: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.dateEncodingStrategy = .formatted(.dateDashed)
        return encoder
    }()
}

extension Firestore.Decoder {
    public static let custom: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.dateDecodingStrategy = .formatted(.dateDashed)
        return decoder
    }()
}

// MARK: - Database

extension Firestore: Database {
    public func batch() -> Batch {
        let writeBatch: WriteBatch = batch()
        return writeBatch
    }

    public func collection(_ collectionPath: String) -> any Collection {
        let collectionRef: CollectionReference = collection(collectionPath)
        return collectionRef
    }

    public func collectionGroup(_ collectionGroupID: String) -> any Collection {
        let query: Query = collectionGroup(collectionGroupID)
        return query
    }

    public func document(_ documentPath: String) -> Document {
        let documentRef: DocumentReference = document(documentPath)
        return documentRef
    }
}

// MARK: Collection

extension Query: Collection {
    public func count() -> AnyPublisher<Int, Error> {
        Future { [count] promise in
            count.getAggregation(source: .server) { snapshot, error in
                if let error {
                    promise(.failure(error))
                } else if let snapshot {
                    promise(.success(Int(truncating: snapshot.count)))
                }
            }
        }
        .reportErrorToCrashlytics()
        .eraseToAnyPublisher()
    }

    public func filter(_ filter: CollectionFilter, on field: String) -> Collection {
        switch filter {
        case .arrayContains(let value):
            return whereField(field, arrayContains: value)
        case .isEqualTo(let value):
            return whereField(field, isEqualTo: value)
        case .notIn(let values):
            guard values.isNotEmpty else { return self }
            return whereField(field, notIn: values)
        case .greaterThan(let value):
            return whereField(field, isGreaterThan: value)
        case .greaterThanOrEqualTo(let value):
            return whereField(field, isGreaterThanOrEqualTo: value)
        case .lessThan(let value):
            return whereField(field, isLessThan: value)
        case .lessThanOrEqualTo(let value):
            return whereField(field, isLessThanOrEqualTo: value)
        }
    }

    public func sorted(by field: String, direction: CollectionSortDirection) -> Collection {
        order(by: field, descending: direction == .descending)
    }

    public func limit(_ limit: Int) -> Collection {
        self.limit(to: limit)
    }

    public func publisher<T: Decodable>(asArrayOf type: T.Type) -> AnyPublisher<[T], Error> {
        snapshotPublisher()
            .handleEvents(receiveOutput: { snapshot in
                guard snapshot.documents.isNotEmpty, !snapshot.metadata.isFromCache else { return }
                let analyticsManager = Container.shared.analyticsManager()
                snapshot.documents.forEach { document in
                    analyticsManager.log(event: .databaseRead(path: document.reference.path))
                }
            })
            .map { $0.documents.decoded(as: T.self) }
            .reportErrorToCrashlytics(userInfo: [
                "type": String(describing: T.self)
            ])
    }

    public func getDocuments<T>(ofType type: T.Type, source: DatabaseSource) -> AnyPublisher<[T], Error> where T : Decodable {
        let query = self
        return getDocuments(source: source.firestoreSource)
            .handleEvents(receiveOutput: { snapshot in
                guard snapshot.documents.isNotEmpty, !snapshot.metadata.isFromCache else { return }
                let analyticsManager = Container.shared.analyticsManager()
                snapshot.documents.forEach { document in
                    analyticsManager.log(event: .databaseRead(path: document.reference.path))
                }
            })
            .map { $0.documents.decoded(as: T.self) }
            .flatMapLatest { [query] (results: [T]) -> AnyPublisher<[T], Error> in
                guard results.isEmpty, source == .cacheFirst else { return .just(results) }
                return query.getDocuments(ofType: T.self, source: .server)
            }
            .reportErrorToCrashlytics(userInfo: [
                "type": String(describing: T.self)
            ])
    }
}

// MARK: Document

extension DocumentReference: Document {

    public var exists: AnyPublisher<Bool, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.success(false))
                return
            }
            self.getDocument { document, error in
                if let error {
                    promise(.failure(error))
                } else {
                    promise(.success(document?.exists ?? false))
                }
            }
        }
        .reportErrorToCrashlytics(userInfo: [
            "path": path
        ])
        .eraseToAnyPublisher()
    }

    public func set<T: Encodable>(value: T) -> AnyPublisher<Void, Error> {
        setData(from: value, encoder: .custom)
            .handleEvents(receiveOutput: { [path] in
                let analyticsManager = Container.shared.analyticsManager()
                analyticsManager.log(event: .databaseWrite(path: path))
            })
            .reportErrorToCrashlytics(userInfo: [
                "path": path,
                "data": value,
                "type": String(describing: T.self)
            ])
    }

    public func update(fields data: [String : Any]) -> AnyPublisher<Void, Error> {
        Future { [weak self, path] promise in
            guard let self else { return }
            self.updateData(data) { error in

                let analyticsManager = Container.shared.analyticsManager()
                analyticsManager.log(event: .databaseWrite(path: path))

                if let error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .reportErrorToCrashlytics(userInfo: [
            "path": path,
            "data": data
        ])
    }

    public func get<T: Decodable>(as type: T.Type, source: DatabaseSource, reportErrors: Bool) -> AnyPublisher<T, Error> {
        let document = self
        return Future { [weak self] promise in
            guard let self else { return }
            self.getDocument(source: source.firestoreSource) { snapshot, error in
                if let error {
                    promise(.failure(error))
                    return
                } else if let snapshot {
                    if !snapshot.metadata.isFromCache {
                        let analyticsManager = Container.shared.analyticsManager()
                        analyticsManager.log(event: .databaseRead(path: snapshot.reference.path))
                    }
                    do {
                        let data = try snapshot.data(as: T.self, decoder: .custom)
                        promise(.success(data))
                    } catch {
                        promise(.failure(error))
                    }
                }
            }
        }
        .catch { [document] error -> AnyPublisher<T, Error> in
            if reportErrors {
                error.reportToCrashlytics(userInfo: ["path": document.path, "type": String(describing: T.self)])
            }
            guard source == .cacheFirst else {
                return .error(error)
            }
            return document.get(as: T.self, source: .server)
        }
        .eraseToAnyPublisher()
    }

    public func publisher<T: Decodable>(as type: T.Type) -> AnyPublisher<T, Error> {
        snapshotPublisher()
            .handleEvents(receiveOutput: { snapshot in
                let analyticsManager = Container.shared.analyticsManager()
                analyticsManager.log(event: .databaseRead(path: snapshot.reference.path))
            })
            .tryMap { try $0.data(as: T.self, decoder: .custom) }
            .reportErrorToCrashlytics(userInfo: [
                "path": path,
                "type": String(describing: T.self)
            ])
    }

    public func cacheFromServer() -> AnyPublisher<Void, Error> {
        Future { promise in
            self.getDocument(source: .server) { _, error in
                if let error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
        .reportErrorToCrashlytics(userInfo: [
            "path": path
        ])
    }
}

// MARK: Batch

extension WriteBatch: Batch {
    public func set<T>(value: T, forDocument document: Document) where T : Encodable {
        guard let documentReference = document as? DocumentReference else { return }
        let analyticsManager = Container.shared.analyticsManager()
        analyticsManager.log(event: .databaseWrite(path: documentReference.path))
        _ = try? setData(from: value, forDocument: documentReference, encoder: .custom)
    }

    public func commit() -> AnyPublisher<Void, Error> {
        Future { promise in
            self.commit { error in
                if let error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .reportErrorToCrashlytics()
        .eraseToAnyPublisher()
    }
}

// MARK: Database Source

fileprivate extension DatabaseSource {
    var firestoreSource: FirestoreSource {
        switch self {
        case .cache, .cacheFirst:
            return .cache
        case .server:
            return .server
        case .default:
            return .default
        }
    }
}

// MARK: - Helpers

fileprivate extension Array where Element == QueryDocumentSnapshot {
    func decoded<T: Decodable>(as: T.Type) -> [T] {
        compactMap { document in
            do {
                return try document.data(as: T.self, decoder: .custom)
            } catch {
                error.reportToCrashlytics(userInfo: [
                    "path": document.reference.path,
                    "data": document.data(),
                    "type": String(describing: T.self)
                ])
                return nil
            }
        }
    }
}
