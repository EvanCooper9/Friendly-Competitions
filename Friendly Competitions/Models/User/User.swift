import Foundation

struct Record {
    let totalCompetitions: Int
    let golds: Int
    let silvers: Int
    let bronzes: Int
}

enum Role: String, Codable {
    case general
    case developer
}

final class User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    var friends = [String]()
    var incomingFriendRequests = [String]()
    var outgoingFriendRequests = [String]()
    var notificationTokens: [String]? = []
    var role: Role? = .general
    var statistics: Statistics? = .zero

    var tempActivitySummary: ActivitySummary? = nil

    var hashId: String {
        let endIndex = id.index(id.startIndex, offsetBy: 4)
        return "#" + id[..<endIndex].uppercased()
    }

    init(id: String, email: String, name: String) {
        self.id = id
        self.email = email
        self.name = name
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension User: ObservableObject {}