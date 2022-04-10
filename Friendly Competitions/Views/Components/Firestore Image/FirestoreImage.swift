import SwiftUI

struct FirestoreImage: View {

    @StateObject private var viewModel: FirestoreImageViewModel
    
    init(path: String) {
        _viewModel = .init(wrappedValue: .init(path: path))
    }

    var body: some View {
        if let imageData = viewModel.imageData {
            if let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
            } else {
                failedImage
            }
        } else if viewModel.failed {
            failedImage
                .onAppear(perform: viewModel.downloadImage)
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear(perform: viewModel.downloadImage)
        }
    }

    private var failedImage: some View {
        Image(systemName: "bolt.horizontal.circle")
            .font(.largeTitle)
    }
}

struct FirestoreImage_Previews: PreviewProvider {
    static var previews: some View {
        FirestoreImage(path: "")
            .setupMocks()
    }
}
