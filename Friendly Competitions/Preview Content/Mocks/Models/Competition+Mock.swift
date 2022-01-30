extension Competition {
    static var mock: Competition {
        .init(
            name: "Get bussy 🥵",
            participants: [User.evan.id, User.gabby.id],
            pendingParticipants: [User.gabby.id],
            scoringModel: .percentOfGoals,
            start: .now,
            end: .now.addingTimeInterval(2.days)
        )
    }

    static var mockInvited: Competition {
        .init(
            name: "Supa heat 🔥",
            participants: [User.evan.id, User.gabby.id],
            pendingParticipants: [User.evan.id],
            scoringModel: .percentOfGoals,
            start: .now,
            end: .now.addingTimeInterval(2.days)
        )
    }

    static var mockOld: Competition {
        .init(
            name: "Oldie bug a goodie",
            participants: [User.evan.id, User.gabby.id],
            pendingParticipants: [],
            scoringModel: .percentOfGoals,
            start: .now.addingTimeInterval(-5.days),
            end: .now.addingTimeInterval(-4.days)
        )
    }
}

extension Competition.Standing {
    static func mock(for user: User) -> Competition.Standing {
        .init(rank: 1, userId: user.id, points: Int.random(in: 100...1000))
    }
}
