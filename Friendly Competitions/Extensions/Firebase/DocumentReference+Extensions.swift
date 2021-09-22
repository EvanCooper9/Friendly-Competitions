import FirebaseFirestore

extension DocumentReference {
    func setDataEncodable<T: Encodable>(_ data: T, completion: ((Error?) -> Void)? = nil) throws {
        setData(try data.jsonDictionary(), completion: completion)
    }
}
