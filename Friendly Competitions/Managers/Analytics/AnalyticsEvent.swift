enum AnalyticsEvent: Codable {

    // competitions
    case acceptCompetition(id: String)
    case createCompetition(name: String)
    case declineCompetition(id: String)
    case deleteCompetition(id: String)
    case inviteFriendToCompetition(id: String, friendId: String)
    case joinCompetition(id: String)
    case leaveCompetition(id: String)

    // permissions
    case notificationPermissions(authorized: Bool)
    case healthKitPermissions(authorized: Bool)

    // errors
    case decodingError(error: String)
}
