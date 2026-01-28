import Foundation
import os.log
import os.signpost

/// Errors that can occur during timer operations
enum TimerError: Error, Sendable {
    /// Attempted to start a timer when one is already running
    case timerAlreadyRunning
    /// Attempted to pause when timer is not running
    case timerNotRunning
    /// Attempted to resume when timer is not paused
    case timerNotPaused
    /// Attempted an operation when no timer is active
    case noActiveTimer
    /// Invalid duration provided
    case invalidDuration
}

/// Actor-based timer service for thread-safe countdown management
/// Uses structured concurrency with AsyncStream for timer ticks
actor TimerService {
    /// Current state of the timer
    private(set) var state: TimerState = .idle

    /// Task managing the countdown
    private var countdownTask: Task<Void, Never>?

    /// Continuation for the state stream
    private var stateContinuation: AsyncStream<TimerState>.Continuation?

    /// Signpost log for performance instrumentation
    private static let signpostLog = OSLog(subsystem: "com.timerfloat", category: .pointsOfInterest)

    /// Current signpost ID for timer interval tracking
    private var timerSignpostID: OSSignpostID?

    /// Stream of timer state changes for observers
    var stateStream: AsyncStream<TimerState> {
        AsyncStream { continuation in
            self.stateContinuation = continuation
            continuation.yield(self.state)

            continuation.onTermination = { _ in
                Task { await self.clearContinuation() }
            }
        }
    }

    /// Start a new timer with the specified duration
    /// - Parameter duration: Duration in seconds (must be positive)
    /// - Throws: TimerError.timerAlreadyRunning if a timer is active
    /// - Throws: TimerError.invalidDuration if duration is not positive
    func startTimer(duration: TimeInterval) throws(TimerError) {
        guard duration > 0 else {
            throw .invalidDuration
        }

        guard !state.isActive else {
            throw .timerAlreadyRunning
        }

        Log.timer.info("Starting timer with duration: \(duration) seconds")

        // Begin signpost interval for timer duration tracking
        timerSignpostID = OSSignpostID(log: Self.signpostLog)
        os_signpost(.begin, log: Self.signpostLog, name: "Timer", signpostID: timerSignpostID!, "duration: %.1f seconds", duration)

        state = .running(remaining: duration, total: duration)
        notifyStateChange()

        countdownTask = Task {
            await runCountdown(total: duration)
        }
    }

    /// Pause the currently running timer
    /// - Throws: TimerError.timerNotRunning if timer is not running
    func pauseTimer() throws(TimerError) {
        guard case .running(let remaining, let total) = state else {
            throw .timerNotRunning
        }

        Log.timer.info("Pausing timer with \(remaining) seconds remaining")

        countdownTask?.cancel()
        countdownTask = nil

        state = .paused(remaining: remaining, total: total)
        notifyStateChange()
    }

    /// Resume a paused timer
    /// - Throws: TimerError.timerNotPaused if timer is not paused
    func resumeTimer() throws(TimerError) {
        guard case .paused(let remaining, let total) = state else {
            throw .timerNotPaused
        }

        Log.timer.info("Resuming timer with \(remaining) seconds remaining")

        state = .running(remaining: remaining, total: total)
        notifyStateChange()

        countdownTask = Task {
            await runCountdown(total: total, startingFrom: remaining)
        }
    }

    /// Cancel the current timer and reset to idle
    /// - Throws: TimerError.noActiveTimer if no timer is active
    func cancelTimer() throws(TimerError) {
        guard state.isActive else {
            throw .noActiveTimer
        }

        Log.timer.info("Cancelling timer")

        // End signpost interval (cancelled)
        if let signpostID = timerSignpostID {
            os_signpost(.end, log: Self.signpostLog, name: "Timer", signpostID: signpostID, "cancelled")
            timerSignpostID = nil
        }

        countdownTask?.cancel()
        countdownTask = nil

        state = .idle
        notifyStateChange()
    }

    /// Reset the timer to idle state (does not throw)
    func reset() {
        Log.timer.info("Resetting timer to idle")

        // End signpost interval (reset)
        if let signpostID = timerSignpostID {
            os_signpost(.end, log: Self.signpostLog, name: "Timer", signpostID: signpostID, "reset")
            timerSignpostID = nil
        }

        countdownTask?.cancel()
        countdownTask = nil

        state = .idle
        notifyStateChange()
    }

    /// Run the countdown loop
    private func runCountdown(total: TimeInterval, startingFrom: TimeInterval? = nil) async {
        let startTime = Date()
        let initialRemaining = startingFrom ?? total

        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSince(startTime)
            let remaining = max(0, initialRemaining - elapsed)

            if remaining <= 0 {
                // End signpost interval (completed)
                if let signpostID = timerSignpostID {
                    os_signpost(.end, log: Self.signpostLog, name: "Timer", signpostID: signpostID, "completed")
                    timerSignpostID = nil
                }

                state = .completed
                notifyStateChange()
                Log.timer.info("Timer completed")
                return
            }

            // Signpost event for timer tick (for performance profiling)
            os_signpost(.event, log: Self.signpostLog, name: "TimerTick", "remaining: %.1f", remaining)

            state = .running(remaining: remaining, total: total)
            notifyStateChange()

            // Sleep for approximately 1 second, but adjust to stay accurate
            let nextTick = ceil(remaining) - remaining
            let sleepDuration = nextTick > 0.01 ? nextTick : 1.0

            do {
                try await Task.sleep(for: .seconds(sleepDuration))
            } catch {
                // Task was cancelled
                return
            }
        }
    }

    /// Notify observers of state change
    private func notifyStateChange() {
        stateContinuation?.yield(state)
    }

    /// Clear the continuation when stream terminates
    private func clearContinuation() {
        stateContinuation = nil
    }
}
