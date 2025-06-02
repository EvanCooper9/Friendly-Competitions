// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
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

    public var events: [AnalyticEventWrapper] = []


    //MARK: - set

    public var setUserIdStringVoidCallsCount = 0
    public var setUserIdStringVoidCalled: Bool {
        return setUserIdStringVoidCallsCount > 0
    }
    public var setUserIdStringVoidReceivedUserId: (String)?
    public var setUserIdStringVoidReceivedInvocations: [(String)] = []
    public var setUserIdStringVoidClosure: ((String) -> Void)?

    public func set(userId: String) {
        setUserIdStringVoidCallsCount += 1
        setUserIdStringVoidReceivedUserId = userId
        setUserIdStringVoidReceivedInvocations.append(userId)
        setUserIdStringVoidClosure?(userId)
    }

    //MARK: - log

    public var logEventAnalyticsEventVoidCallsCount = 0
    public var logEventAnalyticsEventVoidCalled: Bool {
        return logEventAnalyticsEventVoidCallsCount > 0
    }
    public var logEventAnalyticsEventVoidReceivedEvent: (AnalyticsEvent)?
    public var logEventAnalyticsEventVoidReceivedInvocations: [(AnalyticsEvent)] = []
    public var logEventAnalyticsEventVoidClosure: ((AnalyticsEvent) -> Void)?

    public func log(event: AnalyticsEvent) {
        logEventAnalyticsEventVoidCallsCount += 1
        logEventAnalyticsEventVoidReceivedEvent = event
        logEventAnalyticsEventVoidReceivedInvocations.append(event)
        logEventAnalyticsEventVoidClosure?(event)
    }


}
public class DatabaseMock: Database {

    public init() {}



    //MARK: - batch

    public var batchBatchCallsCount = 0
    public var batchBatchCalled: Bool {
        return batchBatchCallsCount > 0
    }
    public var batchBatchReturnValue: Batch!
    public var batchBatchClosure: (() -> Batch)?

    public func batch() -> Batch {
        batchBatchCallsCount += 1
        if let batchBatchClosure = batchBatchClosure {
            return batchBatchClosure()
        } else {
            return batchBatchReturnValue
        }
    }

    //MARK: - collection

    public var collectionCollectionPathStringCollectionCallsCount = 0
    public var collectionCollectionPathStringCollectionCalled: Bool {
        return collectionCollectionPathStringCollectionCallsCount > 0
    }
    public var collectionCollectionPathStringCollectionReceivedCollectionPath: (String)?
    public var collectionCollectionPathStringCollectionReceivedInvocations: [(String)] = []
    public var collectionCollectionPathStringCollectionReturnValue: Collection!
    public var collectionCollectionPathStringCollectionClosure: ((String) -> Collection)?

    public func collection(_ collectionPath: String) -> Collection {
        collectionCollectionPathStringCollectionCallsCount += 1
        collectionCollectionPathStringCollectionReceivedCollectionPath = collectionPath
        collectionCollectionPathStringCollectionReceivedInvocations.append(collectionPath)
        if let collectionCollectionPathStringCollectionClosure = collectionCollectionPathStringCollectionClosure {
            return collectionCollectionPathStringCollectionClosure(collectionPath)
        } else {
            return collectionCollectionPathStringCollectionReturnValue
        }
    }

    //MARK: - collectionGroup

    public var collectionGroupCollectionGroupIDStringCollectionCallsCount = 0
    public var collectionGroupCollectionGroupIDStringCollectionCalled: Bool {
        return collectionGroupCollectionGroupIDStringCollectionCallsCount > 0
    }
    public var collectionGroupCollectionGroupIDStringCollectionReceivedCollectionGroupID: (String)?
    public var collectionGroupCollectionGroupIDStringCollectionReceivedInvocations: [(String)] = []
    public var collectionGroupCollectionGroupIDStringCollectionReturnValue: Collection!
    public var collectionGroupCollectionGroupIDStringCollectionClosure: ((String) -> Collection)?

    public func collectionGroup(_ collectionGroupID: String) -> Collection {
        collectionGroupCollectionGroupIDStringCollectionCallsCount += 1
        collectionGroupCollectionGroupIDStringCollectionReceivedCollectionGroupID = collectionGroupID
        collectionGroupCollectionGroupIDStringCollectionReceivedInvocations.append(collectionGroupID)
        if let collectionGroupCollectionGroupIDStringCollectionClosure = collectionGroupCollectionGroupIDStringCollectionClosure {
            return collectionGroupCollectionGroupIDStringCollectionClosure(collectionGroupID)
        } else {
            return collectionGroupCollectionGroupIDStringCollectionReturnValue
        }
    }

    //MARK: - document

    public var documentDocumentPathStringDocumentCallsCount = 0
    public var documentDocumentPathStringDocumentCalled: Bool {
        return documentDocumentPathStringDocumentCallsCount > 0
    }
    public var documentDocumentPathStringDocumentReceivedDocumentPath: (String)?
    public var documentDocumentPathStringDocumentReceivedInvocations: [(String)] = []
    public var documentDocumentPathStringDocumentReturnValue: Document!
    public var documentDocumentPathStringDocumentClosure: ((String) -> Document)?

    public func document(_ documentPath: String) -> Document {
        documentDocumentPathStringDocumentCallsCount += 1
        documentDocumentPathStringDocumentReceivedDocumentPath = documentPath
        documentDocumentPathStringDocumentReceivedInvocations.append(documentPath)
        if let documentDocumentPathStringDocumentClosure = documentDocumentPathStringDocumentClosure {
            return documentDocumentPathStringDocumentClosure(documentPath)
        } else {
            return documentDocumentPathStringDocumentReturnValue
        }
    }


}
public class DatabaseSettingManagingMock: DatabaseSettingManaging {

    public init() {}

    public var shouldResetCache: Bool {
        get { return underlyingShouldResetCache }
        set(value) { underlyingShouldResetCache = value }
    }
    public var underlyingShouldResetCache: (Bool)!


    //MARK: - didResetCache

    public var didResetCacheVoidCallsCount = 0
    public var didResetCacheVoidCalled: Bool {
        return didResetCacheVoidCallsCount > 0
    }
    public var didResetCacheVoidClosure: (() -> Void)?

    public func didResetCache() {
        didResetCacheVoidCallsCount += 1
        didResetCacheVoidClosure?()
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
    public var underlyingEnvironment: (FCEnvironment)!
    public var environmentPublisher: AnyPublisher<FCEnvironment, Never> {
        get { return underlyingEnvironmentPublisher }
        set(value) { underlyingEnvironmentPublisher = value }
    }
    public var underlyingEnvironmentPublisher: (AnyPublisher<FCEnvironment, Never>)!


    //MARK: - set

    public var setEnvironmentFCEnvironmentVoidCallsCount = 0
    public var setEnvironmentFCEnvironmentVoidCalled: Bool {
        return setEnvironmentFCEnvironmentVoidCallsCount > 0
    }
    public var setEnvironmentFCEnvironmentVoidReceivedEnvironment: (FCEnvironment)?
    public var setEnvironmentFCEnvironmentVoidReceivedInvocations: [(FCEnvironment)] = []
    public var setEnvironmentFCEnvironmentVoidClosure: ((FCEnvironment) -> Void)?

    public func set(_ environment: FCEnvironment) {
        setEnvironmentFCEnvironmentVoidCallsCount += 1
        setEnvironmentFCEnvironmentVoidReceivedEnvironment = environment
        setEnvironmentFCEnvironmentVoidReceivedInvocations.append(environment)
        setEnvironmentFCEnvironmentVoidClosure?(environment)
    }


}
public class FeatureFlagManagingMock: FeatureFlagManaging {

    public init() {}



    //MARK: - value

    public var valueForBoolFeatureFlagFeatureFlagBoolBoolCallsCount = 0
    public var valueForBoolFeatureFlagFeatureFlagBoolBoolCalled: Bool {
        return valueForBoolFeatureFlagFeatureFlagBoolBoolCallsCount > 0
    }
    public var valueForBoolFeatureFlagFeatureFlagBoolBoolReceivedFeatureFlag: (FeatureFlagBool)?
    public var valueForBoolFeatureFlagFeatureFlagBoolBoolReceivedInvocations: [(FeatureFlagBool)] = []
    public var valueForBoolFeatureFlagFeatureFlagBoolBoolReturnValue: Bool!
    public var valueForBoolFeatureFlagFeatureFlagBoolBoolClosure: ((FeatureFlagBool) -> Bool)?

    public func value(forBool featureFlag: FeatureFlagBool) -> Bool {
        valueForBoolFeatureFlagFeatureFlagBoolBoolCallsCount += 1
        valueForBoolFeatureFlagFeatureFlagBoolBoolReceivedFeatureFlag = featureFlag
        valueForBoolFeatureFlagFeatureFlagBoolBoolReceivedInvocations.append(featureFlag)
        if let valueForBoolFeatureFlagFeatureFlagBoolBoolClosure = valueForBoolFeatureFlagFeatureFlagBoolBoolClosure {
            return valueForBoolFeatureFlagFeatureFlagBoolBoolClosure(featureFlag)
        } else {
            return valueForBoolFeatureFlagFeatureFlagBoolBoolReturnValue
        }
    }

    //MARK: - value

    public var valueForDoubleFeatureFlagFeatureFlagDoubleDoubleCallsCount = 0
    public var valueForDoubleFeatureFlagFeatureFlagDoubleDoubleCalled: Bool {
        return valueForDoubleFeatureFlagFeatureFlagDoubleDoubleCallsCount > 0
    }
    public var valueForDoubleFeatureFlagFeatureFlagDoubleDoubleReceivedFeatureFlag: (FeatureFlagDouble)?
    public var valueForDoubleFeatureFlagFeatureFlagDoubleDoubleReceivedInvocations: [(FeatureFlagDouble)] = []
    public var valueForDoubleFeatureFlagFeatureFlagDoubleDoubleReturnValue: Double!
    public var valueForDoubleFeatureFlagFeatureFlagDoubleDoubleClosure: ((FeatureFlagDouble) -> Double)?

    public func value(forDouble featureFlag: FeatureFlagDouble) -> Double {
        valueForDoubleFeatureFlagFeatureFlagDoubleDoubleCallsCount += 1
        valueForDoubleFeatureFlagFeatureFlagDoubleDoubleReceivedFeatureFlag = featureFlag
        valueForDoubleFeatureFlagFeatureFlagDoubleDoubleReceivedInvocations.append(featureFlag)
        if let valueForDoubleFeatureFlagFeatureFlagDoubleDoubleClosure = valueForDoubleFeatureFlagFeatureFlagDoubleDoubleClosure {
            return valueForDoubleFeatureFlagFeatureFlagDoubleDoubleClosure(featureFlag)
        } else {
            return valueForDoubleFeatureFlagFeatureFlagDoubleDoubleReturnValue
        }
    }

    //MARK: - value

    public var valueForStringFeatureFlagFeatureFlagStringStringCallsCount = 0
    public var valueForStringFeatureFlagFeatureFlagStringStringCalled: Bool {
        return valueForStringFeatureFlagFeatureFlagStringStringCallsCount > 0
    }
    public var valueForStringFeatureFlagFeatureFlagStringStringReceivedFeatureFlag: (FeatureFlagString)?
    public var valueForStringFeatureFlagFeatureFlagStringStringReceivedInvocations: [(FeatureFlagString)] = []
    public var valueForStringFeatureFlagFeatureFlagStringStringReturnValue: String!
    public var valueForStringFeatureFlagFeatureFlagStringStringClosure: ((FeatureFlagString) -> String)?

    public func value(forString featureFlag: FeatureFlagString) -> String {
        valueForStringFeatureFlagFeatureFlagStringStringCallsCount += 1
        valueForStringFeatureFlagFeatureFlagStringStringReceivedFeatureFlag = featureFlag
        valueForStringFeatureFlagFeatureFlagStringStringReceivedInvocations.append(featureFlag)
        if let valueForStringFeatureFlagFeatureFlagStringStringClosure = valueForStringFeatureFlagFeatureFlagStringStringClosure {
            return valueForStringFeatureFlagFeatureFlagStringStringClosure(featureFlag)
        } else {
            return valueForStringFeatureFlagFeatureFlagStringStringReturnValue
        }
    }

    //MARK: - override

    public var overrideFlagFeatureFlagBoolWithValueBoolVoidCallsCount = 0
    public var overrideFlagFeatureFlagBoolWithValueBoolVoidCalled: Bool {
        return overrideFlagFeatureFlagBoolWithValueBoolVoidCallsCount > 0
    }
    public var overrideFlagFeatureFlagBoolWithValueBoolVoidReceivedArguments: (flag: FeatureFlagBool, value: Bool?)?
    public var overrideFlagFeatureFlagBoolWithValueBoolVoidReceivedInvocations: [(flag: FeatureFlagBool, value: Bool?)] = []
    public var overrideFlagFeatureFlagBoolWithValueBoolVoidClosure: ((FeatureFlagBool, Bool?) -> Void)?

    public func override(flag: FeatureFlagBool, with value: Bool?) {
        overrideFlagFeatureFlagBoolWithValueBoolVoidCallsCount += 1
        overrideFlagFeatureFlagBoolWithValueBoolVoidReceivedArguments = (flag: flag, value: value)
        overrideFlagFeatureFlagBoolWithValueBoolVoidReceivedInvocations.append((flag: flag, value: value))
        overrideFlagFeatureFlagBoolWithValueBoolVoidClosure?(flag, value)
    }

    //MARK: - override

    public var overrideFlagFeatureFlagDoubleWithValueDoubleVoidCallsCount = 0
    public var overrideFlagFeatureFlagDoubleWithValueDoubleVoidCalled: Bool {
        return overrideFlagFeatureFlagDoubleWithValueDoubleVoidCallsCount > 0
    }
    public var overrideFlagFeatureFlagDoubleWithValueDoubleVoidReceivedArguments: (flag: FeatureFlagDouble, value: Double?)?
    public var overrideFlagFeatureFlagDoubleWithValueDoubleVoidReceivedInvocations: [(flag: FeatureFlagDouble, value: Double?)] = []
    public var overrideFlagFeatureFlagDoubleWithValueDoubleVoidClosure: ((FeatureFlagDouble, Double?) -> Void)?

    public func override(flag: FeatureFlagDouble, with value: Double?) {
        overrideFlagFeatureFlagDoubleWithValueDoubleVoidCallsCount += 1
        overrideFlagFeatureFlagDoubleWithValueDoubleVoidReceivedArguments = (flag: flag, value: value)
        overrideFlagFeatureFlagDoubleWithValueDoubleVoidReceivedInvocations.append((flag: flag, value: value))
        overrideFlagFeatureFlagDoubleWithValueDoubleVoidClosure?(flag, value)
    }

    //MARK: - override

    public var overrideFlagFeatureFlagStringWithValueStringVoidCallsCount = 0
    public var overrideFlagFeatureFlagStringWithValueStringVoidCalled: Bool {
        return overrideFlagFeatureFlagStringWithValueStringVoidCallsCount > 0
    }
    public var overrideFlagFeatureFlagStringWithValueStringVoidReceivedArguments: (flag: FeatureFlagString, value: String?)?
    public var overrideFlagFeatureFlagStringWithValueStringVoidReceivedInvocations: [(flag: FeatureFlagString, value: String?)] = []
    public var overrideFlagFeatureFlagStringWithValueStringVoidClosure: ((FeatureFlagString, String?) -> Void)?

    public func override(flag: FeatureFlagString, with value: String?) {
        overrideFlagFeatureFlagStringWithValueStringVoidCallsCount += 1
        overrideFlagFeatureFlagStringWithValueStringVoidReceivedArguments = (flag: flag, value: value)
        overrideFlagFeatureFlagStringWithValueStringVoidReceivedInvocations.append((flag: flag, value: value))
        overrideFlagFeatureFlagStringWithValueStringVoidClosure?(flag, value)
    }

    //MARK: - isOverridden

    public var isOverriddenFlagFeatureFlagBoolBoolCallsCount = 0
    public var isOverriddenFlagFeatureFlagBoolBoolCalled: Bool {
        return isOverriddenFlagFeatureFlagBoolBoolCallsCount > 0
    }
    public var isOverriddenFlagFeatureFlagBoolBoolReceivedFlag: (FeatureFlagBool)?
    public var isOverriddenFlagFeatureFlagBoolBoolReceivedInvocations: [(FeatureFlagBool)] = []
    public var isOverriddenFlagFeatureFlagBoolBoolReturnValue: Bool!
    public var isOverriddenFlagFeatureFlagBoolBoolClosure: ((FeatureFlagBool) -> Bool)?

    public func isOverridden(flag: FeatureFlagBool) -> Bool {
        isOverriddenFlagFeatureFlagBoolBoolCallsCount += 1
        isOverriddenFlagFeatureFlagBoolBoolReceivedFlag = flag
        isOverriddenFlagFeatureFlagBoolBoolReceivedInvocations.append(flag)
        if let isOverriddenFlagFeatureFlagBoolBoolClosure = isOverriddenFlagFeatureFlagBoolBoolClosure {
            return isOverriddenFlagFeatureFlagBoolBoolClosure(flag)
        } else {
            return isOverriddenFlagFeatureFlagBoolBoolReturnValue
        }
    }

    //MARK: - isOverridden

    public var isOverriddenFlagFeatureFlagDoubleBoolCallsCount = 0
    public var isOverriddenFlagFeatureFlagDoubleBoolCalled: Bool {
        return isOverriddenFlagFeatureFlagDoubleBoolCallsCount > 0
    }
    public var isOverriddenFlagFeatureFlagDoubleBoolReceivedFlag: (FeatureFlagDouble)?
    public var isOverriddenFlagFeatureFlagDoubleBoolReceivedInvocations: [(FeatureFlagDouble)] = []
    public var isOverriddenFlagFeatureFlagDoubleBoolReturnValue: Bool!
    public var isOverriddenFlagFeatureFlagDoubleBoolClosure: ((FeatureFlagDouble) -> Bool)?

    public func isOverridden(flag: FeatureFlagDouble) -> Bool {
        isOverriddenFlagFeatureFlagDoubleBoolCallsCount += 1
        isOverriddenFlagFeatureFlagDoubleBoolReceivedFlag = flag
        isOverriddenFlagFeatureFlagDoubleBoolReceivedInvocations.append(flag)
        if let isOverriddenFlagFeatureFlagDoubleBoolClosure = isOverriddenFlagFeatureFlagDoubleBoolClosure {
            return isOverriddenFlagFeatureFlagDoubleBoolClosure(flag)
        } else {
            return isOverriddenFlagFeatureFlagDoubleBoolReturnValue
        }
    }

    //MARK: - isOverridden

    public var isOverriddenFlagFeatureFlagStringBoolCallsCount = 0
    public var isOverriddenFlagFeatureFlagStringBoolCalled: Bool {
        return isOverriddenFlagFeatureFlagStringBoolCallsCount > 0
    }
    public var isOverriddenFlagFeatureFlagStringBoolReceivedFlag: (FeatureFlagString)?
    public var isOverriddenFlagFeatureFlagStringBoolReceivedInvocations: [(FeatureFlagString)] = []
    public var isOverriddenFlagFeatureFlagStringBoolReturnValue: Bool!
    public var isOverriddenFlagFeatureFlagStringBoolClosure: ((FeatureFlagString) -> Bool)?

    public func isOverridden(flag: FeatureFlagString) -> Bool {
        isOverriddenFlagFeatureFlagStringBoolCallsCount += 1
        isOverriddenFlagFeatureFlagStringBoolReceivedFlag = flag
        isOverriddenFlagFeatureFlagStringBoolReceivedInvocations.append(flag)
        if let isOverriddenFlagFeatureFlagStringBoolClosure = isOverriddenFlagFeatureFlagStringBoolClosure {
            return isOverriddenFlagFeatureFlagStringBoolClosure(flag)
        } else {
            return isOverriddenFlagFeatureFlagStringBoolReturnValue
        }
    }


}
