import Combine
import CombineExt
import ECKit
import Factory
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

    // MARK: - Private Properties

    @Injected(\.environmentManager) private var environmentManager

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
            .map { $0 == .debugRemote }
            .assign(to: &$showDestinationAlert)

        let fcEnvironment = Publishers
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

        saveSubject
            .withLatestFrom(fcEnvironment)
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
}
