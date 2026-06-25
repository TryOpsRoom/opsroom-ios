import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Re-fetches config when the app returns to the foreground (spec §2.2).
enum ForegroundConfigObserver {
    #if canImport(UIKit)
    private nonisolated(unsafe) static var observerToken: NSObjectProtocol?
    #endif

    static func startIfNeeded() {
        guard Configuration.shared.snapshot().checkOnForeground else {
            return
        }
        #if canImport(UIKit)
        guard observerToken == nil else {
            return
        }
        observerToken = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                await UpgradeCoordinator.shared.checkForUpdates()
            }
        }
        #endif
    }

    #if DEBUG
    static func stopForTesting() {
        #if canImport(UIKit)
        if let observerToken {
            NotificationCenter.default.removeObserver(observerToken)
        }
        observerToken = nil
        #endif
    }
    #endif
}
