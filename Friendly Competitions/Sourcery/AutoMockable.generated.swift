// Generated using Sourcery 1.8.1 — https://github.com/krzysztofzablocki/Sourcery
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
    var standings: AnyPublisher<[Competition.ID : [Competition.Standing]], Never> {
        get { return underlyingStandings }
        set(value) { underlyingStandings = value }
    }
    var underlyingStandings: AnyPublisher<[Competition.ID : [Competition.Standing]], Never>!
    var participants: AnyPublisher<[Competition.ID: [User]], Never> {
        get { return underlyingParticipants }
        set(value) { underlyingParticipants = value }
    }
    var underlyingParticipants: AnyPublisher<[Competition.ID: [User]], Never>!
    var pendingParticipants: AnyPublisher<[Competition.ID: [User]], Never> {
        get { return underlyingPendingParticipants }
        set(value) { underlyingPendingParticipants = value }
    }
    var underlyingPendingParticipants: AnyPublisher<[Competition.ID: [User]], Never>!
    var appOwnedCompetitions: AnyPublisher<[Competition], Never> {
        get { return underlyingAppOwnedCompetitions }
        set(value) { underlyingAppOwnedCompetitions = value }
    }
    var underlyingAppOwnedCompetitions: AnyPublisher<[Competition], Never>!
    var topCommunityCompetitions: AnyPublisher<[Competition], Never> {
        get { return underlyingTopCommunityCompetitions }
        set(value) { underlyingTopCommunityCompetitions = value }
    }
    var underlyingTopCommunityCompetitions: AnyPublisher<[Competition], Never>!

    //MARK: - accept

    var acceptCallsCount = 0
    var acceptCalled: Bool {
        return acceptCallsCount > 0
    }
    var acceptReceivedCompetition: Competition?
    var acceptReceivedInvocations: [Competition] = []
    var acceptClosure: ((Competition) -> Void)?

    func accept(_ competition: Competition) {
        acceptCallsCount += 1
        acceptReceivedCompetition = competition
        acceptReceivedInvocations.append(competition)
        acceptClosure?(competition)
    }

    //MARK: - create

    var createCallsCount = 0
    var createCalled: Bool {
        return createCallsCount > 0
    }
    var createReceivedCompetition: Competition?
    var createReceivedInvocations: [Competition] = []
    var createClosure: ((Competition) -> Void)?

    func create(_ competition: Competition) {
        createCallsCount += 1
        createReceivedCompetition = competition
        createReceivedInvocations.append(competition)
        createClosure?(competition)
    }

    //MARK: - decline

    var declineCallsCount = 0
    var declineCalled: Bool {
        return declineCallsCount > 0
    }
    var declineReceivedCompetition: Competition?
    var declineReceivedInvocations: [Competition] = []
    var declineClosure: ((Competition) -> Void)?

    func decline(_ competition: Competition) {
        declineCallsCount += 1
        declineReceivedCompetition = competition
        declineReceivedInvocations.append(competition)
        declineClosure?(competition)
    }

    //MARK: - delete

    var deleteCallsCount = 0
    var deleteCalled: Bool {
        return deleteCallsCount > 0
    }
    var deleteReceivedCompetition: Competition?
    var deleteReceivedInvocations: [Competition] = []
    var deleteClosure: ((Competition) -> Void)?

    func delete(_ competition: Competition) {
        deleteCallsCount += 1
        deleteReceivedCompetition = competition
        deleteReceivedInvocations.append(competition)
        deleteClosure?(competition)
    }

    //MARK: - invite

    var inviteToCallsCount = 0
    var inviteToCalled: Bool {
        return inviteToCallsCount > 0
    }
    var inviteToReceivedArguments: (user: User, competition: Competition)?
    var inviteToReceivedInvocations: [(user: User, competition: Competition)] = []
    var inviteToClosure: ((User, Competition) -> Void)?

    func invite(_ user: User, to competition: Competition) {
        inviteToCallsCount += 1
        inviteToReceivedArguments = (user: user, competition: competition)
        inviteToReceivedInvocations.append((user: user, competition: competition))
        inviteToClosure?(user, competition)
    }

    //MARK: - join

    var joinCallsCount = 0
    var joinCalled: Bool {
        return joinCallsCount > 0
    }
    var joinReceivedCompetition: Competition?
    var joinReceivedInvocations: [Competition] = []
    var joinClosure: ((Competition) -> Void)?

    func join(_ competition: Competition) {
        joinCallsCount += 1
        joinReceivedCompetition = competition
        joinReceivedInvocations.append(competition)
        joinClosure?(competition)
    }

    //MARK: - leave

    var leaveCallsCount = 0
    var leaveCalled: Bool {
        return leaveCallsCount > 0
    }
    var leaveReceivedCompetition: Competition?
    var leaveReceivedInvocations: [Competition] = []
    var leaveClosure: ((Competition) -> Void)?

    func leave(_ competition: Competition) {
        leaveCallsCount += 1
        leaveReceivedCompetition = competition
        leaveReceivedInvocations.append(competition)
        leaveClosure?(competition)
    }

    //MARK: - update

    var updateCallsCount = 0
    var updateCalled: Bool {
        return updateCallsCount > 0
    }
    var updateReceivedCompetition: Competition?
    var updateReceivedInvocations: [Competition] = []
    var updateClosure: ((Competition) -> Void)?

    func update(_ competition: Competition) {
        updateCallsCount += 1
        updateReceivedCompetition = competition
        updateReceivedInvocations.append(competition)
        updateClosure?(competition)
    }

    //MARK: - search

    var searchThrowableError: Error?
    var searchCallsCount = 0
    var searchCalled: Bool {
        return searchCallsCount > 0
    }
    var searchReceivedSearchText: String?
    var searchReceivedInvocations: [String] = []
    var searchReturnValue: [Competition]!
    var searchClosure: ((String) async throws -> [Competition])?

    func search(_ searchText: String) async throws -> [Competition] {
        if let error = searchThrowableError {
            throw error
        }
        searchCallsCount += 1
        searchReceivedSearchText = searchText
        searchReceivedInvocations.append(searchText)
        if let searchClosure = searchClosure {
            return try await searchClosure(searchText)
        } else {
            return searchReturnValue
        }
    }

    //MARK: - search

    var searchByIDThrowableError: Error?
    var searchByIDCallsCount = 0
    var searchByIDCalled: Bool {
        return searchByIDCallsCount > 0
    }
    var searchByIDReceivedCompetitionID: Competition.ID?
    var searchByIDReceivedInvocations: [Competition.ID] = []
    var searchByIDReturnValue: Competition!
    var searchByIDClosure: ((Competition.ID) async throws -> Competition)?

    func search(byID competitionID: Competition.ID) async throws -> Competition {
        if let error = searchByIDThrowableError {
            throw error
        }
        searchByIDCallsCount += 1
        searchByIDReceivedCompetitionID = competitionID
        searchByIDReceivedInvocations.append(competitionID)
        if let searchByIDClosure = searchByIDClosure {
            return try await searchByIDClosure(competitionID)
        } else {
            return searchByIDReturnValue
        }
    }

    //MARK: - updateStandings

    var updateStandingsThrowableError: Error?
    var updateStandingsCallsCount = 0
    var updateStandingsCalled: Bool {
        return updateStandingsCallsCount > 0
    }
    var updateStandingsClosure: (() async throws -> Void)?

    func updateStandings() async throws {
        if let error = updateStandingsThrowableError {
            throw error
        }
        updateStandingsCallsCount += 1
        try await updateStandingsClosure?()
    }

}
