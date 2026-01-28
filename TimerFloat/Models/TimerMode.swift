import Foundation

/// Represents the operating mode of the timer
enum TimerMode: String, Sendable, Equatable, CaseIterable {
    /// Countdown from a set duration to zero
    case countdown
    /// Count up from zero (stopwatch)
    case stopwatch

    /// Display name for UI
    var displayName: String {
        switch self {
        case .countdown: return "Timer"
        case .stopwatch: return "Stopwatch"
        }
    }

    /// SF Symbol icon name
    var iconName: String {
        switch self {
        case .countdown: return "timer"
        case .stopwatch: return "stopwatch"
        }
    }
}
