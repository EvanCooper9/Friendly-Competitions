import Foundation

extension TimeInterval {
    var seconds: TimeInterval { self }
    var minutes: TimeInterval { seconds * 60 }
    var hours: TimeInterval { minutes * 60 }
    var days: TimeInterval { hours * 24 }
}
