import SwiftUI

// https://stackoverflow.com/a/62311089/4027606
struct FlatLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

extension ButtonStyle where Self == FlatLinkStyle {
    static var flatLink: Self { FlatLinkStyle() }
}
