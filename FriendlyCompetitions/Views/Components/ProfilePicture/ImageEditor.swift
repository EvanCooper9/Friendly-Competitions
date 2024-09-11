import BrightroomEngine
import BrightroomUI
import SwiftUI

enum ImageEditorResult {
    case new(Data)
    case cancelled
    case error(Error)
}

struct ImageEditor: View {

    @Binding var imageData: Data?
    let completion: (ImageEditorResult) -> Void

    @StateObject private var editingStack: EditingStack
    @Environment(\.dismiss) private var dismiss

    init(imageData: Binding<Data?>, completion: @escaping (ImageEditorResult) -> Void) {
        self._imageData = imageData
        self.completion = completion
        let imageProvider = try! ImageProvider(data: imageData.wrappedValue ?? .init())
        self._editingStack = .init(wrappedValue: EditingStack(imageProvider: imageProvider))
    }

    var body: some View {
        CroppingView(editingStack: editingStack) { result in
            completion(result)
            dismiss()
        }
        .background(Color.black.ignoresSafeArea())
    }
}

struct CroppingView: UIViewControllerRepresentable {
    typealias UIViewControllerType = PhotosCropViewController

    let editingStack: EditingStack
    let completion: (ImageEditorResult) -> Void

    func makeUIViewController(context: Context) -> PhotosCropViewController {
        editingStack.start()
        var options = PhotosCropViewController.Options()
        options.aspectRatioOptions = .fixed(.square)
        let viewController = PhotosCropViewController(editingStack: editingStack, options: options)
        viewController.handlers.didCancel = { _ in
            completion(.cancelled)
        }
        viewController.handlers.didFinish = { _ in
            do {
                let render = try editingStack.makeRenderer().render()
                if let imageData = render.uiImage.jpegData(compressionQuality: 0.25) {
                    completion(.new(imageData))
                } else {
                    completion(.cancelled)
                }
            } catch {
                completion(.error(error))
            }
        }
        return viewController
    }

    func updateUIViewController(_ uiViewController: PhotosCropViewController, context: Context) {}
}

