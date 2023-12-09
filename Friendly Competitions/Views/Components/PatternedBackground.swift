import SwiftUI
import SwiftUIX

struct PatternedBackground: View {

    private enum Item {
        case image(name: String)
    }

    private let count = 25
    private let size = 30.0

    private let items: [Item] = [
        .image(name: "person.3.fill"),
        .image(name: "trophy.fill")
    ]

    var body: some View {
        VStack {
            ForEach(0..<count, id: \.self) { i in
                HStack {
                    ForEach(0..<count, id: \.self) { j in
                        let index = (i + j) % items.count
                        let item = items[index]
                        view(for: item)
                            .frame(width: size, height: size)
                            .padding(.small)
                    }
                }
            }
        }
        .foregroundStyle(.quinary)
    }

    @ViewBuilder
    private func view(for item: Item) -> some View {
        switch item {
        case .image(let name):
            Image(systemName: name)
                .resizable()
                .sizeToFit()
        }
    }
}

#if DEBUG
struct PatternedBackground_Previews: PreviewProvider {
    static var previews: some View {
        PatternedBackground()
    }
}
#endif
