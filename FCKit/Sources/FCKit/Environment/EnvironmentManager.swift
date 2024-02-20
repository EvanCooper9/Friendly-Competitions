import Combine
import CombineExt
import ECKit
import Factory
import Foundation

// sourcery: AutoMockable
public protocol EnvironmentManaging {
    var environment: FCEnvironment { get }
    var environmentPublisher: AnyPublisher<FCEnvironment, Never> { get }
    func set(_ environment: FCEnvironment)
}

final class EnvironmentManager: EnvironmentManaging {

    private enum Constants {
        static var environmentKey: String { #function }
    }

    // MARK: - Public Properties

    var environment: FCEnvironment {
        environmentSubject.value
    }

    var environmentPublisher: AnyPublisher<FCEnvironment, Never> {
        environmentSubject.eraseToAnyPublisher()
    }

    // MARK: - Private Properties

    @Injected(\.environmentCache) private var environmentCache

    private let environmentSubject = CurrentValueSubject<FCEnvironment, Never>(.prod)
    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {
        if let environment = environmentCache.environment {
            environmentSubject.send(environment)
        } else {
            #if targetEnvironment(simulator)
            environmentSubject.send(.debugLocal)
            #endif
        }

        environmentSubject
            .sink(withUnretained: self) { $0.environmentCache.environment = $1 }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func set(_ environment: FCEnvironment) {
        environmentSubject.send(environment)
    }
}
