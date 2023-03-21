import Combine
import ECKit
import Factory
import Foundation
import UIKit

protocol HealthKitDataHelping {
    associatedtype Data
    typealias FetchClosure = (DateInterval) -> AnyPublisher<Data, Error>
    typealias UploadClosure = (Data) -> AnyPublisher<Void, Error>
    
    init(fetch fetchClosure: @escaping FetchClosure, upload uploadClosure: @escaping UploadClosure)
}

/// Facilitates triggers for fetching & uploading data from HealthKit
final class HealthKitDataHelper<Data> {
    
    typealias FetchClosure = (DateInterval) -> AnyPublisher<Data, Error>
    typealias UploadClosure = (Data) -> AnyPublisher<Void, Error>
    
    // MARK: - Private Properties
    
    @Injected(\.competitionsManager) private var competitionsManager
    @Injected(\.healthKitManager) private var healthKitManager
    @Injected(\.scheduler) private var scheduler
    
    private let fetchAndUpload = PassthroughSubject<DateInterval, Never>()
    private let fetchAndUploadFinished = PassthroughSubject<Void, Never>()
    
    private var cancellables = Cancellables()
    
    // MARK: - Lifecycle
    
    init(fetch fetchClosure: @escaping FetchClosure, upload uploadClosure: @escaping UploadClosure) {
        
        // Ignore errors from fetchClosure & uploadClosure so that finished is still trigered
        fetchAndUpload
            .debounce(for: .seconds(1), scheduler: scheduler)
            .flatMapLatest { dateInterval -> AnyPublisher<Data?, Never> in
                fetchClosure(dateInterval)
                    .map { $0 as Data? }
                    .catchErrorJustReturn(nil)
            }
            .flatMapLatest { data -> AnyPublisher<Void, Never> in
                guard let data else { return .just(()) }
                return uploadClosure(data).catchErrorJustReturn(())
            }
            .mapToVoid()
            .sink(withUnretained: self, receiveValue: { $0.fetchAndUploadFinished.send() })
            .store(in: &cancellables)
        
        Publishers
            .Merge(
                UIApplication.willEnterForegroundNotification.publisher
                    .map { [weak self] _ in self?.competitionsManager.competitionsDateInterval }
                    .unwrap(),
                competitionsManager.competitions
                    .filterMany(\.isActive)
                    .map(\.dateInterval)
            )
            .sink(withUnretained: self, receiveValue: { $0.fetchAndUpload.send($1) })
            .store(in: &cancellables)
        
        registerForBackgroundDelivery()
    }
    
    // MARK: - Private Methods
    
    private func registerForBackgroundDelivery() {
        let backgroundDeliveryTrigger: AnyPublisher<Void, Never> = .just(())
            .handleEvents(withUnretained: self, receiveSubscription: { strongSelf, _ in
                strongSelf.fetchAndUpload.send(strongSelf.competitionsManager.competitionsDateInterval)
            })
            .flatMapLatest(withUnretained: self) { $0.fetchAndUploadFinished.eraseToAnyPublisher() }
            .eraseToAnyPublisher()
        
        healthKitManager.registerBackgroundDeliveryTask(backgroundDeliveryTrigger)
    }
}
