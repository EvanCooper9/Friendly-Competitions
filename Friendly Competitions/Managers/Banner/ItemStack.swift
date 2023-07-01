import ECKit
import SwiftUI

struct ItemStack<Model, ModelContent: View>: View {

    let items: [Model]
    @ViewBuilder let modelContent: (Model) -> ModelContent

    var body: some View {
        stack(for: items)
    }

    @ViewBuilder
    private func stack(for models: [Model], index: Int = 0) -> AnyView? {
        if let model = models.first {
            modelContent(model)
                .padding(.bottom, CGFloat(models.count * 10))
                .background(alignment: .bottom) {
                    let remaining = Array(models.dropFirst())
                    if remaining.isNotEmpty {
                        let currentIndex = index + 1
                        stack(for: remaining, index: currentIndex)?
                            .padding(.horizontal, CGFloat(currentIndex * 4))
                    }
                }
                .eraseToAnyView()
        }
    }
}

#if DEBUG
struct ItemStack_Previews: PreviewProvider {

    private struct Preview: View {
        @State private var banners = Banner.allCases

        var body: some View {
            ItemStack(items: banners) { banner in
                banner.view {
                    banners.remove(banner)
                }
                .maxWidth(.infinity)
                .cornerRadius(10)
                .shadow(color: .gray.opacity(0.4), radius: 10, x: 0, y: 5)
            }
            .padding()
        }
    }
    static var previews: some View {
        Preview()
    }
}
#endif
