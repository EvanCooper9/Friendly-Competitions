// sourcery: AutoMockable
protocol SearchClient {
    func index(withName name: String) -> SearchIndex
}
