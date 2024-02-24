import ECKit
import SwiftUI

struct CompetitionContainerView: View {

    @StateObject private var viewModel: CompetitionContainerViewModel

    init(competition: Competition, result: CompetitionResult?) {
        _viewModel = .init(wrappedValue: .init(competition: competition, result: result))
    }

    var body: some View {
        ScrollView {
            if viewModel.dateRanges.count > 1 {
                CompetitionContainerDateRangeSelector(
                    ranges: viewModel.dateRanges,
                    select: viewModel.select(dateRange:)
                )

                Divider()
                    .padding(.vertical, .small)
            }

            switch viewModel.content {
            case .current:
                CompetitionView(competition: viewModel.competition)
            case .result(let result, let previous):
                CompetitionResultsView(competition: viewModel.competition, result: result, previousResult: previous)
                    .id(result.id)
            case .locked:
                VStack(alignment: .leading, spacing: 15) {
                    Text(L10n.Results.premiumRequred)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title)
                    PremiumBanner()
                        .cornerRadius(10)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle(viewModel.competition.name)
    }
}

#if DEBUG
struct CompetitionContainerView_Previews: PreviewProvider {

    private static let competition = Competition.mock

    private static func setupMocks() {

        // current standings

        let evan = User.evan
        let gabby = User.gabby
        let standings: [Competition.Standing] = [
            .init(rank: 1, userId: "Somebody", points: 100),
            .init(rank: 2, userId: "Rick", points: 75),
            .init(rank: 3, userId: "Bob", points: 60),
            .init(rank: 4, userId: gabby.id, points: 50),
            .init(rank: 5, userId: evan.id, points: 20),
            .init(rank: 6, userId: "Joe", points: 9)
        ]
        let participants = [evan, gabby]
        competitionsManager.competitions = .just([competition])
        competitionsManager.competitionPublisherForReturnValue = .just(competition)
        competitionsManager.standingsPublisherForLimitReturnValue = .just(standings)

        healthKitManager.shouldRequestReturnValue = .just(true)
        notificationsManager.permissionStatusReturnValue = .just(.notDetermined)

        searchManager.searchForUsersWithIDsReturnValue = .just(participants)

        // results

        let results: [CompetitionResult] = (0...6).map { i in
            let refDate = Date.now
                .advanced(by: -(Double(i) * 7.0).days)
                .advanced(by: -10.days) // offset
            return CompetitionResult(id: "\(i)", start: refDate.addingTimeInterval(-6.days), end: refDate, participants: [])
        }
        competitionsManager.resultsForReturnValue = .just(results)

        competitionsManager.standingsForResultIDClosure = { _, _ in
            let standings: [Competition.Standing] = [
                .init(rank: 1, userId: User.evan.id, points: 300),
                .init(rank: 2, userId: User.gabby.id, points: 200),
                .init(rank: 3, userId: User.andrew.id, points: 100),
                .init(rank: 4, userId: "4", points: 100),
                .init(rank: 5, userId: "5", points: 100),
                .init(rank: 6, userId: "6", points: 100)
            ]
            return .just(standings)
        }

        premiumManager.premium = .just(.init(id: "1", title: "", price: "", renews: true, expiry: .distantFuture))
    }

    static var previews: some View {
        CompetitionContainerView(competition: .mock, result: nil)
            .setupMocks(setupMocks)
            .embeddedInNavigationView()
    }
}
#endif
