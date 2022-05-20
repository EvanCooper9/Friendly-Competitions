import Combine

final class AppState: ObservableObject {
    @Published var hudState: HUDState?
}
