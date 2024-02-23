import Foundation

public extension UserDefaults {
    static var appGroup: UserDefaults {
        UserDefaults(suiteName: AppGroup.id()) ?? .standard
    }
}
