import Algorithms
import Combine
import CombineExt
import Factory
import FirebaseCrashlytics
import FirebaseFirestore
import FirebaseFirestoreCombineSwift
import FirebaseFirestoreSwift

extension JSONDecoder {
    static let custom: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(.dateDashed)
        return decoder
    }()
}

extension JSONEncoder {
    static let custom: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .formatted(.dateDashed)
        return encoder
    }()
}

extension Firestore.Encoder {
    static let custom: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.dateEncodingStrategy = .formatted(.dateDashed)
        return encoder
    }()
}

extension Firestore.Decoder {
    static let custom: Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        decoder.dateDecodingStrategy = .formatted(.dateDashed)
        return decoder
    }()
}

// MARK: - Database

extension Firestore: Database {
    func batch() -> Batch {
        let writeBatch: WriteBatch = batch()
        return writeBatch
    }

    func collection(_ collectionPath: String) -> any Collection {
        let collectionRef: CollectionReference = collection(collectionPath)
        return collectionRef
    }

    func collectionGroup(_ collectionGroupID: String) -> any Collection {
        let query: Query = collectionGroup(collectionGroupID)
        return query
    }

    func document(_ documentPath: String) -> Document {
        let documentRef: DocumentReference = document(documentPath)
        return documentRef
    }
}

// MARK: Collection

extension Query: Collection {
    func count() -> AnyPublisher<Int, Error> {
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

    func whereField<T: Decodable>(_ field: String, asArrayOf type: T.Type, in values: [Any], source: DatabaseSource) -> AnyPublisher<[T], Error> {
        let chunks = values.chunks(ofCount: 10).map { chunk in
            whereField(field, in: Array(chunk))
                .getDocuments(source: source.firestoreSource)
                .map { $0.documents.decoded(as: T.self) }
                .eraseToAnyPublisher()
        }

        return Publishers
            .ZipMany(chunks)
            .map { $0.reduce([], +) }
            .reportErrorToCrashlytics(userInfo: [
                 "field": field,
                 "values": values,
                 "type": String(describing: T.self)
             ])
    }

    func whereField(_ field: String, arrayContains value: Any) -> any Collection {
        let query: Query = whereField(field, arrayContains: value)
        return query
    }

    func whereField(_ field: String, isEqualTo value: Any) -> any Collection {
        let query: Query = whereField(field, isEqualTo: value)
        return query
    }

    func whereField(_ field: String, notIn values: [Any]) -> Collection {
        guard values.isNotEmpty else { return self }
        let query: Query = whereField(field, notIn: values)
        return query
    }

    func sorted(by field: String, direction: CollectionSortDirection) -> Collection {
        let query: Query = order(by: field, descending: direction == .descending)
        return query
    }

    func limit(_ limit: Int) -> Collection {
        let query: Query = self.limit(to: limit)
        return query
    }

    func publisher<T: Decodable>(asArrayOf type: T.Type) -> AnyPublisher<[T], Error> {
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

    func getDocuments<T>(ofType type: T.Type, source: DatabaseSource) -> AnyPublisher<[T], Error> where T : Decodable {
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

    var exists: AnyPublisher<Bool, Error> {
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

    func set<T: Encodable>(value: T) -> AnyPublisher<Void, Error> {
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

    func update(fields data: [String : Any]) -> AnyPublisher<Void, Error> {
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

    func get<T: Decodable>(as type: T.Type, source: DatabaseSource) -> AnyPublisher<T, Error> {
        Future { [weak self] promise in
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
        .catch { [weak self] error -> AnyPublisher<T, Error> in
            guard let self else { return .never() }
            guard source == .cacheFirst else { return .error(error) }
            return self.get(as: T.self, source: .server)
        }
        .reportErrorToCrashlytics(userInfo: [
            "path": path,
            "type": String(describing: T.self)
        ])
    }

    func publisher<T: Decodable>(as type: T.Type) -> AnyPublisher<T, Error> {
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

    func cacheFromServer() -> AnyPublisher<Void, Error> {
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
    func set<T>(value: T, forDocument document: Document) where T : Encodable {
        guard let documentReference = document as? DocumentReference else { return }
        let analyticsManager = Container.shared.analyticsManager()
        analyticsManager.log(event: .databaseWrite(path: documentReference.path))
        _ = try? setData(from: value, forDocument: documentReference, encoder: .custom)
    }

    func commit() -> AnyPublisher<Void, Error> {
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

extension Publisher where Failure == Error {
    func reportErrorToCrashlytics(userInfo: [String: Any] = [:], caller: String = #function) -> AnyPublisher<Output, Failure> {
        self.catch { error -> AnyPublisher<Output, Failure> in
            var userInfo = userInfo
            userInfo["caller"] = caller
            error.reportToCrashlytics(userInfo: userInfo)
            return .error(error)
        }
        .eraseToAnyPublisher()
    }
}

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

extension Error {
    func reportToCrashlytics(userInfo: [String: Any] = [:], file: String = #file, line: Int = #line) {
        var nsError = self as NSError

        var userInfo = nsError.userInfo.merging(userInfo) { _, newValue in newValue }
        userInfo["file"] = file
        userInfo["line"] = line

        nsError = NSError(
            domain: nsError.domain,
            code: nsError.code,
            userInfo: nsError.userInfo.merging(userInfo) { _, newValue in newValue }
        )
        Crashlytics.crashlytics().record(error: nsError)
    }
}