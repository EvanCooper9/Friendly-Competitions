@testable import FriendlyCompetitions

extension User {
    func with(friends: [User.ID]) -> User {
        var user = self
        user.friends = friends
        return user
    }
    
    func with(friendRequests: [User.ID]) -> User {
        var user = self
        user.incomingFriendRequests = friendRequests
        return user
    }
}
