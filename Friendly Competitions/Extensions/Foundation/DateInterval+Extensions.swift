import Foundation

extension DateInterval {

//    convenience init(start: Date, end: Date) {
//        .init(
//            start: start,
//            duration: end.timeIntervalSince(start)
//        )
//    }

    var end: Date {
        start.addingTimeInterval(duration)
    }
}
