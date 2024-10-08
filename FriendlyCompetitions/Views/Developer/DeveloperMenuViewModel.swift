import Combine
import CombineExt
import ECKit
import Factory
import FCKit
import Foundation

final class DeveloperMenuViewModel: ObservableObject {

    enum UnderlyingEnvironment: String, CaseIterable, Identifiable {
        case prod = "Prod"
        case debugLocal = "Debug Local"
        case debugRemote = "Debug Remote"

        var id: RawValue { rawValue }

        init(from environment: FCEnvironment) {
            switch environment {
            case .prod:
                self = .prod
            case .debugLocal:
                self = .debugLocal
            case .debugRemote:
                self = .debugRemote
            }
        }
    }

    // MARK: - Public Properties

    @Published var environment: UnderlyingEnvironment = .prod
    @Published var showDestinationAlert = false
    @Published var destination = ""
    @Published var showFeatureFlag = false

    // MARK: - Private Properties

    @Injected(\.environmentManager) private var environmentManager: EnvironmentManaging

    private let saveSubject = PassthroughSubject<Void, Never>()

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        environment = .init(from: environmentManager.environment)
        switch environmentManager.environment {
        case .prod, .debugLocal:
            break
        case .debugRemote(let destination):
            self.destination = destination
        }

        $environment
            .dropFirst()
            .map { $0 == .debugRemote }
            .assign(to: &$showDestinationAlert)

        Publishers
            .CombineLatest($environment, $destination)
            .map { environment, destination -> FCEnvironment in
                switch environment {
                case .prod:
                    return .prod
                case .debugLocal:
                    return .debugLocal
                case .debugRemote:
                    return .debugRemote(destination: destination)
                }
            }
            .dropFirst()
            .sink(withUnretained: self) { $0.environmentManager.set($1) }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func saveTapped() {
        saveSubject.send()
    }

    func text(for environment: UnderlyingEnvironment) -> String {
        var text = environment.rawValue
        if environment == .debugRemote, !destination.isEmpty {
            text += " (\(destination))"
        }
        return text
    }

    func featureFlagButtonTapped() {
        showFeatureFlag = true
    }
}
