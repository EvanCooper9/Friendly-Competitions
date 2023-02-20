import Algorithms
import FirebaseFirestore

public extension Query {

    private enum Constants {
        static let chunkSize = 10
    }

    /// Perform a where-in query with chunking. Firestore only allows for 10 elements in the query array.
    /// - Parameters:
    ///   - field: The name of the field to query
    ///   - values: The array the contains the values to match
    /// - Returns: An array of query doucment snapshots
    func whereFieldWithChunking(_ field: String, in values: [Any]) async throws -> [QueryDocumentSnapshot] {
        try await whereFieldWithChunkingHelper(field, values: values, contains: true)
    }

    // TODO: Figure out how to paginate `not-in` queries
//    func whereFieldWithChunking(_ field: String, notIn values: [Any]) async throws -> [QueryDocumentSnapshot] {
//        try await whereFieldWithChunkingHelper(field, values: values, contains: false)
//    }

    private func whereFieldWithChunkingHelper(_ field: String, values: [Any], contains: Bool) async throws -> [QueryDocumentSnapshot] {
        try await withThrowingTaskGroup(of: [QueryDocumentSnapshot].self) { group -> [QueryDocumentSnapshot] in
            values.chunks(ofCount: Constants.chunkSize).forEach { chunk in
                guard !chunk.isEmpty else { return }
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
