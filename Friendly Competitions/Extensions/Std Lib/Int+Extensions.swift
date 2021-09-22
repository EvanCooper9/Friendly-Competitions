import Foundation

extension Int {
    var seconds: Int { self }
    var minutes: Int { seconds * 60 }
    var hours: Int { minutes * 60 }
    var days: Int { hours * 24 }
}

extension Int {
    var ordinalString: String? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .ordinal
        return numberFormatter.string(from: self as NSNumber)
    }
}
