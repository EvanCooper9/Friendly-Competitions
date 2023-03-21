import Factory

extension Container {
    var appState: Factory<AppStateProviding> {
        Factory(self) { AppState() }.scope(.shared)
    }
}
