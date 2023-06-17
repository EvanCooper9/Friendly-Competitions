// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
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
import HealthKit























class APIMock: API {




    //MARK: - call

    var callCallsCount = 0
    var callCalled: Bool {
        return callCallsCount > 0
    }
    var callReceivedEndpoint: Endpoint?
    var callReceivedInvocations: [Endpoint] = []
    var callReturnValue: AnyPublisher<Void, Error>!
    var callClosure: ((Endpoint) -> AnyPublisher<Void, Error>)?

    func call(_ endpoint: Endpoint) -> AnyPublisher<Void, Error> {
        callCallsCount += 1
        callReceivedEndpoint = endpoint
        callReceivedInvocations.append(endpoint)
        if let callClosure = callClosure {
            return callClosure(endpoint)
        } else {
            return callReturnValue
        }
    }

}
class ActivitySummaryCacheMock: ActivitySummaryCache {


    var activitySummary: ActivitySummary?


}
class ActivitySummaryManagingMock: ActivitySummaryManaging {


    var activitySummary: AnyPublisher<ActivitySummary?, Never> {
        get { return underlyingActivitySummary }
        set(value) { underlyingActivitySummary = value }
    }
    var underlyingActivitySummary: AnyPublisher<ActivitySummary?, Never>!


    //MARK: - activitySummaries

    var activitySummariesInCallsCount = 0
    var activitySummariesInCalled: Bool {
        return activitySummariesInCallsCount > 0
    }
    var activitySummariesInReceivedDateInterval: DateInterval?
    var activitySummariesInReceivedInvocations: [DateInterval] = []
    var activitySummariesInReturnValue: AnyPublisher<[ActivitySummary], Error>!
    var activitySummariesInClosure: ((DateInterval) -> AnyPublisher<[ActivitySummary], Error>)?

    func activitySummaries(in dateInterval: DateInterval) -> AnyPublisher<[ActivitySummary], Error> {
        activitySummariesInCallsCount += 1
        activitySummariesInReceivedDateInterval = dateInterval
        activitySummariesInReceivedInvocations.append(dateInterval)
        if let activitySummariesInClosure = activitySummariesInClosure {
            return activitySummariesInClosure(dateInterval)
        } else {
            return activitySummariesInReturnValue
        }
    }

}
class AnalyticsManagingMock: AnalyticsManaging {




    //MARK: - set

    var setUserIdCallsCount = 0
    var setUserIdCalled: Bool {
        return setUserIdCallsCount > 0
    }
    var setUserIdReceivedUserId: String?
    var setUserIdReceivedInvocations: [String] = []
    var setUserIdClosure: ((String) -> Void)?

    func set(userId: String) {
        setUserIdCallsCount += 1
        setUserIdReceivedUserId = userId
        setUserIdReceivedInvocations.append(userId)
        setUserIdClosure?(userId)
    }

    //MARK: - log

    var logEventCallsCount = 0
    var logEventCalled: Bool {
        return logEventCallsCount > 0
    }
    var logEventReceivedEvent: AnalyticsEvent?
    var logEventReceivedInvocations: [AnalyticsEvent] = []
    var logEventClosure: ((AnalyticsEvent) -> Void)?

    func log(event: AnalyticsEvent) {
        logEventCallsCount += 1
        logEventReceivedEvent = event
        logEventReceivedInvocations.append(event)
        logEventClosure?(event)
    }

}
class AppStateProvidingMock: AppStateProviding {


    var deepLink: AnyPublisher<DeepLink?, Never> {
        get { return underlyingDeepLink }
        set(value) { underlyingDeepLink = value }
    }
    var underlyingDeepLink: AnyPublisher<DeepLink?, Never>!
    var hud: AnyPublisher<HUD?, Never> {
        get { return underlyingHud }
        set(value) { underlyingHud = value }
    }
    var underlyingHud: AnyPublisher<HUD?, Never>!
    var didBecomeActive: AnyPublisher<Bool, Never> {
        get { return underlyingDidBecomeActive }
        set(value) { underlyingDidBecomeActive = value }
    }
    var underlyingDidBecomeActive: AnyPublisher<Bool, Never>!


    //MARK: - push

    var pushHudCallsCount = 0
    var pushHudCalled: Bool {
        return pushHudCallsCount > 0
    }
    var pushHudReceivedHud: HUD?
    var pushHudReceivedInvocations: [HUD] = []
    var pushHudClosure: ((HUD) -> Void)?

    func push(hud: HUD) {
        pushHudCallsCount += 1
        pushHudReceivedHud = hud
        pushHudReceivedInvocations.append(hud)
        pushHudClosure?(hud)
    }

    //MARK: - push

    var pushDeepLinkCallsCount = 0
    var pushDeepLinkCalled: Bool {
        return pushDeepLinkCallsCount > 0
    }
    var pushDeepLinkReceivedDeepLink: DeepLink?
    var pushDeepLinkReceivedInvocations: [DeepLink] = []
    var pushDeepLinkClosure: ((DeepLink) -> Void)?

    func push(deepLink: DeepLink) {
        pushDeepLinkCallsCount += 1
        pushDeepLinkReceivedDeepLink = deepLink
        pushDeepLinkReceivedInvocations.append(deepLink)
        pushDeepLinkClosure?(deepLink)
    }

}
class AuthProvidingMock: AuthProviding {


    var user: AuthUser?


    //MARK: - userPublisher

    var userPublisherCallsCount = 0
    var userPublisherCalled: Bool {
        return userPublisherCallsCount > 0
    }
    var userPublisherReturnValue: AnyPublisher<AuthUser?, Never>!
    var userPublisherClosure: (() -> AnyPublisher<AuthUser?, Never>)?

    func userPublisher() -> AnyPublisher<AuthUser?, Never> {
        userPublisherCallsCount += 1
        if let userPublisherClosure = userPublisherClosure {
            return userPublisherClosure()
        } else {
            return userPublisherReturnValue
        }
    }

    //MARK: - signIn

    var signInWithCallsCount = 0
    var signInWithCalled: Bool {
        return signInWithCallsCount > 0
    }
    var signInWithReceivedCredential: AuthCredential?
    var signInWithReceivedInvocations: [AuthCredential] = []
    var signInWithReturnValue: AnyPublisher<AuthUser, Error>!
    var signInWithClosure: ((AuthCredential) -> AnyPublisher<AuthUser, Error>)?

    func signIn(with credential: AuthCredential) -> AnyPublisher<AuthUser, Error> {
        signInWithCallsCount += 1
        signInWithReceivedCredential = credential
        signInWithReceivedInvocations.append(credential)
        if let signInWithClosure = signInWithClosure {
            return signInWithClosure(credential)
        } else {
            return signInWithReturnValue
        }
    }

    //MARK: - signUp

    var signUpWithCallsCount = 0
    var signUpWithCalled: Bool {
        return signUpWithCallsCount > 0
    }
    var signUpWithReceivedCredential: AuthCredential?
    var signUpWithReceivedInvocations: [AuthCredential] = []
    var signUpWithReturnValue: AnyPublisher<AuthUser, Error>!
    var signUpWithClosure: ((AuthCredential) -> AnyPublisher<AuthUser, Error>)?

    func signUp(with credential: AuthCredential) -> AnyPublisher<AuthUser, Error> {
        signUpWithCallsCount += 1
        signUpWithReceivedCredential = credential
        signUpWithReceivedInvocations.append(credential)
        if let signUpWithClosure = signUpWithClosure {
            return signUpWithClosure(credential)
        } else {
            return signUpWithReturnValue
        }
    }

    //MARK: - signOut

    var signOutThrowableError: Error?
    var signOutCallsCount = 0
    var signOutCalled: Bool {
        return signOutCallsCount > 0
    }
    var signOutClosure: (() throws -> Void)?

    func signOut() throws {
        if let error = signOutThrowableError {
            throw error
        }
        signOutCallsCount += 1
        try signOutClosure?()
    }

    //MARK: - sendPasswordReset

    var sendPasswordResetToCallsCount = 0
    var sendPasswordResetToCalled: Bool {
        return sendPasswordResetToCallsCount > 0
    }
    var sendPasswordResetToReceivedEmail: String?
    var sendPasswordResetToReceivedInvocations: [String] = []
    var sendPasswordResetToReturnValue: AnyPublisher<Void, Error>!
    var sendPasswordResetToClosure: ((String) -> AnyPublisher<Void, Error>)?

    func sendPasswordReset(to email: String) -> AnyPublisher<Void, Error> {
        sendPasswordResetToCallsCount += 1
        sendPasswordResetToReceivedEmail = email
        sendPasswordResetToReceivedInvocations.append(email)
        if let sendPasswordResetToClosure = sendPasswordResetToClosure {
            return sendPasswordResetToClosure(email)
        } else {
            return sendPasswordResetToReturnValue
        }
    }

}
class AuthUserMock: AuthUser {


    var id: String {
        get { return underlyingId }
        set(value) { underlyingId = value }
    }
    var underlyingId: String!
    var displayName: String?
    var email: String?
    var isEmailVerified: Bool {
        get { return underlyingIsEmailVerified }
        set(value) { underlyingIsEmailVerified = value }
    }
    var underlyingIsEmailVerified: Bool!


    //MARK: - sendEmailVerification

    var sendEmailVerificationCallsCount = 0
    var sendEmailVerificationCalled: Bool {
        return sendEmailVerificationCallsCount > 0
    }
    var sendEmailVerificationReturnValue: AnyPublisher<Void, Error>!
    var sendEmailVerificationClosure: (() -> AnyPublisher<Void, Error>)?

    func sendEmailVerification() -> AnyPublisher<Void, Error> {
        sendEmailVerificationCallsCount += 1
        if let sendEmailVerificationClosure = sendEmailVerificationClosure {
            return sendEmailVerificationClosure()
        } else {
            return sendEmailVerificationReturnValue
        }
    }

    //MARK: - set

    var setDisplayNameCallsCount = 0
    var setDisplayNameCalled: Bool {
        return setDisplayNameCallsCount > 0
    }
    var setDisplayNameReceivedDisplayName: String?
    var setDisplayNameReceivedInvocations: [String] = []
    var setDisplayNameReturnValue: AnyPublisher<AuthUser, Error>!
    var setDisplayNameClosure: ((String) -> AnyPublisher<AuthUser, Error>)?

    func set(displayName: String) -> AnyPublisher<AuthUser, Error> {
        setDisplayNameCallsCount += 1
        setDisplayNameReceivedDisplayName = displayName
        setDisplayNameReceivedInvocations.append(displayName)
        if let setDisplayNameClosure = setDisplayNameClosure {
            return setDisplayNameClosure(displayName)
        } else {
            return setDisplayNameReturnValue
        }
    }

    //MARK: - reload

    var reloadThrowableError: Error?
    var reloadCallsCount = 0
    var reloadCalled: Bool {
        return reloadCallsCount > 0
    }
    var reloadClosure: (() async throws -> Void)?

    func reload() async throws {
        if let error = reloadThrowableError {
            throw error
        }
        reloadCallsCount += 1
        try await reloadClosure?()
    }

    //MARK: - delete

    var deleteThrowableError: Error?
    var deleteCallsCount = 0
    var deleteCalled: Bool {
        return deleteCallsCount > 0
    }
    var deleteClosure: (() async throws -> Void)?

    func delete() async throws {
        if let error = deleteThrowableError {
            throw error
        }
        deleteCallsCount += 1
        try await deleteClosure?()
    }

}
class AuthenticationCacheMock: AuthenticationCache {


    var currentUser: User?


}
class AuthenticationManagingMock: AuthenticationManaging {


    var emailVerified: AnyPublisher<Bool, Never> {
        get { return underlyingEmailVerified }
        set(value) { underlyingEmailVerified = value }
    }
    var underlyingEmailVerified: AnyPublisher<Bool, Never>!
    var loggedIn: AnyPublisher<Bool, Never> {
        get { return underlyingLoggedIn }
        set(value) { underlyingLoggedIn = value }
    }
    var underlyingLoggedIn: AnyPublisher<Bool, Never>!


    //MARK: - signIn

    var signInWithCallsCount = 0
    var signInWithCalled: Bool {
        return signInWithCallsCount > 0
    }
    var signInWithReceivedAuthenticationMethod: AuthenticationMethod?
    var signInWithReceivedInvocations: [AuthenticationMethod] = []
    var signInWithReturnValue: AnyPublisher<Void, Error>!
    var signInWithClosure: ((AuthenticationMethod) -> AnyPublisher<Void, Error>)?

    func signIn(with authenticationMethod: AuthenticationMethod) -> AnyPublisher<Void, Error> {
        signInWithCallsCount += 1
        signInWithReceivedAuthenticationMethod = authenticationMethod
        signInWithReceivedInvocations.append(authenticationMethod)
        if let signInWithClosure = signInWithClosure {
            return signInWithClosure(authenticationMethod)
        } else {
            return signInWithReturnValue
        }
    }

    //MARK: - signUp

    var signUpNameEmailPasswordPasswordConfirmationCallsCount = 0
    var signUpNameEmailPasswordPasswordConfirmationCalled: Bool {
        return signUpNameEmailPasswordPasswordConfirmationCallsCount > 0
    }
    var signUpNameEmailPasswordPasswordConfirmationReceivedArguments: (name: String, email: String, password: String, passwordConfirmation: String)?
    var signUpNameEmailPasswordPasswordConfirmationReceivedInvocations: [(name: String, email: String, password: String, passwordConfirmation: String)] = []
    var signUpNameEmailPasswordPasswordConfirmationReturnValue: AnyPublisher<Void, Error>!
    var signUpNameEmailPasswordPasswordConfirmationClosure: ((String, String, String, String) -> AnyPublisher<Void, Error>)?

    func signUp(name: String, email: String, password: String, passwordConfirmation: String) -> AnyPublisher<Void, Error> {
        signUpNameEmailPasswordPasswordConfirmationCallsCount += 1
        signUpNameEmailPasswordPasswordConfirmationReceivedArguments = (name: name, email: email, password: password, passwordConfirmation: passwordConfirmation)
        signUpNameEmailPasswordPasswordConfirmationReceivedInvocations.append((name: name, email: email, password: password, passwordConfirmation: passwordConfirmation))
        if let signUpNameEmailPasswordPasswordConfirmationClosure = signUpNameEmailPasswordPasswordConfirmationClosure {
            return signUpNameEmailPasswordPasswordConfirmationClosure(name, email, password, passwordConfirmation)
        } else {
            return signUpNameEmailPasswordPasswordConfirmationReturnValue
        }
    }

    //MARK: - deleteAccount

    var deleteAccountCallsCount = 0
    var deleteAccountCalled: Bool {
        return deleteAccountCallsCount > 0
    }
    var deleteAccountReturnValue: AnyPublisher<Void, Error>!
    var deleteAccountClosure: (() -> AnyPublisher<Void, Error>)?

    func deleteAccount() -> AnyPublisher<Void, Error> {
        deleteAccountCallsCount += 1
        if let deleteAccountClosure = deleteAccountClosure {
            return deleteAccountClosure()
        } else {
            return deleteAccountReturnValue
        }
    }

    //MARK: - signOut

    var signOutThrowableError: Error?
    var signOutCallsCount = 0
    var signOutCalled: Bool {
        return signOutCallsCount > 0
    }
    var signOutClosure: (() throws -> Void)?

    func signOut() throws {
        if let error = signOutThrowableError {
            throw error
        }
        signOutCallsCount += 1
        try signOutClosure?()
    }

    //MARK: - checkEmailVerification

    var checkEmailVerificationCallsCount = 0
    var checkEmailVerificationCalled: Bool {
        return checkEmailVerificationCallsCount > 0
    }
    var checkEmailVerificationReturnValue: AnyPublisher<Void, Error>!
    var checkEmailVerificationClosure: (() -> AnyPublisher<Void, Error>)?

    func checkEmailVerification() -> AnyPublisher<Void, Error> {
        checkEmailVerificationCallsCount += 1
        if let checkEmailVerificationClosure = checkEmailVerificationClosure {
            return checkEmailVerificationClosure()
        } else {
            return checkEmailVerificationReturnValue
        }
    }

    //MARK: - resendEmailVerification

    var resendEmailVerificationCallsCount = 0
    var resendEmailVerificationCalled: Bool {
        return resendEmailVerificationCallsCount > 0
    }
    var resendEmailVerificationReturnValue: AnyPublisher<Void, Error>!
    var resendEmailVerificationClosure: (() -> AnyPublisher<Void, Error>)?

    func resendEmailVerification() -> AnyPublisher<Void, Error> {
        resendEmailVerificationCallsCount += 1
        if let resendEmailVerificationClosure = resendEmailVerificationClosure {
            return resendEmailVerificationClosure()
        } else {
            return resendEmailVerificationReturnValue
        }
    }

    //MARK: - sendPasswordReset

    var sendPasswordResetToCallsCount = 0
    var sendPasswordResetToCalled: Bool {
        return sendPasswordResetToCallsCount > 0
    }
    var sendPasswordResetToReceivedEmail: String?
    var sendPasswordResetToReceivedInvocations: [String] = []
    var sendPasswordResetToReturnValue: AnyPublisher<Void, Error>!
    var sendPasswordResetToClosure: ((String) -> AnyPublisher<Void, Error>)?

    func sendPasswordReset(to email: String) -> AnyPublisher<Void, Error> {
        sendPasswordResetToCallsCount += 1
        sendPasswordResetToReceivedEmail = email
        sendPasswordResetToReceivedInvocations.append(email)
        if let sendPasswordResetToClosure = sendPasswordResetToClosure {
            return sendPasswordResetToClosure(email)
        } else {
            return sendPasswordResetToReturnValue
        }
    }

}
class CompetitionCacheMock: CompetitionCache {


    var competitionsHasPremiumResults: HasPremiumResultsContainerCache?


}
class CompetitionsManagingMock: CompetitionsManaging {


    var competitions: AnyPublisher<[Competition], Never> {
        get { return underlyingCompetitions }
        set(value) { underlyingCompetitions = value }
    }
    var underlyingCompetitions: AnyPublisher<[Competition], Never>!
    var invitedCompetitions: AnyPublisher<[Competition], Never> {
        get { return underlyingInvitedCompetitions }
        set(value) { underlyingInvitedCompetitions = value }
    }
    var underlyingInvitedCompetitions: AnyPublisher<[Competition], Never>!
    var appOwnedCompetitions: AnyPublisher<[Competition], Never> {
        get { return underlyingAppOwnedCompetitions }
        set(value) { underlyingAppOwnedCompetitions = value }
    }
    var underlyingAppOwnedCompetitions: AnyPublisher<[Competition], Never>!
    var hasPremiumResults: AnyPublisher<Bool, Never> {
        get { return underlyingHasPremiumResults }
        set(value) { underlyingHasPremiumResults = value }
    }
    var underlyingHasPremiumResults: AnyPublisher<Bool, Never>!


    //MARK: - create

    var createCallsCount = 0
    var createCalled: Bool {
        return createCallsCount > 0
    }
    var createReceivedCompetition: Competition?
    var createReceivedInvocations: [Competition] = []
    var createReturnValue: AnyPublisher<Void, Error>!
    var createClosure: ((Competition) -> AnyPublisher<Void, Error>)?

    func create(_ competition: Competition) -> AnyPublisher<Void, Error> {
        createCallsCount += 1
        createReceivedCompetition = competition
        createReceivedInvocations.append(competition)
        if let createClosure = createClosure {
            return createClosure(competition)
        } else {
            return createReturnValue
        }
    }

    //MARK: - update

    var updateCallsCount = 0
    var updateCalled: Bool {
        return updateCallsCount > 0
    }
    var updateReceivedCompetition: Competition?
    var updateReceivedInvocations: [Competition] = []
    var updateReturnValue: AnyPublisher<Void, Error>!
    var updateClosure: ((Competition) -> AnyPublisher<Void, Error>)?

    func update(_ competition: Competition) -> AnyPublisher<Void, Error> {
        updateCallsCount += 1
        updateReceivedCompetition = competition
        updateReceivedInvocations.append(competition)
        if let updateClosure = updateClosure {
            return updateClosure(competition)
        } else {
            return updateReturnValue
        }
    }

    //MARK: - search

    var searchByIDCallsCount = 0
    var searchByIDCalled: Bool {
        return searchByIDCallsCount > 0
    }
    var searchByIDReceivedCompetitionID: Competition.ID?
    var searchByIDReceivedInvocations: [Competition.ID] = []
    var searchByIDReturnValue: AnyPublisher<Competition, Error>!
    var searchByIDClosure: ((Competition.ID) -> AnyPublisher<Competition, Error>)?

    func search(byID competitionID: Competition.ID) -> AnyPublisher<Competition, Error> {
        searchByIDCallsCount += 1
        searchByIDReceivedCompetitionID = competitionID
        searchByIDReceivedInvocations.append(competitionID)
        if let searchByIDClosure = searchByIDClosure {
            return searchByIDClosure(competitionID)
        } else {
            return searchByIDReturnValue
        }
    }

    //MARK: - results

    var resultsForCallsCount = 0
    var resultsForCalled: Bool {
        return resultsForCallsCount > 0
    }
    var resultsForReceivedCompetitionID: Competition.ID?
    var resultsForReceivedInvocations: [Competition.ID] = []
    var resultsForReturnValue: AnyPublisher<[CompetitionResult], Error>!
    var resultsForClosure: ((Competition.ID) -> AnyPublisher<[CompetitionResult], Error>)?

    func results(for competitionID: Competition.ID) -> AnyPublisher<[CompetitionResult], Error> {
        resultsForCallsCount += 1
        resultsForReceivedCompetitionID = competitionID
        resultsForReceivedInvocations.append(competitionID)
        if let resultsForClosure = resultsForClosure {
            return resultsForClosure(competitionID)
        } else {
            return resultsForReturnValue
        }
    }

    //MARK: - standings

    var standingsForResultIDCallsCount = 0
    var standingsForResultIDCalled: Bool {
        return standingsForResultIDCallsCount > 0
    }
    var standingsForResultIDReceivedArguments: (competitionID: Competition.ID, resultID: CompetitionResult.ID)?
    var standingsForResultIDReceivedInvocations: [(competitionID: Competition.ID, resultID: CompetitionResult.ID)] = []
    var standingsForResultIDReturnValue: AnyPublisher<[Competition.Standing], Error>!
    var standingsForResultIDClosure: ((Competition.ID, CompetitionResult.ID) -> AnyPublisher<[Competition.Standing], Error>)?

    func standings(for competitionID: Competition.ID, resultID: CompetitionResult.ID) -> AnyPublisher<[Competition.Standing], Error> {
        standingsForResultIDCallsCount += 1
        standingsForResultIDReceivedArguments = (competitionID: competitionID, resultID: resultID)
        standingsForResultIDReceivedInvocations.append((competitionID: competitionID, resultID: resultID))
        if let standingsForResultIDClosure = standingsForResultIDClosure {
            return standingsForResultIDClosure(competitionID, resultID)
        } else {
            return standingsForResultIDReturnValue
        }
    }

    //MARK: - competitionPublisher

    var competitionPublisherForCallsCount = 0
    var competitionPublisherForCalled: Bool {
        return competitionPublisherForCallsCount > 0
    }
    var competitionPublisherForReceivedCompetitionID: Competition.ID?
    var competitionPublisherForReceivedInvocations: [Competition.ID] = []
    var competitionPublisherForReturnValue: AnyPublisher<Competition, Error>!
    var competitionPublisherForClosure: ((Competition.ID) -> AnyPublisher<Competition, Error>)?

    func competitionPublisher(for competitionID: Competition.ID) -> AnyPublisher<Competition, Error> {
        competitionPublisherForCallsCount += 1
        competitionPublisherForReceivedCompetitionID = competitionID
        competitionPublisherForReceivedInvocations.append(competitionID)
        if let competitionPublisherForClosure = competitionPublisherForClosure {
            return competitionPublisherForClosure(competitionID)
        } else {
            return competitionPublisherForReturnValue
        }
    }

    //MARK: - standingsPublisher

    var standingsPublisherForCallsCount = 0
    var standingsPublisherForCalled: Bool {
        return standingsPublisherForCallsCount > 0
    }
    var standingsPublisherForReceivedCompetitionID: Competition.ID?
    var standingsPublisherForReceivedInvocations: [Competition.ID] = []
    var standingsPublisherForReturnValue: AnyPublisher<[Competition.Standing], Error>!
    var standingsPublisherForClosure: ((Competition.ID) -> AnyPublisher<[Competition.Standing], Error>)?

    func standingsPublisher(for competitionID: Competition.ID) -> AnyPublisher<[Competition.Standing], Error> {
        standingsPublisherForCallsCount += 1
        standingsPublisherForReceivedCompetitionID = competitionID
        standingsPublisherForReceivedInvocations.append(competitionID)
        if let standingsPublisherForClosure = standingsPublisherForClosure {
            return standingsPublisherForClosure(competitionID)
        } else {
            return standingsPublisherForReturnValue
        }
    }

}
class DatabaseMock: Database {




    //MARK: - batch

    var batchCallsCount = 0
    var batchCalled: Bool {
        return batchCallsCount > 0
    }
    var batchReturnValue: Batch!
    var batchClosure: (() -> Batch)?

    func batch() -> Batch {
        batchCallsCount += 1
        if let batchClosure = batchClosure {
            return batchClosure()
        } else {
            return batchReturnValue
        }
    }

    //MARK: - collection

    var collectionCallsCount = 0
    var collectionCalled: Bool {
        return collectionCallsCount > 0
    }
    var collectionReceivedCollectionPath: String?
    var collectionReceivedInvocations: [String] = []
    var collectionReturnValue: Collection!
    var collectionClosure: ((String) -> Collection)?

    func collection(_ collectionPath: String) -> Collection {
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

    var collectionGroupCallsCount = 0
    var collectionGroupCalled: Bool {
        return collectionGroupCallsCount > 0
    }
    var collectionGroupReceivedCollectionGroupID: String?
    var collectionGroupReceivedInvocations: [String] = []
    var collectionGroupReturnValue: Collection!
    var collectionGroupClosure: ((String) -> Collection)?

    func collectionGroup(_ collectionGroupID: String) -> Collection {
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

    var documentCallsCount = 0
    var documentCalled: Bool {
        return documentCallsCount > 0
    }
    var documentReceivedDocumentPath: String?
    var documentReceivedInvocations: [String] = []
    var documentReturnValue: Document!
    var documentClosure: ((String) -> Document)?

    func document(_ documentPath: String) -> Document {
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
class DatabaseSettingManagingMock: DatabaseSettingManaging {


    var shouldResetCache: Bool {
        get { return underlyingShouldResetCache }
        set(value) { underlyingShouldResetCache = value }
    }
    var underlyingShouldResetCache: Bool!


    //MARK: - didResetCache

    var didResetCacheCallsCount = 0
    var didResetCacheCalled: Bool {
        return didResetCacheCallsCount > 0
    }
    var didResetCacheClosure: (() -> Void)?

    func didResetCache() {
        didResetCacheCallsCount += 1
        didResetCacheClosure?()
    }

}
class EnvironmentCacheMock: EnvironmentCache {


    var environment: FCEnvironment?


}
class EnvironmentManagingMock: EnvironmentManaging {


    var environment: FCEnvironment {
        get { return underlyingEnvironment }
        set(value) { underlyingEnvironment = value }
    }
    var underlyingEnvironment: FCEnvironment!
    var environmentPublisher: AnyPublisher<FCEnvironment, Never> {
        get { return underlyingEnvironmentPublisher }
        set(value) { underlyingEnvironmentPublisher = value }
    }
    var underlyingEnvironmentPublisher: AnyPublisher<FCEnvironment, Never>!


    //MARK: - set

    var setCallsCount = 0
    var setCalled: Bool {
        return setCallsCount > 0
    }
    var setReceivedEnvironment: FCEnvironment?
    var setReceivedInvocations: [FCEnvironment] = []
    var setClosure: ((FCEnvironment) -> Void)?

    func set(_ environment: FCEnvironment) {
        setCallsCount += 1
        setReceivedEnvironment = environment
        setReceivedInvocations.append(environment)
        setClosure?(environment)
    }

}
class FriendsManagingMock: FriendsManaging {


    var friends: AnyPublisher<[User], Never> {
        get { return underlyingFriends }
        set(value) { underlyingFriends = value }
    }
    var underlyingFriends: AnyPublisher<[User], Never>!
    var friendActivitySummaries: AnyPublisher<[User.ID: ActivitySummary], Never> {
        get { return underlyingFriendActivitySummaries }
        set(value) { underlyingFriendActivitySummaries = value }
    }
    var underlyingFriendActivitySummaries: AnyPublisher<[User.ID: ActivitySummary], Never>!
    var friendRequests: AnyPublisher<[User], Never> {
        get { return underlyingFriendRequests }
        set(value) { underlyingFriendRequests = value }
    }
    var underlyingFriendRequests: AnyPublisher<[User], Never>!


    //MARK: - user

    var userWithIdCallsCount = 0
    var userWithIdCalled: Bool {
        return userWithIdCallsCount > 0
    }
    var userWithIdReceivedId: String?
    var userWithIdReceivedInvocations: [String] = []
    var userWithIdReturnValue: AnyPublisher<User, Error>!
    var userWithIdClosure: ((String) -> AnyPublisher<User, Error>)?

    func user(withId id: String) -> AnyPublisher<User, Error> {
        userWithIdCallsCount += 1
        userWithIdReceivedId = id
        userWithIdReceivedInvocations.append(id)
        if let userWithIdClosure = userWithIdClosure {
            return userWithIdClosure(id)
        } else {
            return userWithIdReturnValue
        }
    }

}
class HealthKitManagerCacheMock: HealthKitManagerCache {


    var permissionStatus: [HealthKitPermissionType: PermissionStatus] = [:]


}
class HealthKitManagingMock: HealthKitManaging {


    var permissionStatus: AnyPublisher<PermissionStatus, Never> {
        get { return underlyingPermissionStatus }
        set(value) { underlyingPermissionStatus = value }
    }
    var underlyingPermissionStatus: AnyPublisher<PermissionStatus, Never>!


    //MARK: - execute

    var executeCallsCount = 0
    var executeCalled: Bool {
        return executeCallsCount > 0
    }
    var executeReceivedQuery: AnyHealthKitQuery?
    var executeReceivedInvocations: [AnyHealthKitQuery] = []
    var executeClosure: ((AnyHealthKitQuery) -> Void)?

    func execute(_ query: AnyHealthKitQuery) {
        executeCallsCount += 1
        executeReceivedQuery = query
        executeReceivedInvocations.append(query)
        executeClosure?(query)
    }

    //MARK: - registerBackgroundDeliveryTask

    var registerBackgroundDeliveryTaskCallsCount = 0
    var registerBackgroundDeliveryTaskCalled: Bool {
        return registerBackgroundDeliveryTaskCallsCount > 0
    }
    var registerBackgroundDeliveryTaskReceivedPublisher: AnyPublisher<Void, Never>?
    var registerBackgroundDeliveryTaskReceivedInvocations: [AnyPublisher<Void, Never>] = []
    var registerBackgroundDeliveryTaskClosure: ((AnyPublisher<Void, Never>) -> Void)?

    func registerBackgroundDeliveryTask(_ publisher: AnyPublisher<Void, Never>) {
        registerBackgroundDeliveryTaskCallsCount += 1
        registerBackgroundDeliveryTaskReceivedPublisher = publisher
        registerBackgroundDeliveryTaskReceivedInvocations.append(publisher)
        registerBackgroundDeliveryTaskClosure?(publisher)
    }

    //MARK: - requestPermissions

    var requestPermissionsCallsCount = 0
    var requestPermissionsCalled: Bool {
        return requestPermissionsCallsCount > 0
    }
    var requestPermissionsClosure: (() -> Void)?

    func requestPermissions() {
        requestPermissionsCallsCount += 1
        requestPermissionsClosure?()
    }

}
class HealthStoringMock: HealthStoring {




    //MARK: - execute

    var executeCallsCount = 0
    var executeCalled: Bool {
        return executeCallsCount > 0
    }
    var executeReceivedQuery: AnyHealthKitQuery?
    var executeReceivedInvocations: [AnyHealthKitQuery] = []
    var executeClosure: ((AnyHealthKitQuery) -> Void)?

    func execute(_ query: AnyHealthKitQuery) {
        executeCallsCount += 1
        executeReceivedQuery = query
        executeReceivedInvocations.append(query)
        executeClosure?(query)
    }

    //MARK: - enableBackgroundDelivery

    var enableBackgroundDeliveryForCallsCount = 0
    var enableBackgroundDeliveryForCalled: Bool {
        return enableBackgroundDeliveryForCallsCount > 0
    }
    var enableBackgroundDeliveryForReceivedPermissionType: HealthKitPermissionType?
    var enableBackgroundDeliveryForReceivedInvocations: [HealthKitPermissionType] = []
    var enableBackgroundDeliveryForClosure: ((HealthKitPermissionType) -> Void)?

    func enableBackgroundDelivery(for permissionType: HealthKitPermissionType) {
        enableBackgroundDeliveryForCallsCount += 1
        enableBackgroundDeliveryForReceivedPermissionType = permissionType
        enableBackgroundDeliveryForReceivedInvocations.append(permissionType)
        enableBackgroundDeliveryForClosure?(permissionType)
    }

    //MARK: - requestAuthorization

    var requestAuthorizationForCompletionCallsCount = 0
    var requestAuthorizationForCompletionCalled: Bool {
        return requestAuthorizationForCompletionCallsCount > 0
    }
    var requestAuthorizationForCompletionReceivedArguments: (permissionTypes: [HealthKitPermissionType], completion: (Bool) -> Void)?
    var requestAuthorizationForCompletionReceivedInvocations: [(permissionTypes: [HealthKitPermissionType], completion: (Bool) -> Void)] = []
    var requestAuthorizationForCompletionClosure: (([HealthKitPermissionType], @escaping (Bool) -> Void) -> Void)?

    func requestAuthorization(for permissionTypes: [HealthKitPermissionType], completion: @escaping (Bool) -> Void) {
        requestAuthorizationForCompletionCallsCount += 1
        requestAuthorizationForCompletionReceivedArguments = (permissionTypes: permissionTypes, completion: completion)
        requestAuthorizationForCompletionReceivedInvocations.append((permissionTypes: permissionTypes, completion: completion))
        requestAuthorizationForCompletionClosure?(permissionTypes, completion)
    }

}
class NotificationsManagingMock: NotificationsManaging {


    var permissionStatus: AnyPublisher<PermissionStatus, Never> {
        get { return underlyingPermissionStatus }
        set(value) { underlyingPermissionStatus = value }
    }
    var underlyingPermissionStatus: AnyPublisher<PermissionStatus, Never>!


    //MARK: - requestPermissions

    var requestPermissionsCallsCount = 0
    var requestPermissionsCalled: Bool {
        return requestPermissionsCallsCount > 0
    }
    var requestPermissionsClosure: (() -> Void)?

    func requestPermissions() {
        requestPermissionsCallsCount += 1
        requestPermissionsClosure?()
    }

}
class PermissionsManagingMock: PermissionsManaging {


    var requiresPermission: AnyPublisher<Bool, Never> {
        get { return underlyingRequiresPermission }
        set(value) { underlyingRequiresPermission = value }
    }
    var underlyingRequiresPermission: AnyPublisher<Bool, Never>!
    var permissionStatus: AnyPublisher<[Permission: PermissionStatus], Never> {
        get { return underlyingPermissionStatus }
        set(value) { underlyingPermissionStatus = value }
    }
    var underlyingPermissionStatus: AnyPublisher<[Permission: PermissionStatus], Never>!


    //MARK: - request

    var requestCallsCount = 0
    var requestCalled: Bool {
        return requestCallsCount > 0
    }
    var requestReceivedPermission: Permission?
    var requestReceivedInvocations: [Permission] = []
    var requestClosure: ((Permission) -> Void)?

    func request(_ permission: Permission) {
        requestCallsCount += 1
        requestReceivedPermission = permission
        requestReceivedInvocations.append(permission)
        requestClosure?(permission)
    }

}
class PremiumManagingMock: PremiumManaging {


    var premium: AnyPublisher<Premium?, Never> {
        get { return underlyingPremium }
        set(value) { underlyingPremium = value }
    }
    var underlyingPremium: AnyPublisher<Premium?, Never>!
    var products: AnyPublisher<[Product], Never> {
        get { return underlyingProducts }
        set(value) { underlyingProducts = value }
    }
    var underlyingProducts: AnyPublisher<[Product], Never>!


    //MARK: - purchase

    var purchaseCallsCount = 0
    var purchaseCalled: Bool {
        return purchaseCallsCount > 0
    }
    var purchaseReceivedProduct: Product?
    var purchaseReceivedInvocations: [Product] = []
    var purchaseReturnValue: AnyPublisher<Void, Error>!
    var purchaseClosure: ((Product) -> AnyPublisher<Void, Error>)?

    func purchase(_ product: Product) -> AnyPublisher<Void, Error> {
        purchaseCallsCount += 1
        purchaseReceivedProduct = product
        purchaseReceivedInvocations.append(product)
        if let purchaseClosure = purchaseClosure {
            return purchaseClosure(product)
        } else {
            return purchaseReturnValue
        }
    }

    //MARK: - restorePurchases

    var restorePurchasesCallsCount = 0
    var restorePurchasesCalled: Bool {
        return restorePurchasesCallsCount > 0
    }
    var restorePurchasesReturnValue: AnyPublisher<Void, Error>!
    var restorePurchasesClosure: (() -> AnyPublisher<Void, Error>)?

    func restorePurchases() -> AnyPublisher<Void, Error> {
        restorePurchasesCallsCount += 1
        if let restorePurchasesClosure = restorePurchasesClosure {
            return restorePurchasesClosure()
        } else {
            return restorePurchasesReturnValue
        }
    }

    //MARK: - manageSubscription

    var manageSubscriptionCallsCount = 0
    var manageSubscriptionCalled: Bool {
        return manageSubscriptionCallsCount > 0
    }
    var manageSubscriptionClosure: (() -> Void)?

    func manageSubscription() {
        manageSubscriptionCallsCount += 1
        manageSubscriptionClosure?()
    }

}
class SearchClientMock: SearchClient {




    //MARK: - index

    var indexWithNameCallsCount = 0
    var indexWithNameCalled: Bool {
        return indexWithNameCallsCount > 0
    }
    var indexWithNameReceivedName: String?
    var indexWithNameReceivedInvocations: [String] = []
    var indexWithNameReturnValue: SearchIndex!
    var indexWithNameClosure: ((String) -> SearchIndex)?

    func index(withName name: String) -> SearchIndex {
        indexWithNameCallsCount += 1
        indexWithNameReceivedName = name
        indexWithNameReceivedInvocations.append(name)
        if let indexWithNameClosure = indexWithNameClosure {
            return indexWithNameClosure(name)
        } else {
            return indexWithNameReturnValue
        }
    }

}
class SearchManagingMock: SearchManaging {




    //MARK: - searchForCompetitions

    var searchForCompetitionsByNameCallsCount = 0
    var searchForCompetitionsByNameCalled: Bool {
        return searchForCompetitionsByNameCallsCount > 0
    }
    var searchForCompetitionsByNameReceivedName: String?
    var searchForCompetitionsByNameReceivedInvocations: [String] = []
    var searchForCompetitionsByNameReturnValue: AnyPublisher<[Competition], Error>!
    var searchForCompetitionsByNameClosure: ((String) -> AnyPublisher<[Competition], Error>)?

    func searchForCompetitions(byName name: String) -> AnyPublisher<[Competition], Error> {
        searchForCompetitionsByNameCallsCount += 1
        searchForCompetitionsByNameReceivedName = name
        searchForCompetitionsByNameReceivedInvocations.append(name)
        if let searchForCompetitionsByNameClosure = searchForCompetitionsByNameClosure {
            return searchForCompetitionsByNameClosure(name)
        } else {
            return searchForCompetitionsByNameReturnValue
        }
    }

    //MARK: - searchForUsers

    var searchForUsersByNameCallsCount = 0
    var searchForUsersByNameCalled: Bool {
        return searchForUsersByNameCallsCount > 0
    }
    var searchForUsersByNameReceivedName: String?
    var searchForUsersByNameReceivedInvocations: [String] = []
    var searchForUsersByNameReturnValue: AnyPublisher<[User], Error>!
    var searchForUsersByNameClosure: ((String) -> AnyPublisher<[User], Error>)?

    func searchForUsers(byName name: String) -> AnyPublisher<[User], Error> {
        searchForUsersByNameCallsCount += 1
        searchForUsersByNameReceivedName = name
        searchForUsersByNameReceivedInvocations.append(name)
        if let searchForUsersByNameClosure = searchForUsersByNameClosure {
            return searchForUsersByNameClosure(name)
        } else {
            return searchForUsersByNameReturnValue
        }
    }

    //MARK: - searchForUsers

    var searchForUsersWithIDsCallsCount = 0
    var searchForUsersWithIDsCalled: Bool {
        return searchForUsersWithIDsCallsCount > 0
    }
    var searchForUsersWithIDsReceivedUserIDs: [User.ID]?
    var searchForUsersWithIDsReceivedInvocations: [[User.ID]] = []
    var searchForUsersWithIDsReturnValue: AnyPublisher<[User], Error>!
    var searchForUsersWithIDsClosure: (([User.ID]) -> AnyPublisher<[User], Error>)?

    func searchForUsers(withIDs userIDs: [User.ID]) -> AnyPublisher<[User], Error> {
        searchForUsersWithIDsCallsCount += 1
        searchForUsersWithIDsReceivedUserIDs = userIDs
        searchForUsersWithIDsReceivedInvocations.append(userIDs)
        if let searchForUsersWithIDsClosure = searchForUsersWithIDsClosure {
            return searchForUsersWithIDsClosure(userIDs)
        } else {
            return searchForUsersWithIDsReturnValue
        }
    }

}
class SignInWithAppleProvidingMock: SignInWithAppleProviding {




    //MARK: - signIn

    var signInCallsCount = 0
    var signInCalled: Bool {
        return signInCallsCount > 0
    }
    var signInReturnValue: AnyPublisher<AuthUser, Error>!
    var signInClosure: (() -> AnyPublisher<AuthUser, Error>)?

    func signIn() -> AnyPublisher<AuthUser, Error> {
        signInCallsCount += 1
        if let signInClosure = signInClosure {
            return signInClosure()
        } else {
            return signInReturnValue
        }
    }

}
class StorageMock: Storage {




    //MARK: - data

    var dataPathCallsCount = 0
    var dataPathCalled: Bool {
        return dataPathCallsCount > 0
    }
    var dataPathReceivedPath: String?
    var dataPathReceivedInvocations: [String] = []
    var dataPathReturnValue: AnyPublisher<Data, Error>!
    var dataPathClosure: ((String) -> AnyPublisher<Data, Error>)?

    func data(path: String) -> AnyPublisher<Data, Error> {
        dataPathCallsCount += 1
        dataPathReceivedPath = path
        dataPathReceivedInvocations.append(path)
        if let dataPathClosure = dataPathClosure {
            return dataPathClosure(path)
        } else {
            return dataPathReturnValue
        }
    }

}
class StorageManagingMock: StorageManaging {




    //MARK: - data

    var dataForCallsCount = 0
    var dataForCalled: Bool {
        return dataForCallsCount > 0
    }
    var dataForReceivedStoragePath: String?
    var dataForReceivedInvocations: [String] = []
    var dataForReturnValue: AnyPublisher<Data, Error>!
    var dataForClosure: ((String) -> AnyPublisher<Data, Error>)?

    func data(for storagePath: String) -> AnyPublisher<Data, Error> {
        dataForCallsCount += 1
        dataForReceivedStoragePath = storagePath
        dataForReceivedInvocations.append(storagePath)
        if let dataForClosure = dataForClosure {
            return dataForClosure(storagePath)
        } else {
            return dataForReturnValue
        }
    }

}
class UserManagingMock: UserManaging {


    var user: User {
        get { return underlyingUser }
        set(value) { underlyingUser = value }
    }
    var underlyingUser: User!
    var userPublisher: AnyPublisher<User, Never> {
        get { return underlyingUserPublisher }
        set(value) { underlyingUserPublisher = value }
    }
    var underlyingUserPublisher: AnyPublisher<User, Never>!


    //MARK: - deleteAccount

    var deleteAccountCallsCount = 0
    var deleteAccountCalled: Bool {
        return deleteAccountCallsCount > 0
    }
    var deleteAccountReturnValue: AnyPublisher<Void, Error>!
    var deleteAccountClosure: (() -> AnyPublisher<Void, Error>)?

    func deleteAccount() -> AnyPublisher<Void, Error> {
        deleteAccountCallsCount += 1
        if let deleteAccountClosure = deleteAccountClosure {
            return deleteAccountClosure()
        } else {
            return deleteAccountReturnValue
        }
    }

    //MARK: - update

    var updateWithCallsCount = 0
    var updateWithCalled: Bool {
        return updateWithCallsCount > 0
    }
    var updateWithReceivedUser: User?
    var updateWithReceivedInvocations: [User] = []
    var updateWithReturnValue: AnyPublisher<Void, Error>!
    var updateWithClosure: ((User) -> AnyPublisher<Void, Error>)?

    func update(with user: User) -> AnyPublisher<Void, Error> {
        updateWithCallsCount += 1
        updateWithReceivedUser = user
        updateWithReceivedInvocations.append(user)
        if let updateWithClosure = updateWithClosure {
            return updateWithClosure(user)
        } else {
            return updateWithReturnValue
        }
    }

}
class WorkoutCacheMock: WorkoutCache {


    var workoutMetrics: [WorkoutType: [WorkoutMetric]] = [:]


}
class WorkoutManagingMock: WorkoutManaging {




    //MARK: - workouts

    var workoutsOfWithInCallsCount = 0
    var workoutsOfWithInCalled: Bool {
        return workoutsOfWithInCallsCount > 0
    }
    var workoutsOfWithInReceivedArguments: (type: WorkoutType, metrics: [WorkoutMetric], dateInterval: DateInterval)?
    var workoutsOfWithInReceivedInvocations: [(type: WorkoutType, metrics: [WorkoutMetric], dateInterval: DateInterval)] = []
    var workoutsOfWithInReturnValue: AnyPublisher<[Workout], Error>!
    var workoutsOfWithInClosure: ((WorkoutType, [WorkoutMetric], DateInterval) -> AnyPublisher<[Workout], Error>)?

    func workouts(of type: WorkoutType, with metrics: [WorkoutMetric], in dateInterval: DateInterval) -> AnyPublisher<[Workout], Error> {
        workoutsOfWithInCallsCount += 1
        workoutsOfWithInReceivedArguments = (type: type, metrics: metrics, dateInterval: dateInterval)
        workoutsOfWithInReceivedInvocations.append((type: type, metrics: metrics, dateInterval: dateInterval))
        if let workoutsOfWithInClosure = workoutsOfWithInClosure {
            return workoutsOfWithInClosure(type, metrics, dateInterval)
        } else {
            return workoutsOfWithInReturnValue
        }
    }

}
