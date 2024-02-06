import Combine
import FirebaseStorage
import FirebaseStorageCombineSwift
import Foundation

extension StorageReference: Storage {
    func data(path: String) -> AnyPublisher<Data, Error> {
        child(path)
            .getData(maxSize: .max)
            .eraseToAnyPublisher()
    }
}
