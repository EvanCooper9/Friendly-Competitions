import ECKit
import Firebase
import FirebaseFirestore
import FirebaseCrashlytics

enum DocumentSnapshotDecodingError: Error {
    case missingData
}

public extension DocumentSnapshot {
    func decoded<T: Decodable>(as type: T.Type) throws -> T {
        guard exists, let documentData = data() else {
            throw DocumentSnapshotDecodingError.missingData
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: documentData, options: [])
            return try JSONDecoder.shared.decode(T.self, from: data)
        } catch {
            let nsError = (error as NSError).addingItemsToUserInfo([
                "documentPath": reference.path,
                "type": String(describing: type),
                "data": documentData
            ])
            Crashlytics.crashlytics().record(error: nsError)
            throw error
        }
    }
}

public extension Array where Element: DocumentSnapshot {
    func decoded<T: Decodable>(asArrayOf type: T.Type) -> [T] {
        compactMap { try? $0.decoded(as: T.self) }
    }
}

extension NSError {
    func addingItemsToUserInfo(_ newUserInfo: [String: Any]) -> NSError {
        var currentUserInfo = userInfo
        newUserInfo.forEach { (key, value) in
            currentUserInfo[key] = value
        }
        return NSError(domain: domain, code: code, userInfo: currentUserInfo)
    }
}
