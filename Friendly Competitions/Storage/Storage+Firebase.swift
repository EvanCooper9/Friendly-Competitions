import Combine
import FirebaseStorage

extension StorageReference: Storage {
    func data(path: String) -> AnyPublisher<Data, Error> {
        child(path)
            .getData(maxSize: .max)
            .eraseToAnyPublisher()
    }
}
