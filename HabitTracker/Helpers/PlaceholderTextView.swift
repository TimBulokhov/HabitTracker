import UIKit

class PlaceholderTextView: UITextView {
    var placeholder: String? {
        didSet { setNeedsDisplay() }
    }
    var placeholderColor: UIColor = .placeholderText {
        didSet { setNeedsDisplay() }
    }

    override var text: String! {
        didSet { setNeedsDisplay() }
    }
    override var attributedText: NSAttributedString! {
        didSet { setNeedsDisplay() }
    }
    override var font: UIFont? {
        didSet { setNeedsDisplay() }
    }
    override var textAlignment: NSTextAlignment {
        didSet { setNeedsDisplay() }
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard text.isEmpty, let placeholder = placeholder else { return }
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font ?? UIFont.systemFont(ofSize: 17),
            .foregroundColor: placeholderColor,
            .paragraphStyle: paragraphStyle
        ]
        let x = textContainerInset.left + textContainer.lineFragmentPadding
        let y = textContainerInset.top
        let width = rect.width - textContainerInset.left - textContainerInset.right - textContainer.lineFragmentPadding * 2
        let height = rect.height - textContainerInset.top - textContainerInset.bottom
        let placeholderRect = CGRect(x: x, y: y, width: width, height: height)
        (placeholder as NSString).draw(in: placeholderRect, withAttributes: attributes)
    }
} 