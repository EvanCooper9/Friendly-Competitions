import AlgoliaSearchClient
import Factory

extension Container {
    var searchClient: Factory<SearchClient> {
        self { AlgoliaSearchClient.SearchClient() }.scope(.shared)
    }

    var searchManager: Factory<SearchManaging> {
        self { SearchManager() }.scope(.shared)
    }
}
