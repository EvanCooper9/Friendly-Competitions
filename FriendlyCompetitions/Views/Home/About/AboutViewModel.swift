import Combine
import Foundation
import Factory

final class AboutViewModel: ObservableObject {

    // MARK: - Public

    private(set) var bugReportURL: URL!
    private(set) var featureRequestURL: URL!

    // MARK: - Private

    @Injected(\.userManager) private var userManager

    // MARK: - Lifecycle

    init() {
        bugReportURL = URL.bugReport(with: userManager.user.id)
        featureRequestURL = URL.featureRequest(with: userManager.user.id)
    }
}
