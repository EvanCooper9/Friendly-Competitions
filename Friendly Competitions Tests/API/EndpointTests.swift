@testable import Friendly_Competitions
import XCTest

final class EndpointTests: FCTestCase {
    func testName() {
        let endpoints: [Endpoint] = [
            .joinCompetition(id: "competitionID"),
            .leaveCompetition(id: "competitionID"),
            .respondToCompetitionInvite(id: "competitionID", accept: true),
            .inviteUserToCompetition(competitionID: "competitionID", userID: "userID"),
            .deleteCompetition(id: "competitionID"),
            .sendFriendRequest(id: "userID"),
            .respondToFriendRequest(from: "userID", accept: true),
            .deleteFriend(id: "userID"),
            .saveSWAToken(code: "code"),
            .deleteAccount,
            .dev_sendCompetitionCompleteNotification
        ]

        let expectedNames = [
            "joinCompetition",
            "leaveCompetition",
            "respondToCompetitionInvite",
            "inviteUserToCompetition",
            "deleteCompetition",
            "sendFriendRequest",
            "respondToFriendRequest",
            "deleteFriend",
            "saveSWAToken",
            "deleteAccount",
            "dev_sendCompetitionCompleteNotification"
        ]

        zip(endpoints, expectedNames).forEach { endpoint, expectedName in
            XCTAssertEqual(endpoint.name, expectedName)
        }
    }

    func testData() {
        let endpoints: [Endpoint] = [
            .joinCompetition(id: "competitionID"),
            .leaveCompetition(id: "competitionID"),
            .respondToCompetitionInvite(id: "competitionID", accept: true),
            .inviteUserToCompetition(competitionID: "competitionID", userID: "userID"),
            .deleteCompetition(id: "competitionID"),
            .sendFriendRequest(id: "userID"),
            .respondToFriendRequest(from: "userID", accept: true),
            .deleteFriend(id: "userID"),
            .saveSWAToken(code: "code"),
            .deleteAccount,
            .dev_sendCompetitionCompleteNotification
        ]

        let expectedData: [[String: Any]?] = [
            ["competitionID": "competitionID"],
            ["competitionID": "competitionID"],
            ["competitionID": "competitionID", "accept": true],
            ["competitionID": "competitionID", "userID": "userID"],
            ["competitionID": "competitionID"],
            ["userID": "userID"],
            ["userID": "userID", "accept": true],
            ["userID": "userID"],
            ["code": "code"],
            nil,
            nil
        ]

        zip(endpoints, expectedData).forEach { endpoint, expected in
            if let data = endpoint.data {
                data.forEach { key, value in
                    guard let expectedValue = expected?[key] else {
                        XCTFail("Missing value")
                        return
                    }
                    XCTAssertEqual("\(value)", "\(expectedValue)")
                }
            } else {
                XCTAssertNil(expected)
            }
        }
    }
}
