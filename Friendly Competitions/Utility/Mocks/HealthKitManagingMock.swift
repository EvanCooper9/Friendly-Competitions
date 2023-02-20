//import Combine
//
//class HealthKitManagingMock: HealthKitManaging {
//
//
//    var permissionStatus: AnyPublisher<PermissionStatus, Never> {
//        get { return underlyingPermissionStatus }
//        set(value) { underlyingPermissionStatus = value }
//    }
//    var underlyingPermissionStatus: AnyPublisher<PermissionStatus, Never>!
//
//
//    //MARK: - execute
//
//    var executeCallsCount = 0
//    var executeCalled: Bool {
//        return executeCallsCount > 0
//    }
//    var executeReceivedQuery: (any HealthKitQuery)?
//    var executeReceivedInvocations: [any HealthKitQuery] = []
//    var executeClosure: ((any HealthKitQuery) -> Void)?
//
//    func execute(_ query: any HealthKitQuery) {
//        executeCallsCount += 1
//        executeReceivedQuery = query
//        executeReceivedInvocations.append(query)
//        executeClosure?(query)
//    }
//
//    //MARK: - registerBackgroundDeliveryTask
//
//    var registerBackgroundDeliveryTaskCallsCount = 0
//    var registerBackgroundDeliveryTaskCalled: Bool {
//        return registerBackgroundDeliveryTaskCallsCount > 0
//    }
//    var registerBackgroundDeliveryTaskReceivedPublisher: AnyPublisher<Void, Never>?
//    var registerBackgroundDeliveryTaskReceivedInvocations: [AnyPublisher<Void, Never>] = []
//    var registerBackgroundDeliveryTaskClosure: ((AnyPublisher<Void, Never>) -> Void)?
//
//    func registerBackgroundDeliveryTask(_ publisher: AnyPublisher<Void, Never>) {
//        registerBackgroundDeliveryTaskCallsCount += 1
//        registerBackgroundDeliveryTaskReceivedPublisher = publisher
//        registerBackgroundDeliveryTaskReceivedInvocations.append(publisher)
//        registerBackgroundDeliveryTaskClosure?(publisher)
//    }
//
//    //MARK: - requestPermissions
//
//    var requestPermissionsCallsCount = 0
//    var requestPermissionsCalled: Bool {
//        return requestPermissionsCallsCount > 0
//    }
//    var requestPermissionsClosure: (() -> Void)?
//
//    func requestPermissions() {
//        requestPermissionsCallsCount += 1
//        requestPermissionsClosure?()
//    }
//
//}
