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
class AppStateProvidingMock: AppStateProviding {


    var rootTab: AnyPublisher<RootTab, Never> {
        get { return underlyingRootTab }
        set(value) { underlyingRootTab = value }
    }
    var underlyingRootTab: AnyPublisher<RootTab, Never>!
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
    var isActive: AnyPublisher<Bool, Never> {
        get { return underlyingIsActive }
        set(value) { underlyingIsActive = value }
    }
    var underlyingIsActive: AnyPublisher<Bool, Never>!


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

    //MARK: - set

    var setRootTabCallsCount = 0
    var setRootTabCalled: Bool {
        return setRootTabCallsCount > 0
    }
    var setRootTabReceivedRootTab: RootTab?
    var setRootTabReceivedInvocations: [RootTab] = []
    var setRootTabClosure: ((RootTab) -> Void)?

    func set(rootTab: RootTab) {
        setRootTabCallsCount += 1
        setRootTabReceivedRootTab = rootTab
        setRootTabReceivedInvocations.append(rootTab)
        setRootTabClosure?(rootTab)
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
    var isAnonymous: Bool {
        get { return underlyingIsAnonymous }
        set(value) { underlyingIsAnonymous = value }
    }
    var underlyingIsAnonymous: Bool!
    var hasSWA: Bool {
        get { return underlyingHasSWA }
        set(value) { underlyingHasSWA = value }
    }
    var underlyingHasSWA: Bool!


    //MARK: - link

    var linkWithCallsCount = 0
    var linkWithCalled: Bool {
        return linkWithCallsCount > 0
    }
    var linkWithReceivedCredential: AuthCredential?
    var linkWithReceivedInvocations: [AuthCredential] = []
    var linkWithReturnValue: AnyPublisher<Void, Error>!
    var linkWithClosure: ((AuthCredential) -> AnyPublisher<Void, Error>)?

    func link(with credential: AuthCredential) -> AnyPublisher<Void, Error> {
        linkWithCallsCount += 1
        linkWithReceivedCredential = credential
        linkWithReceivedInvocations.append(credential)
        if let linkWithClosure = linkWithClosure {
            return linkWithClosure(credential)
        } else {
            return linkWithReturnValue
        }
    }

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

    //MARK: - shouldReauthenticate

    var shouldReauthenticateCallsCount = 0
    var shouldReauthenticateCalled: Bool {
        return shouldReauthenticateCallsCount > 0
    }
    var shouldReauthenticateReturnValue: AnyPublisher<Bool, Error>!
    var shouldReauthenticateClosure: (() -> AnyPublisher<Bool, Error>)?

    func shouldReauthenticate() -> AnyPublisher<Bool, Error> {
        shouldReauthenticateCallsCount += 1
        if let shouldReauthenticateClosure = shouldReauthenticateClosure {
            return shouldReauthenticateClosure()
        } else {
            return shouldReauthenticateReturnValue
        }
    }

    //MARK: - reauthenticate

    var reauthenticateCallsCount = 0
    var reauthenticateCalled: Bool {
        return reauthenticateCallsCount > 0
    }
    var reauthenticateReturnValue: AnyPublisher<Void, Error>!
    var reauthenticateClosure: (() -> AnyPublisher<Void, Error>)?

    func reauthenticate() -> AnyPublisher<Void, Error> {
        reauthenticateCallsCount += 1
        if let reauthenticateClosure = reauthenticateClosure {
            return reauthenticateClosure()
        } else {
            return reauthenticateReturnValue
        }
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
class BackgroundRefreshManagingMock: BackgroundRefreshManaging {


    var status: AnyPublisher<BackgroundRefreshStatus, Never> {
        get { return underlyingStatus }
        set(value) { underlyingStatus = value }
    }
    var underlyingStatus: AnyPublisher<BackgroundRefreshStatus, Never>!


}
class BannerManagingMock: BannerManaging {


    var banners: AnyPublisher<[Banner], Never> {
        get { return underlyingBanners }
        set(value) { underlyingBanners = value }
    }
    var underlyingBanners: AnyPublisher<[Banner], Never>!


    //MARK: - tapped

    var tappedCallsCount = 0
    var tappedCalled: Bool {
        return tappedCallsCount > 0
    }
    var tappedReceivedBanner: Banner?
    var tappedReceivedInvocations: [Banner] = []
    var tappedReturnValue: AnyPublisher<Void, Never>!
    var tappedClosure: ((Banner) -> AnyPublisher<Void, Never>)?

    func tapped(_ banner: Banner) -> AnyPublisher<Void, Never> {
        tappedCallsCount += 1
        tappedReceivedBanner = banner
        tappedReceivedInvocations.append(banner)
        if let tappedClosure = tappedClosure {
            return tappedClosure(banner)
        } else {
            return tappedReturnValue
        }
    }

    //MARK: - dismissed

    var dismissedCallsCount = 0
    var dismissedCalled: Bool {
        return dismissedCallsCount > 0
    }
    var dismissedReceivedBanner: Banner?
    var dismissedReceivedInvocations: [Banner] = []
    var dismissedReturnValue: AnyPublisher<Void, Never>!
    var dismissedClosure: ((Banner) -> AnyPublisher<Void, Never>)?

    func dismissed(_ banner: Banner) -> AnyPublisher<Void, Never> {
        dismissedCallsCount += 1
        dismissedReceivedBanner = banner
        dismissedReceivedInvocations.append(banner)
        if let dismissedClosure = dismissedClosure {
            return dismissedClosure(banner)
        } else {
            return dismissedReturnValue
        }
    }

    //MARK: - resetDismissed

    var resetDismissedCallsCount = 0
    var resetDismissedCalled: Bool {
        return resetDismissedCallsCount > 0
    }
    var resetDismissedClosure: (() -> Void)?

    func resetDismissed() {
        resetDismissedCallsCount += 1
        resetDismissedClosure?()
    }

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
    var unseenResults: AnyPublisher<[(Competition, CompetitionResult.ID)], Never> {
        get { return underlyingUnseenResults }
        set(value) { underlyingUnseenResults = value }
    }
    var underlyingUnseenResults: AnyPublisher<[(Competition, CompetitionResult.ID)], Never>!


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

    //MARK: - viewedResults

    var viewedResultsCompetitionIDResultIDCallsCount = 0
    var viewedResultsCompetitionIDResultIDCalled: Bool {
        return viewedResultsCompetitionIDResultIDCallsCount > 0
    }
    var viewedResultsCompetitionIDResultIDReceivedArguments: (competitionID: Competition.ID, resultID: CompetitionResult.ID)?
    var viewedResultsCompetitionIDResultIDReceivedInvocations: [(competitionID: Competition.ID, resultID: CompetitionResult.ID)] = []
    var viewedResultsCompetitionIDResultIDClosure: ((Competition.ID, CompetitionResult.ID) -> Void)?

    func viewedResults(competitionID: Competition.ID, resultID: CompetitionResult.ID) {
        viewedResultsCompetitionIDResultIDCallsCount += 1
        viewedResultsCompetitionIDResultIDReceivedArguments = (competitionID: competitionID, resultID: resultID)
        viewedResultsCompetitionIDResultIDReceivedInvocations.append((competitionID: competitionID, resultID: resultID))
        viewedResultsCompetitionIDResultIDClosure?(competitionID, resultID)
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

    var standingsPublisherForLimitCallsCount = 0
    var standingsPublisherForLimitCalled: Bool {
        return standingsPublisherForLimitCallsCount > 0
    }
    var standingsPublisherForLimitReceivedArguments: (competitionID: Competition.ID, limit: Int)?
    var standingsPublisherForLimitReceivedInvocations: [(competitionID: Competition.ID, limit: Int)] = []
    var standingsPublisherForLimitReturnValue: AnyPublisher<[Competition.Standing], Error>!
    var standingsPublisherForLimitClosure: ((Competition.ID, Int) -> AnyPublisher<[Competition.Standing], Error>)?

    func standingsPublisher(for competitionID: Competition.ID, limit: Int) -> AnyPublisher<[Competition.Standing], Error> {
        standingsPublisherForLimitCallsCount += 1
        standingsPublisherForLimitReceivedArguments = (competitionID: competitionID, limit: limit)
        standingsPublisherForLimitReceivedInvocations.append((competitionID: competitionID, limit: limit))
        if let standingsPublisherForLimitClosure = standingsPublisherForLimitClosure {
            return standingsPublisherForLimitClosure(competitionID, limit)
        } else {
            return standingsPublisherForLimitReturnValue
        }
    }

    //MARK: - standing

    var standingForUserIDCallsCount = 0
    var standingForUserIDCalled: Bool {
        return standingForUserIDCallsCount > 0
    }
    var standingForUserIDReceivedArguments: (competitionID: Competition.ID, userID: User.ID)?
    var standingForUserIDReceivedInvocations: [(competitionID: Competition.ID, userID: User.ID)] = []
    var standingForUserIDReturnValue: AnyPublisher<Competition.Standing, Error>!
    var standingForUserIDClosure: ((Competition.ID, User.ID) -> AnyPublisher<Competition.Standing, Error>)?

    func standing(for competitionID: Competition.ID, userID: User.ID) -> AnyPublisher<Competition.Standing, Error> {
        standingForUserIDCallsCount += 1
        standingForUserIDReceivedArguments = (competitionID: competitionID, userID: userID)
        standingForUserIDReceivedInvocations.append((competitionID: competitionID, userID: userID))
        if let standingForUserIDClosure = standingForUserIDClosure {
            return standingForUserIDClosure(competitionID, userID)
        } else {
            return standingForUserIDReturnValue
        }
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
class HealthKitManagingMock: HealthKitManaging {


    var permissionsChanged: AnyPublisher<Void, Never> {
        get { return underlyingPermissionsChanged }
        set(value) { underlyingPermissionsChanged = value }
    }
    var underlyingPermissionsChanged: AnyPublisher<Void, Never>!


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

    var registerBackgroundDeliveryTaskForTaskCallsCount = 0
    var registerBackgroundDeliveryTaskForTaskCalled: Bool {
        return registerBackgroundDeliveryTaskForTaskCallsCount > 0
    }
    var registerBackgroundDeliveryTaskForTaskReceivedArguments: (permission: HealthKitPermissionType, task: HealthKitBackgroundDeliveryTask)?
    var registerBackgroundDeliveryTaskForTaskReceivedInvocations: [(permission: HealthKitPermissionType, task: HealthKitBackgroundDeliveryTask)] = []
    var registerBackgroundDeliveryTaskForTaskClosure: ((HealthKitPermissionType, @escaping HealthKitBackgroundDeliveryTask) -> Void)?

    func registerBackgroundDeliveryTask(for permission: HealthKitPermissionType, task: @escaping HealthKitBackgroundDeliveryTask) {
        registerBackgroundDeliveryTaskForTaskCallsCount += 1
        registerBackgroundDeliveryTaskForTaskReceivedArguments = (permission: permission, task: task)
        registerBackgroundDeliveryTaskForTaskReceivedInvocations.append((permission: permission, task: task))
        registerBackgroundDeliveryTaskForTaskClosure?(permission, task)
    }

    //MARK: - registerForBackgroundDelivery

    var registerForBackgroundDeliveryCallsCount = 0
    var registerForBackgroundDeliveryCalled: Bool {
        return registerForBackgroundDeliveryCallsCount > 0
    }
    var registerForBackgroundDeliveryClosure: (() -> Void)?

    func registerForBackgroundDelivery() {
        registerForBackgroundDeliveryCallsCount += 1
        registerForBackgroundDeliveryClosure?()
    }

    //MARK: - shouldRequest

    var shouldRequestCallsCount = 0
    var shouldRequestCalled: Bool {
        return shouldRequestCallsCount > 0
    }
    var shouldRequestReceivedPermissions: [HealthKitPermissionType]?
    var shouldRequestReceivedInvocations: [[HealthKitPermissionType]] = []
    var shouldRequestReturnValue: AnyPublisher<Bool, Error>!
    var shouldRequestClosure: (([HealthKitPermissionType]) -> AnyPublisher<Bool, Error>)?

    func shouldRequest(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error> {
        shouldRequestCallsCount += 1
        shouldRequestReceivedPermissions = permissions
        shouldRequestReceivedInvocations.append(permissions)
        if let shouldRequestClosure = shouldRequestClosure {
            return shouldRequestClosure(permissions)
        } else {
            return shouldRequestReturnValue
        }
    }

    //MARK: - request

    var requestCallsCount = 0
    var requestCalled: Bool {
        return requestCallsCount > 0
    }
    var requestReceivedPermissions: [HealthKitPermissionType]?
    var requestReceivedInvocations: [[HealthKitPermissionType]] = []
    var requestReturnValue: AnyPublisher<Void, Error>!
    var requestClosure: (([HealthKitPermissionType]) -> AnyPublisher<Void, Error>)?

    func request(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Void, Error> {
        requestCallsCount += 1
        requestReceivedPermissions = permissions
        requestReceivedInvocations.append(permissions)
        if let requestClosure = requestClosure {
            return requestClosure(permissions)
        } else {
            return requestReturnValue
        }
    }

}
class HealthStoringMock: HealthStoring {




    //MARK: - disableBackgroundDelivery

    var disableBackgroundDeliveryForCallsCount = 0
    var disableBackgroundDeliveryForCalled: Bool {
        return disableBackgroundDeliveryForCallsCount > 0
    }
    var disableBackgroundDeliveryForReceivedPermissionType: HealthKitPermissionType?
    var disableBackgroundDeliveryForReceivedInvocations: [HealthKitPermissionType] = []
    var disableBackgroundDeliveryForReturnValue: AnyPublisher<Bool, Error>!
    var disableBackgroundDeliveryForClosure: ((HealthKitPermissionType) -> AnyPublisher<Bool, Error>)?

    func disableBackgroundDelivery(for permissionType: HealthKitPermissionType) -> AnyPublisher<Bool, Error> {
        disableBackgroundDeliveryForCallsCount += 1
        disableBackgroundDeliveryForReceivedPermissionType = permissionType
        disableBackgroundDeliveryForReceivedInvocations.append(permissionType)
        if let disableBackgroundDeliveryForClosure = disableBackgroundDeliveryForClosure {
            return disableBackgroundDeliveryForClosure(permissionType)
        } else {
            return disableBackgroundDeliveryForReturnValue
        }
    }

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
    var enableBackgroundDeliveryForReturnValue: AnyPublisher<Bool, Error>!
    var enableBackgroundDeliveryForClosure: ((HealthKitPermissionType) -> AnyPublisher<Bool, Error>)?

    func enableBackgroundDelivery(for permissionType: HealthKitPermissionType) -> AnyPublisher<Bool, Error> {
        enableBackgroundDeliveryForCallsCount += 1
        enableBackgroundDeliveryForReceivedPermissionType = permissionType
        enableBackgroundDeliveryForReceivedInvocations.append(permissionType)
        if let enableBackgroundDeliveryForClosure = enableBackgroundDeliveryForClosure {
            return enableBackgroundDeliveryForClosure(permissionType)
        } else {
            return enableBackgroundDeliveryForReturnValue
        }
    }

    //MARK: - shouldRequest

    var shouldRequestCallsCount = 0
    var shouldRequestCalled: Bool {
        return shouldRequestCallsCount > 0
    }
    var shouldRequestReceivedPermissions: [HealthKitPermissionType]?
    var shouldRequestReceivedInvocations: [[HealthKitPermissionType]] = []
    var shouldRequestReturnValue: AnyPublisher<Bool, Error>!
    var shouldRequestClosure: (([HealthKitPermissionType]) -> AnyPublisher<Bool, Error>)?

    func shouldRequest(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error> {
        shouldRequestCallsCount += 1
        shouldRequestReceivedPermissions = permissions
        shouldRequestReceivedInvocations.append(permissions)
        if let shouldRequestClosure = shouldRequestClosure {
            return shouldRequestClosure(permissions)
        } else {
            return shouldRequestReturnValue
        }
    }

    //MARK: - request

    var requestCallsCount = 0
    var requestCalled: Bool {
        return requestCallsCount > 0
    }
    var requestReceivedPermissions: [HealthKitPermissionType]?
    var requestReceivedInvocations: [[HealthKitPermissionType]] = []
    var requestReturnValue: AnyPublisher<Bool, Error>!
    var requestClosure: (([HealthKitPermissionType]) -> AnyPublisher<Bool, Error>)?

    func request(_ permissions: [HealthKitPermissionType]) -> AnyPublisher<Bool, Error> {
        requestCallsCount += 1
        requestReceivedPermissions = permissions
        requestReceivedInvocations.append(permissions)
        if let requestClosure = requestClosure {
            return requestClosure(permissions)
        } else {
            return requestReturnValue
        }
    }

}
class NotificationsManagingMock: NotificationsManaging {




    //MARK: - setUp

    var setUpCallsCount = 0
    var setUpCalled: Bool {
        return setUpCallsCount > 0
    }
    var setUpClosure: (() -> Void)?

    func setUp() {
        setUpCallsCount += 1
        setUpClosure?()
    }

    //MARK: - permissionStatus

    var permissionStatusCallsCount = 0
    var permissionStatusCalled: Bool {
        return permissionStatusCallsCount > 0
    }
    var permissionStatusReturnValue: AnyPublisher<PermissionStatus, Never>!
    var permissionStatusClosure: (() -> AnyPublisher<PermissionStatus, Never>)?

    func permissionStatus() -> AnyPublisher<PermissionStatus, Never> {
        permissionStatusCallsCount += 1
        if let permissionStatusClosure = permissionStatusClosure {
            return permissionStatusClosure()
        } else {
            return permissionStatusReturnValue
        }
    }

    //MARK: - requestPermissions

    var requestPermissionsCallsCount = 0
    var requestPermissionsCalled: Bool {
        return requestPermissionsCallsCount > 0
    }
    var requestPermissionsReturnValue: AnyPublisher<Bool, Error>!
    var requestPermissionsClosure: (() -> AnyPublisher<Bool, Error>)?

    func requestPermissions() -> AnyPublisher<Bool, Error> {
        requestPermissionsCallsCount += 1
        if let requestPermissionsClosure = requestPermissionsClosure {
            return requestPermissionsClosure()
        } else {
            return requestPermissionsReturnValue
        }
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

    //MARK: - link

    var linkWithCallsCount = 0
    var linkWithCalled: Bool {
        return linkWithCallsCount > 0
    }
    var linkWithReceivedUser: AuthUser?
    var linkWithReceivedInvocations: [AuthUser] = []
    var linkWithReturnValue: AnyPublisher<AuthUser, Error>!
    var linkWithClosure: ((AuthUser) -> AnyPublisher<AuthUser, Error>)?

    func link(with user: AuthUser) -> AnyPublisher<AuthUser, Error> {
        linkWithCallsCount += 1
        linkWithReceivedUser = user
        linkWithReceivedInvocations.append(user)
        if let linkWithClosure = linkWithClosure {
            return linkWithClosure(user)
        } else {
            return linkWithReturnValue
        }
    }

}
class StepCountManagingMock: StepCountManaging {




    //MARK: - stepCounts

    var stepCountsInCallsCount = 0
    var stepCountsInCalled: Bool {
        return stepCountsInCallsCount > 0
    }
    var stepCountsInReceivedDateInterval: DateInterval?
    var stepCountsInReceivedInvocations: [DateInterval] = []
    var stepCountsInReturnValue: AnyPublisher<[StepCount], Error>!
    var stepCountsInClosure: ((DateInterval) -> AnyPublisher<[StepCount], Error>)?

    func stepCounts(in dateInterval: DateInterval) -> AnyPublisher<[StepCount], Error> {
        stepCountsInCallsCount += 1
        stepCountsInReceivedDateInterval = dateInterval
        stepCountsInReceivedInvocations.append(dateInterval)
        if let stepCountsInClosure = stepCountsInClosure {
            return stepCountsInClosure(dateInterval)
        } else {
            return stepCountsInReturnValue
        }
    }

}
class StorageManagingMock: StorageManaging {




    //MARK: - get

    var getCallsCount = 0
    var getCalled: Bool {
        return getCallsCount > 0
    }
    var getReceivedPath: String?
    var getReceivedInvocations: [String] = []
    var getReturnValue: AnyPublisher<Data, Error>!
    var getClosure: ((String) -> AnyPublisher<Data, Error>)?

    func get(_ path: String) -> AnyPublisher<Data, Error> {
        getCallsCount += 1
        getReceivedPath = path
        getReceivedInvocations.append(path)
        if let getClosure = getClosure {
            return getClosure(path)
        } else {
            return getReturnValue
        }
    }

    //MARK: - set

    var setDataCallsCount = 0
    var setDataCalled: Bool {
        return setDataCallsCount > 0
    }
    var setDataReceivedArguments: (path: String, data: Data?)?
    var setDataReceivedInvocations: [(path: String, data: Data?)] = []
    var setDataReturnValue: AnyPublisher<Void, Error>!
    var setDataClosure: ((String, Data?) -> AnyPublisher<Void, Error>)?

    func set(_ path: String, data: Data?) -> AnyPublisher<Void, Error> {
        setDataCallsCount += 1
        setDataReceivedArguments = (path: path, data: data)
        setDataReceivedInvocations.append((path: path, data: data))
        if let setDataClosure = setDataClosure {
            return setDataClosure(path, data)
        } else {
            return setDataReturnValue
        }
    }

    //MARK: - clear

    var clearTtlCallsCount = 0
    var clearTtlCalled: Bool {
        return clearTtlCallsCount > 0
    }
    var clearTtlReceivedTtl: TimeInterval?
    var clearTtlReceivedInvocations: [TimeInterval] = []
    var clearTtlClosure: ((TimeInterval) -> Void)?

    func clear(ttl: TimeInterval) {
        clearTtlCallsCount += 1
        clearTtlReceivedTtl = ttl
        clearTtlReceivedInvocations.append(ttl)
        clearTtlClosure?(ttl)
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
