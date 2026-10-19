import UIKit

/// Two Auto Layout failures for the inspector:
/// an under-constrained box, and a box with two required widths.
/// The constraint objects are stored so a broken one stays alive for the recorder.
final class BrokenConstraintsViewController: UIViewController {
    private let ambiguousBox = UIView()
    private let conflictBox = UIView()
    private var heldConstraints: [NSLayoutConstraint] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Broken constraints"

        let intro = UILabel()
        intro.translatesAutoresizingMaskIntoConstraints = false
        intro.numberOfLines = 0
        intro.text = "Orange has width and height only, so its position is ambiguous. Red has two required widths, 80 and 160."
        intro.accessibilityIdentifier = "demo.broken.intro"

        ambiguousBox.translatesAutoresizingMaskIntoConstraints = false
        ambiguousBox.backgroundColor = .systemOrange
        ambiguousBox.accessibilityIdentifier = "demo.broken.ambiguous"

        conflictBox.translatesAutoresizingMaskIntoConstraints = false
        conflictBox.backgroundColor = .systemRed
        conflictBox.accessibilityIdentifier = "demo.broken.conflict"

        let ambiguousCaption = caption("Ambiguous: no x or y")
        ambiguousCaption.accessibilityIdentifier = "demo.broken.ambiguousCaption"
        let conflictCaption = caption("Conflict: width 80 and 160 @ 1000")
        conflictCaption.accessibilityIdentifier = "demo.broken.conflictCaption"

        view.addSubview(intro)
        view.addSubview(ambiguousBox)
        view.addSubview(ambiguousCaption)
        view.addSubview(conflictBox)
        view.addSubview(conflictCaption)

        let ambiguousWidth = ambiguousBox.widthAnchor.constraint(equalToConstant: 120)
        ambiguousWidth.identifier = "demo.ambiguous.width"
        let ambiguousHeight = ambiguousBox.heightAnchor.constraint(equalToConstant: 80)
        ambiguousHeight.identifier = "demo.ambiguous.height"

        let conflictLeading = conflictBox.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor)
        conflictLeading.identifier = "demo.conflict.leading"
        let conflictTop = conflictBox.topAnchor.constraint(equalTo: conflictCaption.bottomAnchor, constant: 8)
        conflictTop.identifier = "demo.conflict.top"
        let conflictHeight = conflictBox.heightAnchor.constraint(equalToConstant: 80)
        conflictHeight.identifier = "demo.conflict.height"
        let narrow = conflictBox.widthAnchor.constraint(equalToConstant: 80)
        narrow.identifier = "demo.conflict.width.80"
        let wide = conflictBox.widthAnchor.constraint(equalToConstant: 160)
        wide.identifier = "demo.conflict.width.160"

        heldConstraints = [ambiguousWidth, ambiguousHeight, narrow, wide]

        NSLayoutConstraint.activate([
            intro.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            intro.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            intro.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            ambiguousCaption.topAnchor.constraint(equalTo: intro.bottomAnchor, constant: 24),
            ambiguousCaption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            ambiguousCaption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            ambiguousWidth,
            ambiguousHeight,

            conflictCaption.topAnchor.constraint(equalTo: ambiguousCaption.bottomAnchor, constant: 120),
            conflictCaption.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            conflictCaption.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            conflictLeading,
            conflictTop,
            conflictHeight,
            narrow,
            wide,
        ])
    }

    private func caption(_ text: String) -> UILabel {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }
}
