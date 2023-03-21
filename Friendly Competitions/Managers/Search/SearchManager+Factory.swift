import AlgoliaSearchClient
import Factory

extension Container {
    var searchClient: Factory<SearchClient>{
        Factory(self) { AlgoliaSearchClient.SearchClient() }.scope(.shared)
    }
    
    var searchManager: Factory<SearchManaging>{
        Factory(self) { SearchManager() }.scope(.shared)
    }
}
