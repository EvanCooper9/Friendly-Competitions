import SwiftUI

struct ExploreSection<Content: View>: View {

    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.title3)
                .padding(.horizontal)
                .foregroundColor(.gray)
                .padding(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            content
        }
    }
}
