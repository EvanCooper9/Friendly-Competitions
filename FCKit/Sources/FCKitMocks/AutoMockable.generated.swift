// Generated using Sourcery 2.0.3 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// swiftlint:disable line_length
// swiftlint:disable variable_name

import Foundation
#if os(iOS) || os(tvOS) || os(watchOS)
import UIKit
#elseif os(OSX)
import AppKit
#endif

import Combine
import FCKit























public class AnalyticsManagingMock: AnalyticsManaging {

    public init() {}



    //MARK: - set

    public var setUserIdCallsCount = 0
    public var setUserIdCalled: Bool {
        return setUserIdCallsCount > 0
    }
    public var setUserIdReceivedUserId: String?
    public var setUserIdReceivedInvocations: [String] = []
    public var setUserIdClosure: ((String) -> Void)?

    public func set(userId: String) {
        setUserIdCallsCount += 1
        setUserIdReceivedUserId = userId
        setUserIdReceivedInvocations.append(userId)
        setUserIdClosure?(userId)
    }

    //MARK: - log

    public var logEventCallsCount = 0
    public var logEventCalled: Bool {
        return logEventCallsCount > 0
    }
    public var logEventReceivedEvent: AnalyticsEvent?
    public var logEventReceivedInvocations: [AnalyticsEvent] = []
    public var logEventClosure: ((AnalyticsEvent) -> Void)?

    public func log(event: AnalyticsEvent) {
        logEventCallsCount += 1
        logEventReceivedEvent = event
        logEventReceivedInvocations.append(event)
        logEventClosure?(event)
    }

}
public class DatabaseMock: Database {

    public init() {}



    //MARK: - batch

    public var batchCallsCount = 0
    public var batchCalled: Bool {
        return batchCallsCount > 0
    }
    public var batchReturnValue: Batch!
    public var batchClosure: (() -> Batch)?

    public func batch() -> Batch {
        batchCallsCount += 1
        if let batchClosure = batchClosure {
            return batchClosure()
        } else {
            return batchReturnValue
        }
    }

    //MARK: - collection

    public var collectionCallsCount = 0
    public var collectionCalled: Bool {
        return collectionCallsCount > 0
    }
    public var collectionReceivedCollectionPath: String?
    public var collectionReceivedInvocations: [String] = []
    public var collectionReturnValue: Collection!
    public var collectionClosure: ((String) -> Collection)?

    public func collection(_ collectionPath: String) -> Collection {
        collectionCallsCount += 1
        collectionReceivedCollectionPath = collectionPath
        collectionReceivedInvocations.append(collectionPath)
        if let collectionClosure = collectionClosure {
            return collectionClosure(collectionPath)
        } else {
            return collectionReturnValue
        }
    }

    //MARK: - collectionGroup

    public var collectionGroupCallsCount = 0
    public var collectionGroupCalled: Bool {
        return collectionGroupCallsCount > 0
    }
    public var collectionGroupReceivedCollectionGroupID: String?
    public var collectionGroupReceivedInvocations: [String] = []
    public var collectionGroupReturnValue: Collection!
    public var collectionGroupClosure: ((String) -> Collection)?

    public func collectionGroup(_ collectionGroupID: String) -> Collection {
        collectionGroupCallsCount += 1
        collectionGroupReceivedCollectionGroupID = collectionGroupID
        collectionGroupReceivedInvocations.append(collectionGroupID)
        if let collectionGroupClosure = collectionGroupClosure {
            return collectionGroupClosure(collectionGroupID)
        } else {
            return collectionGroupReturnValue
        }
    }

    //MARK: - document

    public var documentCallsCount = 0
    public var documentCalled: Bool {
        return documentCallsCount > 0
    }
    public var documentReceivedDocumentPath: String?
    public var documentReceivedInvocations: [String] = []
    public var documentReturnValue: Document!
    public var documentClosure: ((String) -> Document)?

    public func document(_ documentPath: String) -> Document {
        documentCallsCount += 1
        documentReceivedDocumentPath = documentPath
        documentReceivedInvocations.append(documentPath)
        if let documentClosure = documentClosure {
            return documentClosure(documentPath)
        } else {
            return documentReturnValue
        }
    }

}
public class DatabaseSettingManagingMock: DatabaseSettingManaging {

    public init() {}

    public var shouldResetCache: Bool {
        get { return underlyingShouldResetCache }
        set(value) { underlyingShouldResetCache = value }
    }
    public var underlyingShouldResetCache: Bool!


    //MARK: - didResetCache

    public var didResetCacheCallsCount = 0
    public var didResetCacheCalled: Bool {
        return didResetCacheCallsCount > 0
    }
    public var didResetCacheClosure: (() -> Void)?

    public func didResetCache() {
        didResetCacheCallsCount += 1
        didResetCacheClosure?()
    }

}
public class EnvironmentCacheMock: EnvironmentCache {

    public init() {}

    public var environment: FCEnvironment?


}
public class EnvironmentManagingMock: EnvironmentManaging {

    public init() {}

    public var environment: FCEnvironment {
        get { return underlyingEnvironment }
        set(value) { underlyingEnvironment = value }
    }
    public var underlyingEnvironment: FCEnvironment!
    public var environmentPublisher: AnyPublisher<FCEnvironment, Never> {
        get { return underlyingEnvironmentPublisher }
        set(value) { underlyingEnvironmentPublisher = value }
    }
    public var underlyingEnvironmentPublisher: AnyPublisher<FCEnvironment, Never>!


    //MARK: - set

    public var setCallsCount = 0
    public var setCalled: Bool {
        return setCallsCount > 0
    }
    public var setReceivedEnvironment: FCEnvironment?
    public var setReceivedInvocations: [FCEnvironment] = []
    public var setClosure: ((FCEnvironment) -> Void)?

    public func set(_ environment: FCEnvironment) {
        setCallsCount += 1
        setReceivedEnvironment = environment
        setReceivedInvocations.append(environment)
        setClosure?(environment)
    }

}
public class FeatureFlagManagingMock: FeatureFlagManaging {

    public init() {}



    //MARK: - value

    public var valueForBoolCallsCount = 0
    public var valueForBoolCalled: Bool {
        return valueForBoolCallsCount > 0
    }
    public var valueForBoolReceivedFeatureFlagBool: FeatureFlagBool?
    public var valueForBoolReceivedInvocations: [FeatureFlagBool] = []
    public var valueForBoolReturnValue: Bool!
    public var valueForBoolClosure: ((FeatureFlagBool) -> Bool)?

    public func value(forBool featureFlagBool: FeatureFlagBool) -> Bool {
        valueForBoolCallsCount += 1
        valueForBoolReceivedFeatureFlagBool = featureFlagBool
        valueForBoolReceivedInvocations.append(featureFlagBool)
        if let valueForBoolClosure = valueForBoolClosure {
            return valueForBoolClosure(featureFlagBool)
        } else {
            return valueForBoolReturnValue
        }
    }

    //MARK: - value

    public var valueForDoubleCallsCount = 0
    public var valueForDoubleCalled: Bool {
        return valueForDoubleCallsCount > 0
    }
    public var valueForDoubleReceivedFeatureFlagDouble: FeatureFlagDouble?
    public var valueForDoubleReceivedInvocations: [FeatureFlagDouble] = []
    public var valueForDoubleReturnValue: Double!
    public var valueForDoubleClosure: ((FeatureFlagDouble) -> Double)?

    public func value(forDouble featureFlagDouble: FeatureFlagDouble) -> Double {
        valueForDoubleCallsCount += 1
        valueForDoubleReceivedFeatureFlagDouble = featureFlagDouble
        valueForDoubleReceivedInvocations.append(featureFlagDouble)
        if let valueForDoubleClosure = valueForDoubleClosure {
            return valueForDoubleClosure(featureFlagDouble)
        } else {
            return valueForDoubleReturnValue
        }
    }

}
