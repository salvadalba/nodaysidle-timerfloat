import os.log

/// Centralized logging infrastructure for TimerFloat
/// Uses os.Logger with subsystem 'com.timerfloat' and categories per service
enum Log {
    /// Subsystem identifier for all TimerFloat logs
    private static let subsystem = "com.timerfloat"

    /// Logger for timer-related operations
    static let timer = Logger(subsystem: subsystem, category: "timer")

    /// Logger for window management operations
    static let window = Logger(subsystem: subsystem, category: "window")

    /// Logger for hotkey registration and handling
    static let hotkey = Logger(subsystem: subsystem, category: "hotkey")

    /// Logger for notification scheduling
    static let notification = Logger(subsystem: subsystem, category: "notification")

    /// Logger for preferences and persistence
    static let preferences = Logger(subsystem: subsystem, category: "preferences")

    /// Logger for general app lifecycle events
    static let app = Logger(subsystem: subsystem, category: "app")
}
