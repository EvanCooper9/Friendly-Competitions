import Foundation
extension Competition {
    static var mock: Competition {
        .init(
            name: "Mock competition",
            owner: User.evan.id,
            participants: [User.evan.id, User.gabby.id],
            pendingParticipants: [User.gabby.id],
            scoringModel: .percentOfGoals,
            start: .now,
            end: .now.addingTimeInterval(2.days),
            repeats: false,
            isPublic: false,
            banner: nil
        )
    }

    static var mockInvited: Competition {
        .init(
            name: "Supa heat 🔥",
            owner: User.evan.id,
            participants: [User.evan.id, User.gabby.id],
            pendingParticipants: [User.evan.id],
            scoringModel: .percentOfGoals,
            start: .now,
            end: .now.addingTimeInterval(2.days),
            repeats: false,
            isPublic: false,
            banner: nil
        )
    }

    static var mockPublic: Competition {
        .init(
            name: "Weekly",
            owner: Bundle.main.id,
            participants: [User.evan.id, User.gabby.id],
            pendingParticipants: [],
            scoringModel: .percentOfGoals,
            start: .now,
            end: .now.addingTimeInterval(2.days),
            repeats: true,
            isPublic: true,
            banner: nil
        )
    }

    static var mockOld: Competition {
        .init(
            name: "Oldie bug a goodie",
            owner: User.evan.id,
            participants: [User.evan.id, User.gabby.id],
            pendingParticipants: [],
            scoringModel: .percentOfGoals,
            start: .now.addingTimeInterval(-5.days),
            end: .now.addingTimeInterval(-4.days),
            repeats: false,
            isPublic: false,
            banner: nil
        )
    }
}

extension Competition.Standing {
    static func mock(for user: User) -> Competition.Standing {
        .init(rank: 1, userId: user.id, points: Int.random(in: 100...1000))
    }
}
