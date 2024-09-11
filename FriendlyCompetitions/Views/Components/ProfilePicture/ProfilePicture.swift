import Combine
import PhotosUI
import SwiftUI
import SwiftUIX

struct ProfilePicture: View {

    @Binding var imageData: Data?

    @State private var showImageSelection = false
    @State private var imageSelection: PhotosPickerItem?
    @State private var tempImageData: Data?
    @State private var editImage = false
    @State private var editError: Error?
    @State private var showImageSelectionConfirmation = false

    var body: some View {
        image
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                Button(toggle: imageData == nil ? $showImageSelection : $showImageSelectionConfirmation) {
                    Image(systemName: "pencil.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 30))
                        .foregroundColor(.accentColor)
                        .buttonStyle(.borderless)
                }
            }
            .sheet(isPresented: $editImage) {
                ImageEditor(imageData: $tempImageData) { result in
                    switch result {
                    case .new(let data):
                        imageData = data
                    case .cancelled:
                        break
                    case .error(let error):
                        editError = error
                    }
                    imageSelection = nil
                }
            }
            .errorAlert(error: $editError)
            .photosPicker(isPresented: $showImageSelection, selection: $imageSelection, matching: .images, photoLibrary: .shared())
            .confirmationDialog("What would you like to do?", isPresented: $showImageSelectionConfirmation, titleVisibility: .visible) {
                Button("Choose", toggle: $showImageSelection)
                Button("Edit") {
                    tempImageData = imageData
                    editImage = true
                }
                Button("Delete", role: .destructive) {
                    imageData = nil
                }
            } message: {
                Text("You can choose a new image, edit your existing one, or delete your profile picture entirely.")
            }
            .onChange(of: imageSelection) { imageSelection in
                guard let imageSelection else { return }
                loadTransferable(from: imageSelection)
            }
    }

    @ViewBuilder
    private var image: some View {
        if let imageData, let image = Image(data: imageData) {
            image
                .resizable()
                .scaledToFill()
        } else {
            Image(systemName: .personCropCircle)
                .resizable()
                .scaledToFit()
                .foregroundStyle(.secondary)
        }
    }

    @discardableResult
    private func loadTransferable(from imageSelection: PhotosPickerItem) -> Progress {
        imageSelection.loadTransferable(type: ProfileImage.self) { result in
            DispatchQueue.main.async {
                guard imageSelection == self.imageSelection else {
                    print("Failed to get the selected item.")
                    return
                }
                switch result {
                case .success(let profileImage):
                    guard let data = profileImage?.data else {
                        return
                    }
                    self.tempImageData = data
                    self.editImage = true
                case .failure:
                    self.tempImageData = nil
                }
            }
        }
    }
}


private struct ProfileImage: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            ProfileImage(data: data)
        }
    }
}

#Preview {
    @State var imageData: Data?
    return ProfilePicture(imageData: $imageData)
}
