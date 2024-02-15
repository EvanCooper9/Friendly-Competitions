public enum AppGroup {
    public static var id: String {
        #if DEBUG
        return "group.com.evancooper.FriendlyCompetitions.debug"
        #else
        return "group.com.evancooper.FriendlyCompetitions"
        #endif
    }
}
