import Combine
import CombineExt
import ECKit
import Factory
import Foundation

// sourcery: AutoMockable
protocol EnvironmentManaging {
    var firestoreEnvironment: FirestoreEnvironment { get }
    var firestoreEnvironmentDidChange: AnyPublisher<Void, Never> { get }
    func set(_ environment: FirestoreEnvironment)
}

final class EnvironmentManager: EnvironmentManaging {
    
    private enum Constants {
        static var environmentKey: String { #function }
    }
    
    // MARK: - Public Properties
    
    var firestoreEnvironment: FirestoreEnvironment { firestoreEnvironmentSubject.value }
    let firestoreEnvironmentDidChange: AnyPublisher<Void, Never>
    
    // MARK: - Private Properties
    
    @Injected(\.environmentCache) private var environmentCache
    
    private let firestoreEnvironmentSubject: CurrentValueSubject<FirestoreEnvironment, Never>
    
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle
    
    init() {
        if let environment = UserDefaults.standard.decode(FirestoreEnvironment.self, forKey: Constants.environmentKey) {
            firestoreEnvironmentSubject = .init(environment)
        } else {
            #if targetEnvironment(simulator)
            firestoreEnvironmentSubject = .init(.init(type: .debug, emulationType: .localhost, emulationDestination: nil))
            #else
            firestoreEnvironmentSubject = .init(.default)
            #endif
        }
        
        firestoreEnvironmentDidChange = firestoreEnvironmentSubject
            .mapToVoid()
            .eraseToAnyPublisher()
        
        firestoreEnvironmentSubject
            .sink { UserDefaults.standard.encode($0, forKey: Constants.environmentKey) }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func set(_ environment: FirestoreEnvironment) {
        firestoreEnvironmentSubject.send(environment)
    }
}
