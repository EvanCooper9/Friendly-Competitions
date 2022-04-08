import Resolver
import SwiftUI

struct FirestoreImage: View {

    let path: String

    @StateObject private var storageManager = Resolver.resolve(AnyStorageManager.self)

    @State private var failed = false
    @State private var imageData: Data?

    var body: some View {
        if let imageData = imageData {
            if let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
            } else {
                failedImage
            }
        } else if failed {
            failedImage
                .onAppear(perform: downloadImage)
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear(perform: downloadImage)
        }
    }

    private var failedImage: some View {
        Image(systemName: "bolt.horizontal.circle")
            .font(.largeTitle)
    }

    private func downloadImage() {
        failed = false
        Task {
            do {
                let data = try await storageManager.data(for: path)
                DispatchQueue.main.async {
                    self.imageData = data
                }
            } catch {
                DispatchQueue.main.async {
                    self.failed = true
                }
            }
        }
    }
}

struct FirestoreImage_Previews: PreviewProvider {
    static var previews: some View {
        FirestoreImage(path: "")
            .setupMocks()
    }
}
