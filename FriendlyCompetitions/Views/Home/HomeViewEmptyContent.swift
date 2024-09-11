import SwiftUI

struct HomeViewEmptyContent: View {

    let symbol: String
    let message: String
    let buttons: [HomeViewEmptyContentButtonConfiguration]

    struct HomeViewEmptyContentButtonConfiguration: Identifiable {
        var id: String { title }
        let title: String
        let action: () -> Void
    }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Image(systemName: symbol)
                .symbolRenderingMode(.hierarchical)
                .resizable()
                .scaledToFit()
                .height(75)
                .foregroundStyle(.secondary)

            Text(message)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                ForEach(enumerating: buttons) { index, button in
                    let button = Button(button.title, action: button.action)
                    switch index {
                    case 0:
                        button.buttonStyle(.borderedProminent)
                    case 1:
                        button.buttonStyle(.bordered)
                    default:
                        button
                    }
                }
            }
        }
        .padding(.vertical)
    }
}
