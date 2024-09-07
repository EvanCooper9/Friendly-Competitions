import SwiftUI

struct HideNameLearnMoreView: View {

    @Binding var showName: Bool

    var body: some View {
        VStack(alignment: .leading) {

            Toggle(L10n.Profile.Privacy.HideName.title, isOn: $showName)
                .font(.title)

            Text(L10n.Profile.Privacy.HideName.description)
                .foregroundColor(.secondaryLabel)
                .padding(.vertical, .small)

            Color.systemFill
                .aspectRatio(3/2, contentMode: .fit)
                .overlay(alignment: .top) {
                    if showName {
                        Asset.Images.Privacy.nameShown.swiftUIImage
                            .resizable()
                            .scaledToFill()
                    } else {
                        Asset.Images.Privacy.nameHidden.swiftUIImage
                            .resizable()
                            .scaledToFill()
                    }
                }
                .cornerRadius(15)
        }
        .padding()
        .fittedDetents(defaultDetents: [.large])
        .registerScreenView(name: "Hide Name Learn More")
    }
}

#if DEBUG
struct HideNameLearnMoreView_Previews: PreviewProvider {

    private struct Preview: View {
        @State private var showName = false
        @State private var presented = true
        var body: some View {
            Button("Present", toggle: $presented)
                .sheet(isPresented: $presented) {
                    HideNameLearnMoreView(showName: $showName)
                }
        }
    }

    static var previews: some View {
        Preview()
            .setupMocks()
    }
}
#endif
