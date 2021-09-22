import FirebaseFirestore

extension CollectionReference {
    func addDocumentEncodable<T: Encodable>(_ data: T, completion: ((Error?) -> Void)? = nil) throws {
        addDocument(data: try data.jsonDictionary(), completion: completion)
    }
}
