import SwiftUI

struct FeaturedCompetitionView: View {

    let competition: Competition

    var body: some View {
        Color.clear
            .aspectRatio(3/2, contentMode: .fit)
            .overlay {
                Image(competition.bannerPath ?? "trophy")
                    .resizable()
                    .scaledToFill()
            }
            .clipped()
            .overlay {
                VStack(alignment: .leading, spacing: 5) {
                    Text(competition.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.title3)
                    HStack {
                        Image(systemName: "calendar")
                        Text("\(competition.start.formatted(date: .abbreviated, time: .omitted)) - \(competition.end.formatted(date: .abbreviated, time: .omitted))")
                    }
                    .font(.caption)
                }
                .foregroundColor(.black)
                .padding(8)
                .background(.ultraThinMaterial)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .cornerRadius(10)
    }
}

struct FeaturedCompetitionView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView(.vertical) {
            FeaturedCompetitionView(competition: .mock)
                .padding()
        }
    }
}
