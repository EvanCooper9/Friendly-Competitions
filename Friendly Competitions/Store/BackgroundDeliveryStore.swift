import Foundation
import HealthKit
import OrderedCollections

protocol BackgroundDeliveryStoring {
    var deliveries: OrderedDictionary<String, [Date]> { get set }
    var errors: OrderedDictionary<Date, String> { get set }
}

extension UserDefaults: BackgroundDeliveryStoring {
    var deliveries: OrderedDictionary<String, [Date]> {
        get { decode(OrderedDictionary<String, [Date]>.self, forKey: #function) ?? [:] }
        set { encode(newValue, forKey: #function) }
    }

    var errors: OrderedDictionary<Date, String> {
        get { decode(OrderedDictionary<Date, String>.self, forKey: #function) ?? [:] }
        set { encode(newValue, forKey: #function) }
    }
}
