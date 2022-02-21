import SwiftUI

struct FeaturedCompetition: View {

    let competition: Competition

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
                    Color(uiColor: .white)
                }
            }
            .clipped()
            .overlay {
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        if competition.owner == Bundle.main.id {
                            AppIcon(size: UIFont.preferredFont(forTextStyle: .title2).pointSize)
                        }
                        Text(competition.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .font(.title3)
                    }
                    Label("\(start) - \(end)", systemImage: "calendar")
                        .font(.caption)
                }
                .foregroundColor(.black)
                .padding(8)
                .background(.ultraThinMaterial)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .cornerRadius(10)
    }

    @ViewBuilder
    private var color: some View {
        colorScheme == .light ? .white : Color(uiColor: .secondarySystemBackground)
    }
}

struct FeaturedCompetitionView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            FeaturedCompetition(competition: .mockPublic)
                .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
    }
}
