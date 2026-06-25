import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Presents ``UpgradePromptView`` in a dedicated overlay `UIWindow` above the app (iOS only).
@MainActor
enum UpgradePromptPresenter {
    #if canImport(UIKit)
    private static var overlayWindow: UIWindow?
    #endif

    /// Shows the upgrade modal for `presentation`.
    ///
    /// Force updates keep the modal visible after opening the store; soft updates dismiss on primary or secondary.
    static func present(
        _ presentation: UpgradePromptPresentation,
        onPrimary: @escaping () -> Void,
        onSecondary: (() -> Void)? = nil,
        onUnavailable: @escaping () -> Void = {}
    ) {
        #if canImport(UIKit)
        guard let scene = foregroundWindowScene() else {
            onUnavailable()
            return
        }

        dismiss()

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let hosting = UIHostingController(
            rootView: UpgradePromptView(
                presentation: presentation,
                onPrimary: {
                    AppStoreOpener.open(url: presentation.appStoreURL)
                    onPrimary()
                    if presentation.style == .soft {
                        dismiss()
                    }
                },
                onSecondary: presentation.style == .soft
                    ? {
                        onSecondary?()
                        dismiss()
                    }
                    : nil
            )
        )
        hosting.view.backgroundColor = .clear
        window.rootViewController = hosting
        window.makeKeyAndVisible()
        overlayWindow = window
        #else
        onUnavailable()
        #endif
    }

    /// Removes the overlay window if present.
    static func dismiss() {
        #if canImport(UIKit)
        overlayWindow?.isHidden = true
        overlayWindow?.rootViewController = nil
        overlayWindow = nil
        #endif
    }

    #if canImport(UIKit)
    private static func foregroundWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }
    #endif
}
