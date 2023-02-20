import Combine
import CombineExt
import ECKit
import Factory
import HealthKit

/// Required typealias so that sourcery can generate mock for type `any HealthKitQuery`
typealias AnyHealthKitQuery = any HealthKitQuery

// sourcery: AutoMockable
protocol HealthKitManaging {
    var permissionStatus: AnyPublisher<PermissionStatus, Never> { get }
    func execute(_ query: AnyHealthKitQuery)
    func registerBackgroundDeliveryTask(_ publisher: AnyPublisher<Void, Never>)
    func requestPermissions()
}

final class HealthKitManager: HealthKitManaging {

    // MARK: - Public Properties

    let permissionStatus: AnyPublisher<PermissionStatus, Never>

    // MARK: - Private Properties
    
    @Injected(Container.analyticsManager) private var analyticsManager
    
    private var cancellables = Cancellables()

    private let healthStore = HKHealthStore()
    private let backgroundDeliveryReceivedSubject = PassthroughSubject<Void, Never>()
    private let permissionStatusSubject: CurrentValueSubject<[HealthKitPermissionType: PermissionStatus], Never>

    // MARK: - Initializers

    init() {
        permissionStatusSubject = .init(UserDefaults.standard.decode([HealthKitPermissionType: PermissionStatus].self, forKey: "health_kit_permissions") ?? [:])
        permissionStatus = permissionStatusSubject
            .handleEvents(receiveOutput: { UserDefaults.standard.encode($0, forKey: "health_kit_permissions") })
            .map { permissionStatuses in
                let hasUndetermined = HealthKitPermissionType.allCases
                    .contains { permissionType in
                        guard let permissionStatus = permissionStatuses[permissionType] else {
                            return true
                        }
                        return permissionStatus == .notDetermined
                    }

                guard !hasUndetermined else { return .notDetermined }

                let authorized = HealthKitPermissionType.allCases.allSatisfy { permissionStatuses[$0] == .authorized }
                return authorized ? .authorized : .denied
            }
            .share(replay: 1)
            .eraseToAnyPublisher()

        registerForBackgroundDelivery()
    }

    // MARK: - Public Methods

    func execute(_ query: any HealthKitQuery) {
        guard let underlyingQuery = query.underlyingQuery else { return }
        healthStore.execute(underlyingQuery)
    }

    func requestPermissions() {
        let permissionsToRequest = HealthKitPermissionType.allCases
            .filter { permissionStatusSubject.value[$0] != .authorized }

        healthStore.requestAuthorization(
            toShare: nil,
            read: .init(permissionsToRequest.map(\.objectType)),
            completion: { [weak self] authorized, error in
                guard let strongSelf = self else { return }
                let permissionStatus: PermissionStatus = authorized ? .authorized : .denied
                strongSelf.analyticsManager.log(event: .healthKitPermissions(authorized: authorized))
                var currentPermissions = strongSelf.permissionStatusSubject.value
                permissionsToRequest.forEach { currentPermissions[$0] = permissionStatus }
                strongSelf.permissionStatusSubject.send(currentPermissions)
                strongSelf.registerForBackgroundDelivery()
            }
        )
    }
    
    private var backgroundDeliveryPublishers = [AnyPublisher<Void, Never>]()
    func registerBackgroundDeliveryTask(_ publisher: AnyPublisher<Void, Never>) {
        backgroundDeliveryPublishers.append(publisher)
    }

    // MARK: - Private Methods

    private func registerForBackgroundDelivery() {
        let backgroundDeliveryTypes = HealthKitPermissionType.allCases
            .filter { permissionStatusSubject.value[$0] == .authorized }
            .compactMap { $0.objectType as? HKSampleType }

        for sampleType in backgroundDeliveryTypes {
            let query = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] _, completion, _ in
                guard let strongSelf = self else { return }
                strongSelf.backgroundDeliveryPublishers
                    .combineLatest()
                    .mapToVoid()
                    .first()
                    .sink(receiveValue: completion)
                    .store(in: &strongSelf.cancellables)
            }
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: sampleType, frequency: .hourly) { _, _ in }
        }
    }
}

extension Publishers {
    struct ZipMany<Element, F: Error>: Publisher {
        typealias Output = [Element]
        typealias Failure = F

        private let upstreams: [AnyPublisher<Element, F>]

        init(_ upstreams: [AnyPublisher<Element, F>]) {
            self.upstreams = upstreams
        }

        func receive<S: Subscriber>(subscriber: S) where Self.Failure == S.Failure, Self.Output == S.Input {
            let initial = Just<[Element]>([])
                .setFailureType(to: F.self)
                .eraseToAnyPublisher()

            let zipped = upstreams.reduce(into: initial) { result, upstream in
                result = result.zip(upstream) { elements, element in
                    elements + [element]
                }
                .eraseToAnyPublisher()
            }

            zipped.subscribe(subscriber)
        }
    }
}
