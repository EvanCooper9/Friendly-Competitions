import Combine
import HealthKit

// sourcery: AutoMockable
protocol HealthStoring {
    func execute(_ query: AnyHealthKitQuery)
    func enableBackgroundDelivery(for permissionType: HealthKitPermissionType) -> AnyPublisher<Bool, Error>
    func shouldRequest(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error>
    func request(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Void, Error>
}

// MARK: - HealthKit Implementations

extension HKHealthStore: HealthStoring {
    func execute(_ query: AnyHealthKitQuery) {
        execute(query.underlyingQuery)
    }

    func enableBackgroundDelivery(for permissionType: HealthKitPermissionType) -> AnyPublisher<Bool, Error> {
        Future { [weak self] promise in
            guard let self, let object = permissionType.objectType as? HKSampleType else { return }
            self.enableBackgroundDelivery(for: object, frequency: .hourly) { success, error in
                if let error {
                    promise(.failure(error))
                } else {
                    promise(.success(success))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func shouldRequest(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error> {
        Future { [weak self] promise in
            guard let self else { return }
            let objectTypes = permissions.map(\.objectType)
            self.getRequestStatusForAuthorization(toShare: [], read: .init(objectTypes)) { status, error in
                if let error {
                    promise(.failure(error))
                } else {
                    switch status {
                    case .shouldRequest:
                        promise(.success(true))
                    case .unnecessary, .unknown:
                        promise(.success(false))
                    @unknown default:
                        promise(.success(false))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func request(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Void, Error> {
        Future { [weak self] promise in
            guard let self else { return }
            let objectTypes = permissions.map(\.objectType)
            self.requestAuthorization(toShare: nil, read: .init(objectTypes)) { _, error in
                if let error {
                    promise(.failure(error))
                } else {
                    promise(.success(()))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
