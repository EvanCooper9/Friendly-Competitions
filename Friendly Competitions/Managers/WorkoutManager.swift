import Combine
import Firebase
import FirebaseFirestore
import HealthKit
import Resolver

protocol WorkoutManaging {
    func update() -> AnyPublisher<Void, Error>
}

final class WorkoutManager: WorkoutManaging {
    
    @Injected private var competitionsManager: CompetitionsManaging
    @Injected private var healthKitManager: HealthKitManaging
    @Injected private var userManager: UserManaging
    @Injected private var database: Firestore
    
    private let query = PassthroughSubject<Void, Never>()

    private let uploadFinished = PassthroughSubject<Void, Error>()
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Publishers
            .Merge(healthKitManager.backgroundDeliveryReceived, query)
            .prepend(())
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .flatMapLatest(requestWorkouts)
            .filter(\.isNotEmpty)
            .combineLatest(userManager.user)
            .sinkAsync { [weak self] workouts, user in
                guard let self = self else { return }
                let batch = self.database.batch()
                try workouts.forEach { workout in
                    let document = self.database.document("users/\(user.id)/workouts/\(workout.id)")
                    _ = try batch.setDataEncodable(workout, forDocument: document)
                }
                try await batch.commit()
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    func update() -> AnyPublisher<Void, Error> {
        uploadFinished
            .handleEvents(receiveSubscription: { [weak self] _ in self?.query.send() })
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods

    private func requestWorkouts() -> AnyPublisher<[Workout], Never> {
        competitionsManager.competitions
            .compactMapMany(\.workoutType?.hkWorkoutActivityType)
            .flatMapAsync { workoutTypes in
                let totalPoints = try await withThrowingTaskGroup(of: (HKWorkoutActivityType, [HKQuantityType: [Date: Double]]).self) { group -> [HKWorkoutActivityType: [HKQuantityType: [Date: Double]]] in
                    workoutTypes.forEach { workoutType in
                        group.addTask { [weak self] in
                            guard let self = self else { return (workoutType, [:]) }
                            let points = try await self.requestWorkouts(ofType: workoutType)
                            return (workoutType, points)
                        }
                    }

                    var toReturn = [HKWorkoutActivityType: [HKQuantityType: [Date: Double]]]()
                    for try await (workoutType, points) in group {
                        toReturn[workoutType] = points
                    }
                    return toReturn
                }

                let workouts = totalPoints.flatMap { workoutType, pointsBySampleTypeByDate in
                    pointsBySampleTypeByDate.flatMap { sampleType, pointsByDate in
                        pointsByDate.compactMap { date, points -> Workout? in
                            guard let workoutType = WorkoutType(hkWorkoutActivityType: workoutType) else { return nil }
                            return Workout(
                                type: workoutType,
                                date: date,
                                points: Int(points)
                            )
                        }
                    }
                }
                return workouts
            }
            .ignoreFailure()
    }
    
    private func requestWorkouts(ofType workoutType: HKWorkoutActivityType) async throws -> [HKQuantityType: [Date: Double]] {
        let sampleType = HKSampleType.workoutType()
        let predicate = HKQuery.predicateForWorkouts(with: workoutType)
        let startDateSort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let workouts = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKWorkout], Error>) in
            let query = HKSampleQuery(sampleType: sampleType, predicate: predicate, limit: 0, sortDescriptors: [startDateSort]) { _, workouts, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let workouts = workouts?
                    .compactMap { $0 as? HKWorkout }
                    .filter { $0.endDate.compare(.now.advanced(by: -5.days)) == .orderedDescending }
                
                continuation.resume(returning: workouts ?? [])
            }
            healthKitManager.execute(query)
        }
        
        return try await withThrowingTaskGroup(of: [HKQuantityType: [Date: Double]].self) { group -> [HKQuantityType: [Date: Double]] in
            workouts.forEach { workout in
                group.addTask { [weak self] in
                    guard let self = self else { return [:] }
                    return try await self.pointsByDateBySample(for: workout)
                }
            }
            
            var toReturn = [HKQuantityType: [Date: Double]]()
            for try await pointsByDateBySample in group {
                pointsByDateBySample.forEach { sampleType, pointsByDate in
                    if let existing = toReturn[sampleType] {
                        toReturn[sampleType] = pointsByDate.reduce(into: existing) { partialResult, next in
                            partialResult[next.key] = (partialResult[next.key] ?? 0) + next.value
                        }
                    } else {
                        toReturn[sampleType] = pointsByDate
                    }
                }
            }
            return toReturn
        }
    }
    
    /// Get the total points by date for all sample types of a given workout
    /// - Parameter workout: The workout to fetch the points for
    /// - Throws: Any errors from  HealthKit
    /// - Returns: Points by date by sample type
    private func pointsByDateBySample(for workout: HKWorkout) async throws -> [HKQuantityType: [Date: Double]] {
        try await withThrowingTaskGroup(of: (HKQuantityType, [Date: Double]).self) { group -> [HKQuantityType: [Date: Double]] in
            workout.workoutActivityType.samples.forEach { sample, unit in
                group.addTask { [weak self] in
                    guard let self = self else { return (sample, [:]) }
                    let pointsByDate = try await self.pointsByDate(sampleType: sample, workout: workout, unit: unit)
                    return (sample, pointsByDate)
                }
            }
            
            var toReturn = [HKQuantityType: [Date: Double]]()
            for try await (sampleType, pointsByDate) in group {
                guard let existing = toReturn[sampleType] else {
                    toReturn[sampleType] = pointsByDate
                    continue
                }
                
                toReturn[sampleType] = pointsByDate.reduce(into: existing) { partialResult, next in
                    partialResult[next.key] = (partialResult[next.key] ?? 0) + next.value
                }
            }
            return toReturn
        }
    }
    
    /// Get the total points by date for a given workout and sample type
    /// - Parameters:
    ///   - sampleType: The sample type to fetch the points for
    ///   - workout: The workout to fetch the points for
    ///   - unit: The unit
    /// - Throws: Any errors from HealthKit
    /// - Returns: Points by date
    private func pointsByDate(sampleType: HKQuantityType, workout: HKWorkout, unit: HKUnit) async throws -> [Date: Double] {
        // https://developer.apple.com/documentation/healthkit/workouts_and_activity_rings/adding_samples_to_a_workout
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[Date: Double], Error>)  in
            let query = HKSampleQuery(sampleType: sampleType, predicate: predicate,limit: 0, sortDescriptors: nil) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples else { return }
                let total = samples
                    .compactMap { $0 as? HKQuantitySample }
                    .reduce(into: [Date: Double]()) { partialResult, sample in
                        let dateNoTime = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: sample.endDate)!
                        partialResult[dateNoTime] = (partialResult[dateNoTime] ?? 0) + sample.quantity.doubleValue(for: unit)
                    }
                
                continuation.resume(returning: total)
            }
            healthKitManager.execute(query)
        }
    }
}
