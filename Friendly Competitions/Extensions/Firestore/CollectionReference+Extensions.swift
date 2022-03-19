import Algorithms
import Firebase
import FirebaseFirestore

extension CollectionReference {
    func addDocumentEncodable<T: Encodable>(_ data: T, completion: ((Error?) -> Void)? = nil) throws {
        addDocument(data: try data.jsonDictionary(), completion: completion)
    }

    func whereFieldWithChunking(_ field: String, in values: [Any]) async throws -> [QueryDocumentSnapshot] {
        try await whereFieldWithChunkingHelper(field, values: values, contains: true)
    }

    // TODO: Figure out how to paginate `not-in` queries
//    func whereFieldWithChunking(_ field: String, notIn values: [Any]) async throws -> [QueryDocumentSnapshot] {
//        try await whereFieldWithChunkingHelper(field, values: values, contains: false)
//    }

    private func whereFieldWithChunkingHelper(_ field: String, values: [Any], contains: Bool) async throws -> [QueryDocumentSnapshot] {
        try await withThrowingTaskGroup(of: [QueryDocumentSnapshot].self) { group -> [QueryDocumentSnapshot] in
            values.chunks(ofCount: 10).forEach { chunk in
                group.addTask { [weak self] in
                    guard let self = self else { return [] }
                    let query = contains ?
                        self.whereField(field, in: Array(chunk)) :
                        self.whereField(field, notIn: Array(chunk))

                    return try await query
                        .getDocuments()
                        .documents
                }
            }

            var results = [QueryDocumentSnapshot]()
            for try await chunkedResults in group {
                results.append(contentsOf: chunkedResults)
            }
            return results
        }
    }
}
