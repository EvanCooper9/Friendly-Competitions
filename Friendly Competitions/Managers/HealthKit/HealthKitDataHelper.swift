import Combine
import ECKit
import Factory
import Foundation
import UIKit

/// Facilitates triggers for fetching & uploading data from HealthKit
final class HealthKitDataHelper<Data> {
    
    typealias FetchClosure = (DateInterval) -> AnyPublisher<Data, Error>
    typealias UploadClosure = (Data) -> AnyPublisher<Void, Error>
    
    @Injected(Container.competitionsManager) private var competitionsManager
    @Injected(Container.healthKitManager) private var healthKitManager
    
    private var cancellables = Cancellables()
    
    init(fetch fetchClosure: @escaping FetchClosure, upload uploadClosure: @escaping UploadClosure) {
        let fetchAndUpload = PassthroughSubject<DateInterval, Error>()
        let fetchAndUploadFinished = PassthroughSubject<Void, Never>()
        
        fetchAndUpload
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .flatMapLatest(fetchClosure)
            .flatMapLatest(uploadClosure)
            .sink(receiveCompletion: { _ in }, receiveValue: { fetchAndUploadFinished.send() })
            .store(in: &cancellables)
        
        let backgroundDeliveryTrigger = Just(())
            .handleEvents(withUnretained: self, receiveSubscription: { strongSelf, _ in
                fetchAndUpload.send(strongSelf.competitionsManager.competitionsDateInterval)
            })
            .flatMapLatest { fetchAndUploadFinished }
            .eraseToAnyPublisher()
        
        healthKitManager.registerBackgroundDeliveryTask(backgroundDeliveryTrigger)
        
        Publishers
            .Merge(
                UIApplication.willEnterForegroundNotification.publisher
                    .map { [weak self] _ in self?.competitionsManager.competitionsDateInterval }
                    .unwrap(),
                competitionsManager.competitions
                    .filterMany(\.isActive)
                    .map(\.dateInterval)
            )
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink(receiveValue: { fetchAndUpload.send($0) })
            .store(in: &cancellables)
    }
}
