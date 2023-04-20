enum Endpoint {

    // Compeittions
    case joinCompetition
    case leaveCompetition
    case respondToCompetitionInvite
    case inviteUserToCompetition
    case deleteCompetition

    // Friends
    case sendFriendRequest
    case respondToFriendRequest
    case deleteFriend

    // Account
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
            return "repondToCompetitionInvite"
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
        case .deleteAccount:
            return "deleteAccount"
        case .dev_sendCompetitionCompleteNotification:
            return "dev_sendCompetitionCompleteNotification"
        }
    }
}
