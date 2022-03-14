final class MockFriendsManager: AnyFriendsManager {

    override init() {
        super.init()
        setupAppStorePreviewContent()
    }

    private func setupAppStorePreviewContent() {
        friends = [User.andrew, .gabby]
        friendActivitySummaries = friends.reduce(into: [:]) { partialResult, friend in
            partialResult[friend.id] = .mock
        }
    }
}
