import Combine
import CombineExt
import ECKit
import Factory
import Foundation

final class ReportIssueViewModel: ObservableObject {

    // MARK: - Public Properties

    @Published var title = ""
    @Published var description = ""
    var submitDisabled: Bool { title.isEmpty || description.isEmpty }

    @Published var showSuccess = false
    @Published var loading = false
    @Published var error: Error?

    // MARK: - Private Properties

    @Injected(\.issueReporter) private var issueReporter: IssueReporting

    private var cancellables = Cancellables()

    // MARK: - Lifecycle

    init() {}

    // MARK: - Public Methods

    func submit() {
        issueReporter
            .report(title: title, description: description)
            .eraseToAnyPublisher()
            .isLoading(set: \.loading, on: self)
            .materialize()
            .sink(receiveValue: { [weak self] event in
                guard let self else { return }
                switch event {
                case .failure(let error):
                    self.error = error
                case .value, .finished:
                    showSuccess = true
                }
            })
            .store(in: &cancellables)
    }
}
