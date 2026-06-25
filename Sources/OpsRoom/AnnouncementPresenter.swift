import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Presents announcement UI in a dedicated overlay window (iOS only).
@MainActor
enum AnnouncementPresenter {
    #if canImport(UIKit)
    private static var overlayWindow: UIWindow?
    #endif

    /// - Returns: `true` when UI was shown; `false` when no scene (caller must not mark as shown).
    @discardableResult
    static func present(
        _ announcement: Announcement,
        onDismiss: @escaping () -> Void,
        onCTA: (() -> Void)? = nil
    ) async -> Bool {
        #if canImport(UIKit)
        guard let scene = await OverlayWindowScene.waitForForeground() else {
            OpsRoomLog.config.debug(
                "Announcement skipped: no foreground window scene."
            )
            return false
        }

        dismiss()

        let ctaURL = announcement.ctaURL
        let wrappedDismiss = {
            dismiss()
            onDismiss()
        }
        let wrappedCTA: (() -> Void)? = {
            if let onCTA {
                return {
                    dismiss()
                    onCTA()
                    if let ctaURL {
                        Task { @MainActor in
                            AppStoreOpener.open(url: ctaURL)
                        }
                    }
                }
            }
            if let ctaURL {
                return {
                    dismiss()
                    wrappedDismiss()
                    Task { @MainActor in
                        AppStoreOpener.open(url: ctaURL)
                    }
                }
            }
            return nil
        }()

        let window = UIWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.backgroundColor = .clear

        switch announcement.style {
        case .modal:
            let hosting = UIHostingController(
                rootView: AnnouncementView(
                    announcement: announcement,
                    onDismiss: wrappedDismiss,
                    onCTA: wrappedCTA
                )
            )
            hosting.view.backgroundColor = .clear
            window.rootViewController = hosting

        case .banner:
            let overlay = AnnouncementBannerOverlayController(
                bannerContent: AnnouncementBannerView(
                    announcement: announcement,
                    onDismiss: wrappedDismiss,
                    onCTA: wrappedCTA
                )
            )
            window.rootViewController = overlay
        }

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
