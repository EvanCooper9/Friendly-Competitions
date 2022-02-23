import SwiftUI

struct AttributedText: UIViewRepresentable {

    let attributedString: NSAttributedString

    init(_ attributedString: NSAttributedString) {
        self.attributedString = attributedString
    }

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()

        label.lineBreakMode = .byClipping
        label.numberOfLines = 0

        return label
    }

    func updateUIView(_ uiView: UILabel, context: Context) {
        uiView.attributedText = attributedString
    }
}
