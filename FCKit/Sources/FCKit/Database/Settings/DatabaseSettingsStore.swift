import Foundation

public protocol DatabaseSettingsStoring {
    var lastCacheReset: Date { get set }
}

extension UserDefaults: DatabaseSettingsStoring {

    private enum Constants {
        static var lastCacheResetKey: String { #function }
    }

    public var lastCacheReset: Date {
        get { decode(Date.self, forKey: Constants.lastCacheResetKey) ?? .now }
        set { encode(newValue, forKey: Constants.lastCacheResetKey) }
    }
}
