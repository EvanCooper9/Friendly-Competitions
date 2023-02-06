import SwiftUI
import SwiftUIX

struct FirebaseImage: View {

    @StateObject private var viewModel: FirebaseImageViewModel
    
    var contentMode = ContentMode.fit
    
    init(path: String) {
        _viewModel = .init(wrappedValue: .init(path: path))
    }

    var body: some View {
        image.onAppear(perform: viewModel.downloadImage)
    }
    
    @ViewBuilder
    private var image: some View {
        if let imageData = viewModel.imageData {
            if let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .scaledToFill()
            } else {
                failedImage
            }
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

#if DEBUG
struct FirebaseImage_Previews: PreviewProvider {
    static var previews: some View {
        FirebaseImage(path: "")
            .setupMocks()
    }
}
#endif
