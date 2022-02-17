import SwiftUI

struct ExploreCarouselSection<Content: View>: View {

    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title2)
                .padding(.leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    content
                }
                .padding(.horizontal)
            }
        }
    }
}
