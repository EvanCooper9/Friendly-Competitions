import FirebaseFirestore

extension Timestamp: Comparable {
    public static func < (lhs: Timestamp, rhs: Timestamp) -> Bool {
        lhs.seconds < rhs.seconds
    }
}
