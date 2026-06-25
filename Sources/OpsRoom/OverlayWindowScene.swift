#if canImport(UIKit)
import UIKit

/// Resolves an active `UIWindowScene` for SDK overlay windows.
@MainActor
enum OverlayWindowScene {
    static func foreground() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }

    /// Waits briefly for a scene during cold launch before presenting overlay UI.
    static func waitForForeground(maxWait: TimeInterval = 2.0) async -> UIWindowScene? {
        let deadline = Date().addingTimeInterval(maxWait)
        while Date() < deadline {
            if let scene = foreground() {
                return scene
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return foreground()
    }
}
#endif
