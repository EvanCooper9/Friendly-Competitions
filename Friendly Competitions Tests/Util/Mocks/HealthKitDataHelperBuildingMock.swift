import Combine
import Foundation

@testable import Friendly_Competitions

final class HealthKitDataHelperBuildingMock<D>: HealthKitDataHelperBuilding {

    private(set) var healthKitDataHelper: HealthKitDataHelperMock<D>!

    func bulid<Data>(fetch fetchClosure: @escaping (DateInterval) -> AnyPublisher<Data, Error>, upload uploadClosure: @escaping (Data) -> AnyPublisher<Void, Error>) -> any HealthKitDataHelping<Data> {
        let helper = HealthKitDataHelperMock(fetch: fetchClosure, upload: uploadClosure)
        if let healthKitDataHelper = helper as? HealthKitDataHelperMock<D> {
            self.healthKitDataHelper = healthKitDataHelper
        }
        return helper
    }
}

final class HealthKitDataHelperMock<Data>: HealthKitDataHelping {

    private let fetchClosure: (DateInterval) -> AnyPublisher<Data, Error>
    private let uploadClosure: (Data) -> AnyPublisher<Void, Error>

    init(fetch fetchClosure: @escaping (DateInterval) -> AnyPublisher<Data, Error>, upload uploadClosure: @escaping (Data) -> AnyPublisher<Void, Error>) {
        self.fetchClosure = fetchClosure
        self.uploadClosure = uploadClosure
    }

    func fetch(dateInterval: DateInterval) -> AnyPublisher<Data, Error> {
        fetchClosure(dateInterval)
    }

    func uplaod(data: Data) -> AnyPublisher<Void, Error> {
        uploadClosure(data)
    }
}
