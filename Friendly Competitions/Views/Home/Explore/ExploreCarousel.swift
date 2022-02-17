import SwiftUI

struct ExploreCarousel<Content: View>: View {

    let title: String
    @ViewBuilder var content: Content

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(title)
                    .font(.title2)
                Spacer()

                NavigationLink("See all") {
                    ScrollView(.vertical) {
                        content
                            .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .navigationTitle(title)
                    .background(colorScheme == .light ?
                        Color(uiColor: UIColor.secondarySystemBackground).ignoresSafeArea() :
                        nil
                    )
                }
            }
            .padding(.horizontal)
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack {
                    content
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ExploreCarousel_Previews: PreviewProvider {
    static var previews: some View {
        ExploreCarousel(title: "From us") {
            FeaturedCompetition(competition: .mockPublic)
            FeaturedCompetition(competition: .mockPublic)
        }
        .aspectRatio(3/2, contentMode: .fit)
        .navigationTitle("Test")
        .embeddedInNavigationView()
//        .frame(height: 300)
    }
}
