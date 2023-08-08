import ECKit
import SwiftUI
import SwiftUIX

struct CompetitionResultsView: View {

    @StateObject private var viewModel: CompetitionResultsViewModel

    init(competition: Competition, result: CompetitionResult, previousResult: CompetitionResult?) {
        _viewModel = .init(wrappedValue: .init(competition: competition, result: result, previousResult: previousResult))
    }

    var body: some View {
        ScrollView {
            if viewModel.loading {
                ProgressView()
            } else {
                LazyVGrid(columns: [.flexible(), .flexible()], spacing: 25) {
                    ForEach(viewModel.dataPoints) { $0.view }
                }
                .padding(.horizontal, 20)
                .padding(.bottom)
            }
        }
        .registerScreenView(name: "Results")
    }
}

#if DEBUG
struct CompetitionResultsView_Previews: PreviewProvider {

    private static func setupMocks() {
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
        CompetitionResultsView(competition: .mock, result: .init(id: "1", start: .now.advanced(by: -7.days), end: .now, participants: []), previousResult: nil)
            .embeddedInNavigationView()
            .setupMocks(setupMocks)
    }
}
#endif
