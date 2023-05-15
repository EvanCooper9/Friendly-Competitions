import Combine
import ECKit
import Factory
import Foundation

final class BackgroundNotificationAppService: AppService {

    private let jobTypes: [BackgroundJob.Type] = [FetchCompetitionBackgroundJob.self]
    private let decoder = JSONDecoder()

    func didReceiveRemoteNotification(with data: [AnyHashable: Any]) -> AnyPublisher<Void, Never> {
        guard let customData = data["customData"] as? [String: Any],
              let backgroundJob = customData["backgroundJob"],
              let data = try? JSONSerialization.data(withJSONObject: backgroundJob)
        else { return .just(()) }

        return jobTypes
            .compactMap { jobType -> AnyPublisher<Void, Never>? in
                guard let job = try? decoder.decode(jobType.self, from: data) else { return nil }
                return job.execute()
            }
            .combineLatest()
            .first()
            .mapToVoid()
            .eraseToAnyPublisher()
    }
}
