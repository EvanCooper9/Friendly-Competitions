import AlgoliaSearchClient
import Factory

extension Container {
    static let searchClient = Factory<SearchClient>(scope: .shared, factory: AlgoliaSearchClient.SearchClient.init)
    static let searchManager = Factory<SearchManaging>(scope: .shared, factory: SearchManager.init)
}
