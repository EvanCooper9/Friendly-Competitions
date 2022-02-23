import SwiftUI

struct ExploreCarousel<Content: View>: View {

    @ViewBuilder let content: Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                content
            }
            .padding(.horizontal)
        }
    }
}

struct ExploreCarousel_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            ExploreCarousel {
                FeaturedCompetition(competition: .mockPublic)
                    .frame(width: UIScreen.width - 40)
                FeaturedCompetition(competition: .mockPublic)
                    .frame(width: UIScreen.width - 40)
            }
            .aspectRatio(3/2, contentMode: .fit)
        }
        .background(Asset.Colors.listBackground.swiftUIColor)
//        .preferredColorScheme(.dark)
    }
}
