import SwiftUI
import SwiftUIX

struct FirebaseImage<Content: View>: View {

    @StateObject private var viewModel: FirebaseImageViewModel
    private let alternateContent: (() -> Content)?

    init(path: String, alternateContent: (() -> Content)?) {
        self.alternateContent = alternateContent
        _viewModel = .init(wrappedValue: .init(path: path))
    }

    var body: some View {
        if let imageData = viewModel.imageData {
            if let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaledToFill()
            } else {
                alternateContent?() ?? failedImage
            }
        } else if let alternateContent {
            alternateContent()
        } else if viewModel.failed {
            failedImage
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var failedImage: some View {
        Image(systemName: .boltHorizontalCircle)
            .font(.largeTitle)
    }
}

extension FirebaseImage where Content == EmptyView {
    init(path: String) {
        self.init(path: path, alternateContent: nil)
    }
}

#if DEBUG
struct FirebaseImage_Previews: PreviewProvider {
    static var previews: some View {
        FirebaseImage(path: "")
            .setupMocks()
    }
}
#endif
