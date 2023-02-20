import SwiftUI

extension View {
    func fittedDetents(defaultDetents: Set<PresentationDetent> = [.medium, .large]) -> some View {
        FittedDetentsContainer(content: self, defaultDetents: defaultDetents)
    }
}

private struct FittedDetentsContainer<Content: View>: View {
    
    let content: Content
    let defaultDetents: Set<PresentationDetent>
    
    @State private var contentSize: CGSize?
    
    private var presentationDetents: Set<PresentationDetent> {
        guard let contentSize else { return defaultDetents }
        return [.height(contentSize.height)]
    }
    
    var body: some View {
        content
            .background {
                GeometryReader { proxy in
                    Color.clear.onAppear { contentSize = proxy.size }
                }
            }
            .presentationDetents(presentationDetents)
    }
}
