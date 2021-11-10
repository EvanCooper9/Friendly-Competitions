import FirebaseFirestore

extension DocumentReference {

    func setDataEncodable<T: Encodable>(_ data: T, completion: ((Error?) -> Void)? = nil) throws {
        setData(try data.jsonDictionary(), completion: completion)
    }

    func setDataEncodable<T: Encodable>(_ data: T) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try setDataEncodable(data) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume()
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func updateDataEncodable<T: Encodable>(_ data: T, completion: ((Error?) -> Void)? = nil) throws {
        updateData(try data.jsonDictionary(), completion: completion)
    }

    func updateDataEncodable<T: Encodable>(_ data: T) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            do {
                try updateDataEncodable(data) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                        return
                    }
                    continuation.resume()
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
