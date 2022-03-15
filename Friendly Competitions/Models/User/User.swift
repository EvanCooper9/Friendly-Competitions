import Foundation

fileprivate let animals = ["alligator", "anteater", "armadillo", "auroch", "axolotl", "badger", "bat", "beaver", "buffalo", "camel", "capybara", "chameleon", "cheetah", "chinchilla", "chipmunk", "chupacabra", "cormorant", "coyote", "crow", "dingo", "dinosaur", "dog", "dolphin", "dragon", "duck", "octopus", "elephant", "ferret", "fox", "frog", "giraffe", "gopher", "grizzly", "hedgehog", "hippo", "hyena", "jackal", "ibex", "ifrit", "iguana", "koala", "kraken", "lemur", "leopard", "liger", "lion", "llama", "manatee", "mink", "monkey", "narwhal", "orangutan", "otter", "panda", "penguin", "platypus", "pumpkin", "python", "quagga", "rabbit", "raccoon", "rhino", "sheep", "shrew", "skunk", "squirrel", "tiger", "turtle", "unicorn", "walrus", "wolf", "wolverine", "wombat"]

final class User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    var friends = [String]()
    var incomingFriendRequests = [String]()
    var outgoingFriendRequests = [String]()
    var notificationTokens: [String]? = []
    var statistics: Statistics? = .zero

    var searchable: Bool? = true
    var showRealName: Bool? = true

    var hashId: String {
        let endIndex = id.index(id.startIndex, offsetBy: 4)
        return "#" + id[..<endIndex].uppercased()
    }

    init(id: String, email: String, name: String) {
        self.id = id
        self.email = email
        self.name = name
    }

    func displayName(seenBy otherUser: User) -> String {
        let showRealName = otherUser.id == id || otherUser.friends.contains(id) || showRealName == true
        return showRealName ? name : "Anonymous \(animals.randomElement()!.localizedCapitalized)"
    }
}

extension User: Equatable {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
}

extension User: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension User: ObservableObject {}
