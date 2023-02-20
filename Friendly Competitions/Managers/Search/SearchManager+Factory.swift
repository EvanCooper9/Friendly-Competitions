import Factory

extension Container {
    static let searchManager = Factory<SearchManaging>(scope: .shared, factory: SearchManager.init)
}
