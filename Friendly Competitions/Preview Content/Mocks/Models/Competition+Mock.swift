#if DEBUG

import Foundation

extension Competition {
    static var mock: Competition {
        .init(
            name: "Competition 🏃🏻",
            owner: User.evan.id,
            participants: [User.evan.id, User.gabby.id, User.andrew.id],
            pendingParticipants: [],
            scoringModel: .percentOfGoals,
            start: .now,
            end: .now.addingTimeInterval(2.days),
            repeats: true,
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
            banner: "competitions/banners/trophy.jpg"
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
    
    static var mockFuture: Competition {
        .init(
            name: "Back to the future",
            owner: User.evan.id,
            participants: [User.evan.id, User.gabby.id],
            pendingParticipants: [],
            scoringModel: .percentOfGoals,
            start: .now.addingTimeInterval(2.days),
            end: .now.addingTimeInterval(4.days),
            repeats: false,
            isPublic: false,
            banner: nil
        )
    }

    static func mock(with name: String, participantCount: Int) -> Competition {
        .init(
            name: name,
            owner: User.evan.id,
            participants: (0..<participantCount).map { "\($0)" },
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
#endif
