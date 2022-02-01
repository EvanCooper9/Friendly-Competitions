struct Participant: Identifiable {
    let id: String
    let name: String

    init(from user: User) {
        id = user.id
        name = user.name
    }
}
