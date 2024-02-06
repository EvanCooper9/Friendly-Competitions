import Foundation

struct Premium: Codable {
    let id: String
    let title: String
    let price: String
    let renews: Bool
    let expiry: Date?
}
