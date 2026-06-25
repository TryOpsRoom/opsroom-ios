import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Opens the App Store (or any HTTPS URL) from upgrade prompt primary actions.
@MainActor
enum AppStoreOpener {
    /// Opens `url` in the system browser / App Store app.
    static func open(url: URL) {
        #if canImport(UIKit)
        UIApplication.shared.open(url, options: [:]) { accepted in
            if !accepted {
                OpsRoomLog.config.warning(
                    "Could not open URL \(url.absoluteString, privacy: .public)"
                )
            }
        }
        #elseif canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }
}
