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
    
    // MARK: - Public Properties
    
    var firestoreEnvironment: FirestoreEnvironment { firestoreEnvironmentSubject.value }
    
    let firestoreEnvironmentDidChange: AnyPublisher<Void, Never>
    
    // MARK: - Private Properties
    
    private let firestoreEnvironmentSubject: CurrentValueSubject<FirestoreEnvironment, Never>
    
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle
    
    init() {
        if let environment = UserDefaults.standard.decode(FirestoreEnvironment.self, forKey: "environment") {
            firestoreEnvironmentSubject = .init(environment)
        } else {
            firestoreEnvironmentSubject = .init(.defaultEnvionment)
        }
        
        firestoreEnvironmentDidChange = firestoreEnvironmentSubject
            .mapToVoid()
            .eraseToAnyPublisher()
        
        firestoreEnvironmentSubject
            .sink { UserDefaults.standard.encode($0, forKey: "environment") }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func set(_ environment: FirestoreEnvironment) {
        firestoreEnvironmentSubject.send(environment)
    }
}
