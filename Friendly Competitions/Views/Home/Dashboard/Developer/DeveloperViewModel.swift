import Combine
import CombineExt
import ECKit
import Factory

struct FirestoreEnvironment: Codable {

    let type: EnvironmentType
    let emulationType: EmulationType
    let emulationDestination: String?

    static var defaultEnvionment: Self {
        .init(type: .prod, emulationType: .localhost, emulationDestination: "localhost")
    }

    enum EnvironmentType: String, CaseIterable, Codable, Hashable, Identifiable {
        case prod
        case debug

        var id: String { rawValue }
    }

    enum EmulationType: String, CaseIterable, Codable, Hashable, Identifiable {
        case localhost
        case custom

        var id: String { rawValue }
    }
}

final class DeveloperViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published var environment: FirestoreEnvironment.EnvironmentType = .prod
    @Published var emulation: FirestoreEnvironment.EmulationType = .localhost
    @Published var emulationDestination = "localhost"

    // MARK: - Private Properties

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        if let environment = UserDefaults.standard.decode(FirestoreEnvironment.self, forKey: "environment") {
            self.environment = environment.type
            self.emulation = environment.emulationType
            self.emulationDestination = environment.emulationDestination ?? "localhost"
        }

        Publishers
            .CombineLatest3($environment, $emulation, $emulationDestination)
            .map { environment, emulation, emulationDestination in
                FirestoreEnvironment(
                    type: environment,
                    emulationType: emulation,
                    emulationDestination: emulationDestination
                )
            }
            .sink { environment in
                UserDefaults.standard.encode(environment, forKey: "environment")
//                Resolver.registerFirebase(environment: environment)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods
}
