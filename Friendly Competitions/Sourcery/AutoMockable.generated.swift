// Generated using Sourcery 2.0.1 — https://github.com/krzysztofzablocki/Sourcery
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

    var callWithCallsCount = 0
    var callWithCalled: Bool {
        return callWithCallsCount > 0
    }
    var callWithReceivedArguments: (endpoint: String, data: [String: Any]?)?
    var callWithReceivedInvocations: [(endpoint: String, data: [String: Any]?)] = []
    var callWithReturnValue: AnyPublisher<Void, Error>!
    var callWithClosure: ((String, [String: Any]?) -> AnyPublisher<Void, Error>)?

    func call(_ endpoint: String, with data: [String: Any]?) -> AnyPublisher<Void, Error> {
        callWithCallsCount += 1
        callWithReceivedArguments = (endpoint: endpoint, data: data)
        callWithReceivedInvocations.append((endpoint: endpoint, data: data))
        if let callWithClosure = callWithClosure {
            return callWithClosure(endpoint, data)
        } else {
            return callWithReturnValue
        }
    }

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
    var signInWithReceivedSignInMethod: SignInMethod?
    var signInWithReceivedInvocations: [SignInMethod] = []
    var signInWithReturnValue: AnyPublisher<Void, Error>!
    var signInWithClosure: ((SignInMethod) -> AnyPublisher<Void, Error>)?

    func signIn(with signInMethod: SignInMethod) -> AnyPublisher<Void, Error> {
        signInWithCallsCount += 1
        signInWithReceivedSignInMethod = signInMethod
        signInWithReceivedInvocations.append(signInMethod)
        if let signInWithClosure = signInWithClosure {
            return signInWithClosure(signInMethod)
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
class CacheMock: Cache {


    var activitySummary: ActivitySummary?


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
    var competitionsDateInterval: DateInterval {
        get { return underlyingCompetitionsDateInterval }
        set(value) { underlyingCompetitionsDateInterval = value }
    }
    var underlyingCompetitionsDateInterval: DateInterval!
    var hasPremiumResults: AnyPublisher<Bool, Never> {
        get { return underlyingHasPremiumResults }
        set(value) { underlyingHasPremiumResults = value }
    }
    var underlyingHasPremiumResults: AnyPublisher<Bool, Never>!


    //MARK: - accept

    var acceptCallsCount = 0
    var acceptCalled: Bool {
        return acceptCallsCount > 0
    }
    var acceptReceivedCompetition: Competition?
    var acceptReceivedInvocations: [Competition] = []
    var acceptReturnValue: AnyPublisher<Void, Error>!
    var acceptClosure: ((Competition) -> AnyPublisher<Void, Error>)?

    func accept(_ competition: Competition) -> AnyPublisher<Void, Error> {
        acceptCallsCount += 1
        acceptReceivedCompetition = competition
        acceptReceivedInvocations.append(competition)
        if let acceptClosure = acceptClosure {
            return acceptClosure(competition)
        } else {
            return acceptReturnValue
        }
    }

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

    //MARK: - decline

    var declineCallsCount = 0
    var declineCalled: Bool {
        return declineCallsCount > 0
    }
    var declineReceivedCompetition: Competition?
    var declineReceivedInvocations: [Competition] = []
    var declineReturnValue: AnyPublisher<Void, Error>!
    var declineClosure: ((Competition) -> AnyPublisher<Void, Error>)?

    func decline(_ competition: Competition) -> AnyPublisher<Void, Error> {
        declineCallsCount += 1
        declineReceivedCompetition = competition
        declineReceivedInvocations.append(competition)
        if let declineClosure = declineClosure {
            return declineClosure(competition)
        } else {
            return declineReturnValue
        }
    }

    //MARK: - delete

    var deleteCallsCount = 0
    var deleteCalled: Bool {
        return deleteCallsCount > 0
    }
    var deleteReceivedCompetition: Competition?
    var deleteReceivedInvocations: [Competition] = []
    var deleteReturnValue: AnyPublisher<Void, Error>!
    var deleteClosure: ((Competition) -> AnyPublisher<Void, Error>)?

    func delete(_ competition: Competition) -> AnyPublisher<Void, Error> {
        deleteCallsCount += 1
        deleteReceivedCompetition = competition
        deleteReceivedInvocations.append(competition)
        if let deleteClosure = deleteClosure {
            return deleteClosure(competition)
        } else {
            return deleteReturnValue
        }
    }

    //MARK: - invite

    var inviteToCallsCount = 0
    var inviteToCalled: Bool {
        return inviteToCallsCount > 0
    }
    var inviteToReceivedArguments: (user: User, competition: Competition)?
    var inviteToReceivedInvocations: [(user: User, competition: Competition)] = []
    var inviteToReturnValue: AnyPublisher<Void, Error>!
    var inviteToClosure: ((User, Competition) -> AnyPublisher<Void, Error>)?

    func invite(_ user: User, to competition: Competition) -> AnyPublisher<Void, Error> {
        inviteToCallsCount += 1
        inviteToReceivedArguments = (user: user, competition: competition)
        inviteToReceivedInvocations.append((user: user, competition: competition))
        if let inviteToClosure = inviteToClosure {
            return inviteToClosure(user, competition)
        } else {
            return inviteToReturnValue
        }
    }

    //MARK: - join

    var joinCallsCount = 0
    var joinCalled: Bool {
        return joinCallsCount > 0
    }
    var joinReceivedCompetition: Competition?
    var joinReceivedInvocations: [Competition] = []
    var joinReturnValue: AnyPublisher<Void, Error>!
    var joinClosure: ((Competition) -> AnyPublisher<Void, Error>)?

    func join(_ competition: Competition) -> AnyPublisher<Void, Error> {
        joinCallsCount += 1
        joinReceivedCompetition = competition
        joinReceivedInvocations.append(competition)
        if let joinClosure = joinClosure {
            return joinClosure(competition)
        } else {
            return joinReturnValue
        }
    }

    //MARK: - leave

    var leaveCallsCount = 0
    var leaveCalled: Bool {
        return leaveCallsCount > 0
    }
    var leaveReceivedCompetition: Competition?
    var leaveReceivedInvocations: [Competition] = []
    var leaveReturnValue: AnyPublisher<Void, Error>!
    var leaveClosure: ((Competition) -> AnyPublisher<Void, Error>)?

    func leave(_ competition: Competition) -> AnyPublisher<Void, Error> {
        leaveCallsCount += 1
        leaveReceivedCompetition = competition
        leaveReceivedInvocations.append(competition)
        if let leaveClosure = leaveClosure {
            return leaveClosure(competition)
        } else {
            return leaveReturnValue
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

    //MARK: - participants

    var participantsForCallsCount = 0
    var participantsForCalled: Bool {
        return participantsForCallsCount > 0
    }
    var participantsForReceivedCompetitionsID: Competition.ID?
    var participantsForReceivedInvocations: [Competition.ID] = []
    var participantsForReturnValue: AnyPublisher<[User], Error>!
    var participantsForClosure: ((Competition.ID) -> AnyPublisher<[User], Error>)?

    func participants(for competitionsID: Competition.ID) -> AnyPublisher<[User], Error> {
        participantsForCallsCount += 1
        participantsForReceivedCompetitionsID = competitionsID
        participantsForReceivedInvocations.append(competitionsID)
        if let participantsForClosure = participantsForClosure {
            return participantsForClosure(competitionsID)
        } else {
            return participantsForReturnValue
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
class EnvironmentManagingMock: EnvironmentManaging {


    var firestoreEnvironment: FirestoreEnvironment {
        get { return underlyingFirestoreEnvironment }
        set(value) { underlyingFirestoreEnvironment = value }
    }
    var underlyingFirestoreEnvironment: FirestoreEnvironment!
    var firestoreEnvironmentDidChange: AnyPublisher<Void, Never> {
        get { return underlyingFirestoreEnvironmentDidChange }
        set(value) { underlyingFirestoreEnvironmentDidChange = value }
    }
    var underlyingFirestoreEnvironmentDidChange: AnyPublisher<Void, Never>!


    //MARK: - set

    var setCallsCount = 0
    var setCalled: Bool {
        return setCallsCount > 0
    }
    var setReceivedEnvironment: FirestoreEnvironment?
    var setReceivedInvocations: [FirestoreEnvironment] = []
    var setClosure: ((FirestoreEnvironment) -> Void)?

    func set(_ environment: FirestoreEnvironment) {
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


    //MARK: - add

    var addUserCallsCount = 0
    var addUserCalled: Bool {
        return addUserCallsCount > 0
    }
    var addUserReceivedUser: User?
    var addUserReceivedInvocations: [User] = []
    var addUserReturnValue: AnyPublisher<Void, Error>!
    var addUserClosure: ((User) -> AnyPublisher<Void, Error>)?

    func add(user: User) -> AnyPublisher<Void, Error> {
        addUserCallsCount += 1
        addUserReceivedUser = user
        addUserReceivedInvocations.append(user)
        if let addUserClosure = addUserClosure {
            return addUserClosure(user)
        } else {
            return addUserReturnValue
        }
    }

    //MARK: - accept

    var acceptFriendRequestCallsCount = 0
    var acceptFriendRequestCalled: Bool {
        return acceptFriendRequestCallsCount > 0
    }
    var acceptFriendRequestReceivedFriendRequest: User?
    var acceptFriendRequestReceivedInvocations: [User] = []
    var acceptFriendRequestReturnValue: AnyPublisher<Void, Error>!
    var acceptFriendRequestClosure: ((User) -> AnyPublisher<Void, Error>)?

    func accept(friendRequest: User) -> AnyPublisher<Void, Error> {
        acceptFriendRequestCallsCount += 1
        acceptFriendRequestReceivedFriendRequest = friendRequest
        acceptFriendRequestReceivedInvocations.append(friendRequest)
        if let acceptFriendRequestClosure = acceptFriendRequestClosure {
            return acceptFriendRequestClosure(friendRequest)
        } else {
            return acceptFriendRequestReturnValue
        }
    }

    //MARK: - decline

    var declineFriendRequestCallsCount = 0
    var declineFriendRequestCalled: Bool {
        return declineFriendRequestCallsCount > 0
    }
    var declineFriendRequestReceivedFriendRequest: User?
    var declineFriendRequestReceivedInvocations: [User] = []
    var declineFriendRequestReturnValue: AnyPublisher<Void, Error>!
    var declineFriendRequestClosure: ((User) -> AnyPublisher<Void, Error>)?

    func decline(friendRequest: User) -> AnyPublisher<Void, Error> {
        declineFriendRequestCallsCount += 1
        declineFriendRequestReceivedFriendRequest = friendRequest
        declineFriendRequestReceivedInvocations.append(friendRequest)
        if let declineFriendRequestClosure = declineFriendRequestClosure {
            return declineFriendRequestClosure(friendRequest)
        } else {
            return declineFriendRequestReturnValue
        }
    }

    //MARK: - delete

    var deleteFriendCallsCount = 0
    var deleteFriendCalled: Bool {
        return deleteFriendCallsCount > 0
    }
    var deleteFriendReceivedFriend: User?
    var deleteFriendReceivedInvocations: [User] = []
    var deleteFriendReturnValue: AnyPublisher<Void, Error>!
    var deleteFriendClosure: ((User) -> AnyPublisher<Void, Error>)?

    func delete(friend: User) -> AnyPublisher<Void, Error> {
        deleteFriendCallsCount += 1
        deleteFriendReceivedFriend = friend
        deleteFriendReceivedInvocations.append(friend)
        if let deleteFriendClosure = deleteFriendClosure {
            return deleteFriendClosure(friend)
        } else {
            return deleteFriendReturnValue
        }
    }

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
class NotificationManagingMock: NotificationManaging {


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
