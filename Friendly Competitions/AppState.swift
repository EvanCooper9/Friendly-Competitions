import Combine

final class AppState: ObservableObject {
    @Published var deepLink: DeepLink? = nil
    @Published var hudState: HUDState?
}
