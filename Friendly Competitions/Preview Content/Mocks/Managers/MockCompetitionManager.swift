//final class MockCompetitionManager: CompetitionsManaging {
//
//    var searchResults = [Competition]()
//    override func search(_ searchText: String) async throws -> [Competition] {
//        searchResults
//    }
//
//    override init() {
//        super.init()
//        setupAppStorePreviewContent()
//    }
//
//    private func setupAppStorePreviewContent() {
//        competitions = [
//            .mock,
//            .mock(with: "Runner's high 🏃🏻‍♂️", participantCount: 10)
//        ]
//        participants = competitions.reduce(into: [:]) { participants, competition in
//            participants[competition.id] = [.evan, .andrew, .gabby]
//        }
//        standings = competitions.reduce(into: [:]) { standings, competition in
//            standings[competition.id] = [
//                .init(rank: 1, userId: User.evan.id, points: 903),
//                .init(rank: 2, userId: User.andrew.id, points: 612),
//                .init(rank: 3, userId: User.gabby.id, points: 413)
//            ]
//        }
//        appOwnedCompetitions = [
//            .mockPublic,
//            .mockPublic
//        ]
//        topCommunityCompetitions = [
//            .mock(with: "Feel the burn 🔥", participantCount: 5),
//            .mock(with: "Runner's high 🏃🏻‍♂️", participantCount: 10),
//            .mock(with: "Leg day", participantCount: 15),
//            .mock(with: "Training day", participantCount: 20)
//        ]
//    }
//}
