import os

/// Unified logging for the OpsRoom package (`Logger`, subsystem `com.opsroom.sdk`).
enum OpsRoomLog {
    private static let subsystem = "com.opsroom.sdk"

    /// Config fetch, decode, maintenance, and fail-open messages.
    static let config = Logger(subsystem: subsystem, category: "config")
}
