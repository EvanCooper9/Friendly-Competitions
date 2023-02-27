import HealthKit

// sourcery: AutoMockable
protocol HealthStoring {
    func execute(_ query: AnyHealthKitQuery)
    func enableBackgroundDelivery(for permissionType: HealthKitPermissionType)
    func requestAuthorization(for permissionTypes: [HealthKitPermissionType], completion: @escaping (Bool) -> Void)
}

// MARK: - HealthKit Implementations

extension HKHealthStore: HealthStoring {
    func execute(_ query: AnyHealthKitQuery) {
        execute(query.underlyingQuery)
    }
    
    func enableBackgroundDelivery(for permissionType: HealthKitPermissionType) {
        guard let object = permissionType.objectType as? HKSampleType else { return }
        enableBackgroundDelivery(for: object, frequency: .hourly) { _, _ in }
    }
    
    func requestAuthorization(for permissionTypes: [HealthKitPermissionType], completion: @escaping (Bool) -> Void) {
        requestAuthorization(toShare: nil, read: .init(permissionTypes.map(\.objectType))) { authorized, error in
            completion(authorized)
        }
    }
}
