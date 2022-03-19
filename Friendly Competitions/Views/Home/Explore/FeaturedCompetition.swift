import SwiftUI

struct FeaturedCompetition: View {

    @Binding var competition: Competition

    @Environment(\.colorScheme) private var colorScheme

    private var start: String { competition.start.formatted(date: .abbreviated, time: .omitted) }
    private var end: String { competition.end.formatted(date: .abbreviated, time: .omitted) }

    var body: some View {
        color
            .aspectRatio(3/2, contentMode: .fit)
            .overlay {
                if let banner = competition.banner {
                    FirestoreImage(path: banner)
                } else {
                    Asset.Colors.listSectionBackground.swiftUIColor
                }
            }
            .clipped()
            .overlay {
                CompetitionDetails(competition: $competition)
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .background(.ultraThinMaterial)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .cornerRadius(10)
    }

    private var color: some View {
        colorScheme == .light ? Color(uiColor: .systemGray4) : Color(uiColor: .secondarySystemBackground)
    }
}

struct FeaturedCompetitionView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            FeaturedCompetition(competition: .constant(.mockPublic))
                .padding()
            FeaturedCompetition(competition: .constant(.mockPublic))
                .padding()
        }
//        .preferredColorScheme(.dark)
        .background(Asset.Colors.listBackground.swiftUIColor)
        .withEnvironmentObjects()
    }
}
