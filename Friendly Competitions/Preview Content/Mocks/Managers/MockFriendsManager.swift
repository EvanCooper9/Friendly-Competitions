final class MockFriendsManager: AnyFriendsManager {

    override init() {
        super.init()
        setupAppStorePreviewContent()
    }

    private func setupAppStorePreviewContent() {
        friends = [User.andrew, .gabby]
            .map { friend -> User in
                friend.tempActivitySummary = .mock
                return friend
            }
    }
}
