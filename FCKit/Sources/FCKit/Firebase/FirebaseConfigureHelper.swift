import Firebase

extension FirebaseApp {
    private static var hasConfigured = false
    public static func configureIfRequired() {
        guard !FirebaseApp.hasConfigured else { return }
        FirebaseApp.configure()
        FirebaseApp.hasConfigured = true
    }
}
