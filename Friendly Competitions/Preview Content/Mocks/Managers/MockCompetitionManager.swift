final class MockCompetitionManager: AnyCompetitionsManager {

    var searchResults = [Competition]()
    override func search(_ searchText: String) async throws -> [Competition] {
        searchResults
    }
}
