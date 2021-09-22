import FirebaseFirestore

protocol FirestoreTransactionHelper {

    associatedtype Writer

    func setData(_ data: [String: Any], forDocument document: DocumentReference) -> Writer
    func setDataEncodable<T: Encodable>(_ data: T, forDocument document: DocumentReference) throws -> Writer
}

extension FirestoreTransactionHelper {
    func setDataEncodable<T: Encodable>(_ data: T, forDocument document: DocumentReference) throws -> Writer {
        return setData(try data.jsonDictionary(), forDocument: document)
    }
}

extension WriteBatch: FirestoreTransactionHelper {
    typealias Writer = WriteBatch
}
