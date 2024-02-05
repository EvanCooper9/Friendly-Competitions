import Combine
import HealthKit

// sourcery: AutoMockable
protocol HealthStoring {
    func disableBackgroundDelivery(for permissionType: HealthKitPermissionType) -> AnyPublisher<Bool, Error>
    func execute(_ query: AnyHealthKitQuery)
    func enableBackgroundDelivery(for permissionType: HealthKitPermissionType) -> AnyPublisher<Bool, Error>
    func shouldRequest(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error>
    func request(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error>
}

// MARK: - HealthKit Implementations

enum HealthStoreError: Error {
    case unknown
}

extension HKHealthStore: HealthStoring {

    func disableBackgroundDelivery(for permissionType: HealthKitPermissionType) -> AnyPublisher<Bool, Error> {
        Future { [weak self] promise in
            guard let self, let objectType = permissionType.objectType as? HKSampleType else {
                promise(.failure(HealthStoreError.unknown))
                return
            }
            disableBackgroundDelivery(for: objectType) { success, error in
                if let error {
                    error.reportToCrashlytics()
                    promise(.failure(error))
                } else {
                    promise(.success(success))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func execute(_ query: AnyHealthKitQuery) {
        execute(query.underlyingQuery)
    }

    func enableBackgroundDelivery(for permissionType: HealthKitPermissionType) -> AnyPublisher<Bool, Error> {
        Future { [weak self] promise in
            guard let self, let object = permissionType.objectType as? HKSampleType else {
                promise(.failure(HealthStoreError.unknown))
                return
            }
            enableBackgroundDelivery(for: object, frequency: .hourly) { success, error in
                if let error {
                    error.reportToCrashlytics()
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
            guard let self else {
                promise(.failure(HealthStoreError.unknown))
                return
            }
            let objectTypes = permissions.map(\.objectType)
            getRequestStatusForAuthorization(toShare: [], read: .init(objectTypes)) { status, error in
                if let error {
                    error.reportToCrashlytics()
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

    func request(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error> {
        Future { [weak self] promise in
            guard let self else {
                promise(.failure(HealthStoreError.unknown))
                return
            }
            let objectTypes = permissions.map(\.objectType)
            requestAuthorization(toShare: nil, read: .init(objectTypes)) { success, error in
                if let error {
                    error.reportToCrashlytics()
                    promise(.failure(error))
                } else {
                    promise(.success(success))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
