import Combine
import CombineExt
import FirebaseFirestore

fileprivate extension Firestore.Encoder {
    static let custom: Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        encoder.dateEncodingStrategy = .formatted(.dateDashed)
        return encoder
    }()
}

fileprivate extension Firestore.Decoder {
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
    func whereField<T: Decodable>(_ field: String, asArrayOf type: T.Type, in values: [Any]) -> AnyPublisher<[T], Error> {
        .fromAsync {
            try await self
                .whereFieldWithChunking(field, in: values)
                .map { try $0.data(as: T.self, decoder: .custom) }
        }
    }

    func whereField(_ field: String, arrayContains value: Any) -> any Collection {
        let query: Query = whereField(field, arrayContains: value)
        return query
    }

    func whereField(_ field: String, isEqualTo value: Any) -> any Collection {
        let query: Query = whereField(field, isEqualTo: value)
        return query
    }

    func publisher<T: Decodable>(asArrayOf type: T.Type) -> AnyPublisher<[T], Error> {
        snapshotPublisher()
            .map(\.documents)
            .tryMap { try $0.map { try $0.data(as: T.self, decoder: .custom) } }
            .eraseToAnyPublisher()
    }

    func getDocuments<T: Decodable>(ofType type: T.Type) -> AnyPublisher<[T], Error> {
        getDocuments()
            .map(\.documents)
            .tryMap { try $0.map { try $0.data(as: T.self, decoder: .custom) } }
            .eraseToAnyPublisher()
    }
}

// MARK: Document

extension DocumentReference: Document {
    func setData<T: Encodable>(from value: T) -> AnyPublisher<Void, Error> {
        setData(from: value, encoder: .custom).eraseToAnyPublisher()
    }

    func updateData(from data: [String : Any]) -> AnyPublisher<Void, Error> {
        let subject = PassthroughSubject<Void, Error>()
        updateData(data) { error in
            if let error {
                subject.send(completion: .failure(error))
            } else {
                subject.send(())
                subject.send(completion: .finished)
            }
        }
        return subject.eraseToAnyPublisher()
    }

    func getDocument<T: Decodable>(as type: T.Type) -> AnyPublisher<T, Error> {
        let subject = PassthroughSubject<T, Error>()
        getDocument(as: T.self, decoder: .custom) { result in
            switch result {
            case .failure(let error):
                subject.send(completion: .failure(error))
            case .success(let data):
                subject.send(data)
                subject.send(completion: .finished)
            }
        }
        return subject.eraseToAnyPublisher()
    }

    func getDocumentPublisher<T: Decodable>(as type: T.Type) -> AnyPublisher<T, Error> {
        snapshotPublisher()
            .tryMap { try $0.data(as: T.self, decoder: .custom) }
            .eraseToAnyPublisher()
    }
}

// MARK: Batch

extension WriteBatch: Batch {
    func setData<T: Encodable>(from value: T, forDocument document: Document) throws {
        guard let documentReference = document as? DocumentReference else { return }
        try setData(from: value, forDocument: documentReference, encoder: .custom)
    }
}
