import ECKit
import SwiftUI
import SwiftUIX

struct CompetitionResultsView: View {

    @StateObject private var viewModel: CompetitionResultsViewModel

    init(competition: Competition) {
        _viewModel = .init(wrappedValue: .init(competition: competition))
    }

    var body: some View {
        ScrollView {
            CompetitionResultsDateRangeSelector(
                ranges: viewModel.ranges,
                select: viewModel.select
            )

            Divider()
                .padding(.vertical, .small)

            if viewModel.loading {
                ProgressView()
            } else if viewModel.locked {
                lockedView
            } else {
                LazyVGrid(columns: [.flexible(), .flexible()], spacing: 25) {
                    ForEach(viewModel.dataPoints) { $0.view }
                }
                .padding(.horizontal, 20)
                .padding(.bottom)
            }
        }
        .background(Color.listBackground)
        .navigationTitle(L10n.Results.title)
        .sheet(isPresented: $viewModel.showPaywall, content: PaywallView.init)
        .registerScreenView(name: "Results")
    }

    private var lockedView: some View {
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

#if DEBUG
struct CompetitionResultsView_Previews: PreviewProvider {

    private static func setupMocks() {
        let results: [CompetitionResult] = [
            .init(id: "1", start: .now.advanced(by: -7.days), end: .now, participants: []),
            .init(id: "2", start: .now.advanced(by: -14.days), end: .now.advanced(by: -8.days), participants: []),
            .init(id: "3", start: .now.advanced(by: -21.days), end: .now.advanced(by: -15.days), participants: []),
            .init(id: "4", start: .now.advanced(by: -28.days), end: .now.advanced(by: -22.days), participants: []),
            .init(id: "5", start: .now.advanced(by: -35.days), end: .now.advanced(by: -29.days), participants: []),
            .init(id: "6", start: .now.advanced(by: -42.days), end: .now.advanced(by: -43.days), participants: [])
        ]
        competitionsManager.resultsForReturnValue = .just(results)

        let stats: [Competition.Standing] = [
            .init(rank: 1, userId: User.evan.id, points: 300),
            .init(rank: 2, userId: User.gabby.id, points: 200),
            .init(rank: 3, userId: User.andrew.id, points: 100),
            .init(rank: 4, userId: "4", points: 100),
            .init(rank: 5, userId: "5", points: 100),
            .init(rank: 6, userId: "6", points: 100)
        ]
        competitionsManager.standingsForResultIDReturnValue = .just(stats)
    }

    static var previews: some View {
        CompetitionResultsView(competition: .mock)
            .embeddedInNavigationView()
            .setupMocks(setupMocks)
    }
}
#endif
