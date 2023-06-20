import SwiftUI
import SwiftUIX

struct TextFieldWithSecureToggle: View {

    private enum FocusedField {
        case secure
        case unsecure

        var symbol: SFSymbolName {
            switch self {
            case .secure:
                return .eyeSlash
            case .unsecure:
                return .eye
            }
        }
    }

    private let title: String
    private let text: Binding<String>

    @FocusState var focused: Bool
    @State private var showPassword: Bool

    private let textContentType: UITextContentType?

    init(_ title: String, text: Binding<String>, showPassword: Bool = false, textContentType: UITextContentType? = nil) {
        self.title = title
        self.text = text
        self.showPassword = showPassword
        self.textContentType = textContentType
    }

    var body: some View {
        HStack {
            ZStack {
                TextField(title, text: text)
                    .textContentType(textContentType)
                    .focused($focused)
                    .opacity(showPassword ? 1 : 0)
                SecureField(title, text: text)
                    .textContentType(textContentType)
                    .focused($focused)
                    .opacity(showPassword ? 0 : 1)
            }

            Button(systemImage: showPassword ? .eyeSlash : .eye) {
                showPassword.toggle()
            }
            .foregroundColor(.secondaryLabel)
        }
    }
}
