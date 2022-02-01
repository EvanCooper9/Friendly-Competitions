import SwiftUI

struct WithLoadingOverlay: ViewModifier {

    @Binding var loading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
            if loading {
                ProgressView()
                    .padding()
                    .tint(.white)
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(5)
            }
        }
    }
}

extension View {
    func withLoadingOverlay(loading: Binding<Bool>) -> some View {
        modifier(WithLoadingOverlay(loading: loading))
    }
}

struct WithLoadingOverlay_Previews: PreviewProvider {
    static var previews: some View {
        Text("Test")
            .modifier(WithLoadingOverlay(loading: .constant(true)))
    }
}
