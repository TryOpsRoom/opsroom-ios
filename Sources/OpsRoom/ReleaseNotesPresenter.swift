import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Presents ``ReleaseNotesView`` in a dedicated overlay window (iOS only).
@MainActor
enum ReleaseNotesPresenter {
    #if canImport(UIKit)
    private static var overlayWindow: UIWindow?
    #endif

    /// Presents release notes when a window scene is available.
    ///
    /// - Returns: `true` when UI was shown; `false` when no scene (caller must not mark as shown).
    @discardableResult
    static func present(
        _ releaseNotes: ReleaseNotes,
        onDismiss: @escaping () -> Void
    ) async -> Bool {
        #if canImport(UIKit)
        guard let scene = await OverlayWindowScene.waitForForeground() else {
            OpsRoomLog.config.debug(
                "Release notes skipped: no foreground window scene."
            )
            return false
        }

        dismiss()

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let hosting = UIHostingController(
            rootView: ReleaseNotesView(
                releaseNotes: releaseNotes,
                onDismiss: {
                    dismiss()
                    onDismiss()
                }
            )
        )
        hosting.view.backgroundColor = .clear
        window.rootViewController = hosting
        window.makeKeyAndVisible()
        overlayWindow = window
        return true
        #else
        return false
        #endif
    }

    static func dismiss() {
        #if canImport(UIKit)
        overlayWindow?.isHidden = true
        overlayWindow?.rootViewController = nil
        overlayWindow = nil
        #endif
    }
}
