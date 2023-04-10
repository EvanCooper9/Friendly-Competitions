import ECKit
import Factory
import UIKit

final class DeveloperAppService: AppService {

    @Injected(\.api) private var api

    private var cancellables = Cancellables()

    func didFinishLaunching() {
        #if DEBUG
//        forceCompetitionComplete()
        #endif
    }

    // MARK: - Private Methods

    private func forceCompetitionComplete() {
        api.call("dev_sendCompetitionCompleteNotification", with: ["date": "2023-05-19"])
            .sink()
            .store(in: &cancellables)
    }
}
