import Combine
import Foundation

protocol HealthKitDataHelperBuilding {
    func bulid<Data>(
        fetch fetchClosure: @escaping (DateInterval) -> AnyPublisher<Data, Error>,
        upload uploadClosure: @escaping (Data) -> AnyPublisher<Void, Error>
    ) -> any HealthKitDataHelping<Data>
}

final class HealthKitDataHelperBuilder: HealthKitDataHelperBuilding {
    func bulid<Data>(
        fetch fetchClosure: @escaping (DateInterval) -> AnyPublisher<Data, Error>,
        upload uploadClosure: @escaping (Data) -> AnyPublisher<Void, Error>
    ) -> any HealthKitDataHelping<Data> {
        HealthKitDataHelper<Data>(fetch: fetchClosure, upload: uploadClosure)
    }
}
