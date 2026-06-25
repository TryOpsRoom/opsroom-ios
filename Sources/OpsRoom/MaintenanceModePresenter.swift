import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Presents ``MaintenanceModeView`` in a dedicated overlay window (iOS only).
@MainActor
enum MaintenanceModePresenter {
    #if canImport(UIKit)
    private static var overlayWindow: UIWindow?
    #endif

    static func present(_ maintenance: MaintenancePayload) {
        #if canImport(UIKit)
        guard let scene = foregroundWindowScene() else {
            return
        }

        dismiss()

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 2
        window.backgroundColor = .systemBackground

        let supportURL = maintenance.supportURL
        let hosting = UIHostingController(
            rootView: MaintenanceModeView(
                maintenance: maintenance,
                onSupport: supportURL != nil
                    ? { AppStoreOpener.open(url: supportURL!) }
                    : nil
            )
        )
        hosting.view.backgroundColor = .clear
        window.rootViewController = hosting
        window.makeKeyAndVisible()
        overlayWindow = window
        #endif
    }

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
