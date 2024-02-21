import ECKit
import Factory
import Foundation

public protocol WidgetStore {
    var uploaded: Date? { get set }
    var downloaded: [String: Date] { get set }
    var competitions: [String: WidgetCompetition] { get set }
}

extension UserDefaults: WidgetStore {
    public var uploaded: Date? {
        get { decode(Date.self, forKey: WidgetStoreKeys.uploaded.value) }
        set { encode(newValue, forKey: WidgetStoreKeys.uploaded.value) }
    }

    public var downloaded: [String : Date] {
        get { decode([String: Date].self, forKey: WidgetStoreKeys.downloaded.value) ?? [:] }
        set { encode(newValue, forKey: WidgetStoreKeys.downloaded.value) }
    }

    public var competitions: [String: WidgetCompetition] {
        get { decode([String: WidgetCompetition].self, forKey: WidgetStoreKeys.competitions.value) ?? [:] }
        set { encode(newValue, forKey: WidgetStoreKeys.competitions.value) }
    }
}

enum WidgetStoreKeys: String {
    case uploaded
    case downloaded
    case competitions

    private var namespace: String {
        "WidgetStoreKeys"
    }

    var value: String {
        [namespace, rawValue].joined(separator: ".")
    }
}

public extension Container {
    var widgetStore: Factory<WidgetStore> {
        self { UserDefaults.appGroup }.scope(.shared)
    }
}
