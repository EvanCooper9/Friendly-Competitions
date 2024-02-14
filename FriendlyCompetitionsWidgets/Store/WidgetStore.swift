import ECKit
import Factory
import Foundation

public protocol WidgetStore {
    var competitions: [WidgetCompetition] { get set }
}

extension UserDefaults: WidgetStore {
    public var competitions: [WidgetCompetition] {
        get { decode([WidgetCompetition].self, forKey: "competitions", decoder: .init()) ?? [] }
        set { encode(newValue, forKey: "competitions", encoder: .init()) }
    }
}

public extension Container {
    var widgetStore: Factory<WidgetStore> {
        self { UserDefaults.appGroup }.scope(.shared)
    }
}
