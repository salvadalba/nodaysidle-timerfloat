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

    /// Stopwatch is actively counting up
    /// - Parameter elapsed: Time elapsed in seconds
    case stopwatchRunning(elapsed: TimeInterval)

    /// Stopwatch is paused
    /// - Parameter elapsed: Time elapsed when paused in seconds
    case stopwatchPaused(elapsed: TimeInterval)

    /// The remaining time in seconds, or nil if idle/completed/stopwatch
    var remainingTime: TimeInterval? {
        switch self {
        case .idle, .completed, .stopwatchRunning, .stopwatchPaused:
            return nil
        case .running(let remaining, _), .paused(let remaining, _):
            return remaining
        }
    }

    /// The total duration in seconds, or nil if idle/completed/stopwatch
    var totalTime: TimeInterval? {
        switch self {
        case .idle, .completed, .stopwatchRunning, .stopwatchPaused:
            return nil
        case .running(_, let total), .paused(_, let total):
            return total
        }
    }

    /// Progress from 0.0 (just started) to 1.0 (completed)
    /// Returns 0.0 for idle state, stopwatch states, and 1.0 for completed state
    var progress: Double {
        switch self {
        case .idle, .stopwatchRunning, .stopwatchPaused:
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
        switch self {
        case .running, .stopwatchRunning:
            return true
        default:
            return false
        }
    }

    /// Whether the timer is paused
    var isPaused: Bool {
        switch self {
        case .paused, .stopwatchPaused:
            return true
        default:
            return false
        }
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
        case .running, .paused, .stopwatchRunning, .stopwatchPaused:
            return true
        case .idle, .completed:
            return false
        }
    }

    /// The elapsed time in seconds (for stopwatch mode), or nil if countdown
    var elapsedTime: TimeInterval? {
        switch self {
        case .stopwatchRunning(let elapsed), .stopwatchPaused(let elapsed):
            return elapsed
        case .idle, .running, .paused, .completed:
            return nil
        }
    }

    /// Whether this is a stopwatch state
    var isStopwatch: Bool {
        switch self {
        case .stopwatchRunning, .stopwatchPaused:
            return true
        default:
            return false
        }
    }
}
