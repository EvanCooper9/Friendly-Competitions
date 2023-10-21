enum Endpoint {

    // Compeittions
    case joinCompetition(id: Competition.ID)
    case leaveCompetition(id: Competition.ID)
    case respondToCompetitionInvite(id: Competition.ID, accept: Bool)
    case inviteUserToCompetition(competitionID: Competition.ID, userID: User.ID)
    case deleteCompetition(id: Competition.ID)

    // Friends
    case sendFriendRequest(id: User.ID)
    case respondToFriendRequest(from: User.ID, accept: Bool)
    case deleteFriend(id: User.ID)

    // Account
    case saveSWAToken(code: String)
    case deleteAccount

    // Developer
    case dev_sendCompetitionCompleteNotification

    var name: String {
        switch self {
        case .joinCompetition:
            return "joinCompetition"
        case .leaveCompetition:
            return "leaveCompetition"
        case .respondToCompetitionInvite:
            return "respondToCompetitionInvite"
        case .inviteUserToCompetition:
            return "inviteUserToCompetition"
        case .deleteCompetition:
            return "deleteCompetition"
        case .sendFriendRequest:
            return "sendFriendRequest"
        case .respondToFriendRequest:
            return "respondToFriendRequest"
        case .deleteFriend:
            return "deleteFriend"
        case .saveSWAToken:
            return "saveSWAToken"
        case .deleteAccount:
            return "deleteAccount"
        case .dev_sendCompetitionCompleteNotification:
            return "dev_sendCompetitionCompleteNotification"
        }
    }

    var data: [String: Any]? {
        underlyingData?.mapKeys(\.rawValue)
    }

    // MARK: - Private

    private enum Key: String {
        case accept
        case code
        case competitionID
        case userID
    }

    private var underlyingData: [Key: Any]? {
        switch self {
        case .joinCompetition(let id):
            return [.competitionID: id]
        case .leaveCompetition(let id):
            return [.competitionID: id]
        case .respondToCompetitionInvite(let id, let accept):
            return [.competitionID: id, .accept: accept]
        case .inviteUserToCompetition(let competitionID, let userID):
            return [.competitionID: competitionID, .userID: userID]
        case .deleteCompetition(let id):
            return [.competitionID: id]
        case .sendFriendRequest(let id):
            return [.userID: id]
        case .respondToFriendRequest(let from, let accept):
            return [.userID: from, .accept: accept]
        case .deleteFriend(let id):
            return [.userID: id]
        case .saveSWAToken(let code):
            return [.code: code]
        case .deleteAccount:
            return nil
        case .dev_sendCompetitionCompleteNotification:
            return nil
        }
    }
}
