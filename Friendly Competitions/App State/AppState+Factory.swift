import Factory

extension Container {
    static let appState = Factory<AppStateProviding>(scope: .shared, factory: AppState.init)
}
