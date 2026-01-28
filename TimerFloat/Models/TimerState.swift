import Foundation

/// Represents the current state of the timer
/// Sendable and Equatable for Swift 6 concurrency safety and state comparison
enum TimerState: Sendable, Equatable {
    /// Timer is not running and has no active countdown
    case idle

    /// Timer is actively counting down
    /// - Parameters:
    ///   - remaining: Time remaining in seconds
    ///   - total: Total duration of the timer in seconds
    case running(remaining: TimeInterval, total: TimeInterval)

    /// Timer is paused with time remaining
    /// - Parameters:
    ///   - remaining: Time remaining when paused in seconds
    ///   - total: Total duration of the timer in seconds
    case paused(remaining: TimeInterval, total: TimeInterval)

    /// Timer has completed its countdown
    case completed

    /// The remaining time in seconds, or nil if idle/completed
    var remainingTime: TimeInterval? {
        switch self {
        case .idle, .completed:
            return nil
        case .running(let remaining, _), .paused(let remaining, _):
            return remaining
        }
    }

    /// The total duration in seconds, or nil if idle/completed
    var totalTime: TimeInterval? {
        switch self {
        case .idle, .completed:
            return nil
        case .running(_, let total), .paused(_, let total):
            return total
        }
    }

    /// Progress from 0.0 (just started) to 1.0 (completed)
    /// Returns 0.0 for idle state and 1.0 for completed state
    var progress: Double {
        switch self {
        case .idle:
            return 0.0
        case .completed:
            return 1.0
        case .running(let remaining, let total), .paused(let remaining, let total):
            guard total > 0 else { return 0.0 }
            return 1.0 - (remaining / total)
        }
    }

    /// Whether the timer is currently running
    var isRunning: Bool {
        if case .running = self { return true }
        return false
    }

    /// Whether the timer is paused
    var isPaused: Bool {
        if case .paused = self { return true }
        return false
    }

    /// Whether the timer is idle (not started)
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }

    /// Whether the timer has completed
    var isCompleted: Bool {
        if case .completed = self { return true }
        return false
    }

    /// Whether there is an active timer (running or paused)
    var isActive: Bool {
        switch self {
        case .running, .paused:
            return true
        case .idle, .completed:
            return false
        }
    }
}
