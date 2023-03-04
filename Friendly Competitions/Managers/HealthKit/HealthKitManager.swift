import Combine
import CombineExt
import ECKit
import Factory
import HealthKit

// sourcery: AutoMockable
protocol HealthKitManaging {
    var permissionStatus: AnyPublisher<PermissionStatus, Never> { get }
    func execute(_ query: AnyHealthKitQuery)
    func registerBackgroundDeliveryTask(_ publisher: AnyPublisher<Void, Never>)
    func requestPermissions()
}

final class HealthKitManager: HealthKitManaging {

    // MARK: - Public Properties

    var permissionStatus: AnyPublisher<PermissionStatus, Never> {
        permissionStatusSubject
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
            .eraseToAnyPublisher()
    }

    // MARK: - Private Properties
    
    @Injected(Container.analyticsManager) private var analyticsManager
    @Injected(Container.healthStore) private var healthStore
    @Injected(Container.healthKitManagerCache) private var cache
    
    private let backgroundDeliveryReceivedSubject = PassthroughSubject<Void, Never>()
    private let permissionStatusSubject = ReplaySubject<[HealthKitPermissionType: PermissionStatus], Never>(bufferSize: 1)
    
    private var cancellables = Cancellables()

    // MARK: - Initializers

    init() {
        permissionStatusSubject.send(cache.permissionStatus)
        permissionStatusSubject
            .dropFirst()
            .sink(withUnretained: self) { $0.cache.permissionStatus = $1 }
            .store(in: &cancellables)
        registerForBackgroundDelivery()
    }

    // MARK: - Public Methods

    func execute(_ query: AnyHealthKitQuery) {
        healthStore.execute(query)
    }

    func requestPermissions() {
        let permissionsToRequest = HealthKitPermissionType.allCases
            .filter { cache.permissionStatus[$0] != .authorized }

        healthStore.requestAuthorization(for: permissionsToRequest) { [weak self] authorized in
            guard let strongSelf = self else { return }
            let permissionStatus: PermissionStatus = authorized ? .authorized : .denied
            strongSelf.analyticsManager.log(event: .healthKitPermissions(authorized: authorized))
            var currentPermissions = strongSelf.cache.permissionStatus
            permissionsToRequest.forEach { currentPermissions[$0] = permissionStatus }
            strongSelf.permissionStatusSubject.send(currentPermissions)
            strongSelf.registerForBackgroundDelivery()
        }
    }
    
    private var backgroundDeliveryPublishers = [AnyPublisher<Void, Never>]()
    func registerBackgroundDeliveryTask(_ publisher: AnyPublisher<Void, Never>) {
        backgroundDeliveryPublishers.append(publisher)
    }

    // MARK: - Private Methods

    private func registerForBackgroundDelivery() {
        let backgroundDeliveryTypes = HealthKitPermissionType.allCases
            .filter { cache.permissionStatus[$0] == .authorized }

        for sampleType in backgroundDeliveryTypes {
            guard let hkSampleType = sampleType.objectType as? HKSampleType else { continue }
            let query = ObserverQuery(sampleType: hkSampleType) { [weak self] result in
                guard let strongSelf = self else { return }
                switch result {
                case .failure:
                    break
                case .success(let completion):
                    strongSelf.backgroundDeliveryPublishers
                        .combineLatest()
                        .mapToVoid()
                        .first()
                        .sink(receiveValue: completion)
                        .store(in: &strongSelf.cancellables)
                }
            }
            healthStore.execute(query)
            healthStore.enableBackgroundDelivery(for: sampleType)
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
