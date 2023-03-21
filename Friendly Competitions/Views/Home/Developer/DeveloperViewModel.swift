import Combine
import CombineExt
import ECKit
import Factory
import Foundation



final class DeveloperViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published var environmentType: FirestoreEnvironment.EnvironmentType = .prod
    @Published var environmentEmulationType: FirestoreEnvironment.EmulationType = .localhost
    @Published var emulationDestination = "localhost"

    // MARK: - Private Properties
    
    @Injected(\.environmentManager) private var environmentManager
    
    private let saveSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        environmentType = environmentManager.firestoreEnvironment.type
        environmentEmulationType = environmentManager.firestoreEnvironment.emulationType
        emulationDestination = environmentManager.firestoreEnvironment.emulationDestination ?? "localhost"
        
        let environment = Publishers
            .CombineLatest3($environmentType, $environmentEmulationType, $emulationDestination)
            .map { environment, emulation, emulationDestination in
                FirestoreEnvironment(
                    type: environment,
                    emulationType: emulation,
                    emulationDestination: emulationDestination
                )
            }
        
        saveSubject
            .withLatestFrom(environment)
            .sink(withUnretained: self) { $0.environmentManager.set($1) }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func saveTapped() {
        saveSubject.send()
    }
}
