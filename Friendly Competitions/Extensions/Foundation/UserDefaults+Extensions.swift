import Foundation

extension UserDefaults {
    enum Key: String, CaseIterable {
        case activitySummary
        case currentUser
        
        case competitions
        case invitedCompetitions
        case standings
        case participants
        case pendingParticipants
        case appOwnedCompetitions
        case topCommunityCompetitions
        
        case friends
        case friendActivitySummaries
    }
    
    func reset() {
        Key.allCases.forEach { key in
            removeObject(forKey: key.rawValue)
        }
    }
}

extension UserDefaults {
    func encode<T: Encodable>(_ data: T, forKey key: String) {
        set(try? JSONEncoder.shared.encode(data), forKey: key)
    }

    func decode<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder.shared.decode(T.self, from: data)
    }
}
