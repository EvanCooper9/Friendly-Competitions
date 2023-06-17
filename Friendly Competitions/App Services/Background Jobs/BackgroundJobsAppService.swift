import Combine
import ECKit
import Factory
import Foundation

final class BackgroundJobsAppService: AppService {

    private enum Constants {
        static let customDataKey = "customData"
        static let backgroundJobKey = "backgroundJob"
    }

    private let jobTypes: [BackgroundJob.Type] = [
        FetchDocumentBackgroundJob.self,
        FetchCompetitionResultsBackgroundJob.self
    ]

    private let decoder = JSONDecoder()

    @Injected(\.analyticsManager) private var analyticsManager

    func didReceiveRemoteNotification(with data: [AnyHashable: Any]) -> AnyPublisher<Void, Never> {
        analyticsManager.log(event: .backgroundNotificationReceived)
        
        guard let customData = data[Constants.customDataKey] as? [String: Any],
              let backgroundJob = customData[Constants.backgroundJobKey] as? [String: Any],
              let data = try? JSONSerialization.data(withJSONObject: backgroundJob)
        else {
            analyticsManager.log(event: .backgroundNotificationFailedToParseJob)
            return .just(())
        }

        let codableJob = backgroundJob.compactMapValues { $0 as? String }
        analyticsManager.log(event: .backgroundJobReceived(job: codableJob))

        analyticsManager.log(event: .backgroundJobReceived(job: backgroundJob))

        return jobTypes
            .compactMap { jobType -> AnyPublisher<Void, Never>? in
                guard let job = try? decoder.decode(jobType.self, from: data) else { return nil }
                analyticsManager.log(event: .backgroundJobStarted(jobType: String(describing: jobType)))
                return job.execute()
                    .handleEvents(withUnretained: self,
                                  receiveSubscription: { strongSelf, _ in strongSelf.analyticsManager.log(event: .backgroundJobStarted(jobType: String(describing: jobType))) },
                                  receiveOutput: { $0.analyticsManager.log(event: .backgroundJobEnded(jobType: String(describing: jobType))) })
                    .eraseToAnyPublisher()
            }
            .combineLatest()
            .first()
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}
