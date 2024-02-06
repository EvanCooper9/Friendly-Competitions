import Factory

extension Container {
    var appState: Factory<AppStateProviding> {
        self { AppState() }.scope(.shared)
    }
}
