import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Presents ``FeedbackSheetView`` in a dedicated overlay window (iOS only).
@MainActor
enum FeedbackPresenter {
    #if canImport(UIKit)
    private static var overlayWindow: UIWindow?
    #endif

    @discardableResult
    static func present(
        feedback: FeedbackPayload,
        onSubmit: @escaping (String) -> Void,
        onDismiss: @escaping () -> Void
    ) async -> Bool {
        #if canImport(UIKit)
        guard let scene = await OverlayWindowScene.waitForForeground() else {
            OpsRoomLog.config.debug(
                "Feedback skipped: no foreground window scene."
            )
            return false
        }

        dismiss()

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        let hosting = UIHostingController(
            rootView: FeedbackSheetView(
                feedback: feedback,
                onSubmit: { value in
                    dismiss()
                    onSubmit(value)
                },
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
