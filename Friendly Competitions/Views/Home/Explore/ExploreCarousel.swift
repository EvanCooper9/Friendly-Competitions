import SwiftUI

struct ExploreCarousel<Content: View>: View {

    let padding: CGFloat
    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                content
            }
            .padding(.horizontal, padding)
        }
    }
}

struct ExploreCarousel_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ExploreCarousel(padding: 20) {
                FeaturedCompetition(competition: .constant(.mockPublic))
                    .frame(width: UIScreen.width - 40)
                FeaturedCompetition(competition: .constant(.mockPublic))
                    .frame(width: UIScreen.width - 40)
            }
            .aspectRatio(3/2, contentMode: .fit)
        }
        .background(Asset.Colors.listBackground.swiftUIColor)
//        .preferredColorScheme(.dark)
    }
}
