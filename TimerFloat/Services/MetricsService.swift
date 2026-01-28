import Foundation
import os

/// Service for collecting app usage metrics locally
/// All data is stored on-device only, no external transmission
@MainActor
final class MetricsService {
    /// Shared instance for app-wide metrics collection
    static let shared = MetricsService()

    // MARK: - Session Metrics

    /// Number of timers started this session
    private(set) var sessionTimerStarts: Int = 0

    /// Number of timers completed this session
    private(set) var sessionTimerCompletions: Int = 0

    /// Number of timers cancelled this session
    private(set) var sessionTimerCancellations: Int = 0

    /// Total duration of all started timers this session (in seconds)
    private(set) var sessionTotalDuration: TimeInterval = 0

    /// Number of overlay drag operations this session
    private(set) var sessionOverlayDrags: Int = 0

    /// Session start time
    private let sessionStartTime = Date()

    // MARK: - Lifetime Metrics (persisted)

    /// UserDefaults keys for persistence
    private enum Keys {
        static let lifetimeTimerStarts = "metrics.lifetime.timerStarts"
        static let lifetimeTimerCompletions = "metrics.lifetime.timerCompletions"
        static let lifetimeTimerCancellations = "metrics.lifetime.timerCancellations"
        static let lifetimeTotalDuration = "metrics.lifetime.totalDuration"
        static let lifetimeOverlayDrags = "metrics.lifetime.overlayDrags"
        static let lifetimeSessionCount = "metrics.lifetime.sessionCount"
    }

    /// Lifetime timer starts
    private(set) var lifetimeTimerStarts: Int {
        get { UserDefaults.standard.integer(forKey: Keys.lifetimeTimerStarts) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lifetimeTimerStarts) }
    }

    /// Lifetime timer completions
    private(set) var lifetimeTimerCompletions: Int {
        get { UserDefaults.standard.integer(forKey: Keys.lifetimeTimerCompletions) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lifetimeTimerCompletions) }
    }

    /// Lifetime timer cancellations
    private(set) var lifetimeTimerCancellations: Int {
        get { UserDefaults.standard.integer(forKey: Keys.lifetimeTimerCancellations) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lifetimeTimerCancellations) }
    }

    /// Lifetime total duration of all timers (in seconds)
    private(set) var lifetimeTotalDuration: TimeInterval {
        get { UserDefaults.standard.double(forKey: Keys.lifetimeTotalDuration) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lifetimeTotalDuration) }
    }

    /// Lifetime overlay drag count
    private(set) var lifetimeOverlayDrags: Int {
        get { UserDefaults.standard.integer(forKey: Keys.lifetimeOverlayDrags) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lifetimeOverlayDrags) }
    }

    /// Lifetime session count
    private(set) var lifetimeSessionCount: Int {
        get { UserDefaults.standard.integer(forKey: Keys.lifetimeSessionCount) }
        set { UserDefaults.standard.set(newValue, forKey: Keys.lifetimeSessionCount) }
    }

    // MARK: - Computed Metrics

    /// Session completion ratio (0.0 to 1.0)
    var sessionCompletionRatio: Double {
        let total = sessionTimerCompletions + sessionTimerCancellations
        guard total > 0 else { return 0 }
        return Double(sessionTimerCompletions) / Double(total)
    }

    /// Lifetime completion ratio (0.0 to 1.0)
    var lifetimeCompletionRatio: Double {
        let total = lifetimeTimerCompletions + lifetimeTimerCancellations
        guard total > 0 else { return 0 }
        return Double(lifetimeTimerCompletions) / Double(total)
    }

    /// Session average timer duration (in seconds)
    var sessionAverageDuration: TimeInterval {
        guard sessionTimerStarts > 0 else { return 0 }
        return sessionTotalDuration / Double(sessionTimerStarts)
    }

    /// Lifetime average timer duration (in seconds)
    var lifetimeAverageDuration: TimeInterval {
        guard lifetimeTimerStarts > 0 else { return 0 }
        return lifetimeTotalDuration / Double(lifetimeTimerStarts)
    }

    /// Session duration
    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartTime)
    }

    // MARK: - Initialization

    private init() {
        // Increment session count
        lifetimeSessionCount += 1
        Log.app.info("MetricsService initialized - Session #\(self.lifetimeSessionCount)")
    }

    // MARK: - Recording Methods

    /// Record a timer start event
    /// - Parameter duration: The timer duration in seconds
    func recordTimerStart(duration: TimeInterval) {
        sessionTimerStarts += 1
        sessionTotalDuration += duration
        lifetimeTimerStarts += 1
        lifetimeTotalDuration += duration

        Log.app.debug("Metrics: Timer started (duration: \(Int(duration))s, session starts: \(self.sessionTimerStarts))")
    }

    /// Record a timer completion event
    func recordTimerCompletion() {
        sessionTimerCompletions += 1
        lifetimeTimerCompletions += 1

        Log.app.debug("Metrics: Timer completed (session completions: \(self.sessionTimerCompletions), ratio: \(String(format: "%.1f%%", self.sessionCompletionRatio * 100)))")
    }

    /// Record a timer cancellation event
    func recordTimerCancellation() {
        sessionTimerCancellations += 1
        lifetimeTimerCancellations += 1

        Log.app.debug("Metrics: Timer cancelled (session cancellations: \(self.sessionTimerCancellations))")
    }

    /// Record an overlay drag event
    func recordOverlayDrag() {
        sessionOverlayDrags += 1
        lifetimeOverlayDrags += 1

        Log.app.debug("Metrics: Overlay dragged (session drags: \(self.sessionOverlayDrags))")
    }

    // MARK: - Debug Output

    /// Log all current metrics for debugging
    func logAllMetrics() {
        Log.app.info("""
        === TimerFloat Metrics ===
        Session #\(self.lifetimeSessionCount) (duration: \(Int(self.sessionDuration))s)

        SESSION METRICS:
        - Timer starts: \(self.sessionTimerStarts)
        - Completions: \(self.sessionTimerCompletions)
        - Cancellations: \(self.sessionTimerCancellations)
        - Completion ratio: \(String(format: "%.1f%%", self.sessionCompletionRatio * 100))
        - Avg duration: \(Int(self.sessionAverageDuration))s
        - Overlay drags: \(self.sessionOverlayDrags)

        LIFETIME METRICS:
        - Total sessions: \(self.lifetimeSessionCount)
        - Timer starts: \(self.lifetimeTimerStarts)
        - Completions: \(self.lifetimeTimerCompletions)
        - Cancellations: \(self.lifetimeTimerCancellations)
        - Completion ratio: \(String(format: "%.1f%%", self.lifetimeCompletionRatio * 100))
        - Avg duration: \(Int(self.lifetimeAverageDuration))s
        - Overlay drags: \(self.lifetimeOverlayDrags)
        ==========================
        """)
    }

    /// Reset all lifetime metrics (for debugging/testing)
    func resetLifetimeMetrics() {
        lifetimeTimerStarts = 0
        lifetimeTimerCompletions = 0
        lifetimeTimerCancellations = 0
        lifetimeTotalDuration = 0
        lifetimeOverlayDrags = 0
        lifetimeSessionCount = 1  // Current session

        Log.app.info("Metrics: Lifetime metrics reset")
    }
}
