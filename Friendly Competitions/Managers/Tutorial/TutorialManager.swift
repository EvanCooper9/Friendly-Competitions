import Combine
import ECKit
import Foundation

// sourcery: AutoMockable
protocol TutorialManaging {
    var remainingSteps: AnyPublisher<[TutorialStep], Never> { get }
    
    func complete(step: TutorialStep)
}

final class TutorialManager: TutorialManaging {
    
    // MARK: - Public Properties
    
    let remainingSteps: AnyPublisher<[TutorialStep], Never>
    
    // MARK: - Private Properties
    
    private let remainingStepsSubject: CurrentValueSubject<[TutorialStep], Never>
    private let cancellables = Cancellables()
    
    // MARK: - Lifecycle
    
    init() {
        let completedSteps = UserDefaults.standard.decode([TutorialStep].self, forKey: "tutorial_steps") ?? []
        let remainingSteps = TutorialStep.allCases.filter { !completedSteps.contains($0) }
        
        remainingStepsSubject = .init(remainingSteps)
        self.remainingSteps = remainingStepsSubject
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Public Methods
    
    func complete(step: TutorialStep) {
        var remainingSteps = remainingStepsSubject.value
        remainingSteps.remove(step)
        remainingStepsSubject.send(remainingSteps)
    }
}
