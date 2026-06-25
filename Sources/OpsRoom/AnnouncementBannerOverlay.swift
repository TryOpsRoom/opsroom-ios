#if canImport(UIKit)
import SwiftUI
import UIKit

/// Full-screen invisible root; only the top banner subview receives touches.
@MainActor
final class AnnouncementBannerOverlayController<Content: View>: UIViewController {
    private let bannerContent: Content

    init(bannerContent: Content) {
        self.bannerContent = bannerContent
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }

    override func loadView() {
        let root = PassThroughRootView()
        root.backgroundColor = .clear
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let hosting = UIHostingController(rootView: bannerContent)
        hosting.view.backgroundColor = .clear
        hosting.sizingOptions = .intrinsicContentSize

        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}

/// Does not intercept touches; interactive subviews (the banner) still receive them.
final class PassThroughRootView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === self ? nil : hit
    }
}
#endif
