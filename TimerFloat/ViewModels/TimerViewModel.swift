import Foundation
import SwiftUI

/// ViewModel for timer UI using Observation framework
/// MainActor isolated for safe UI updates
@MainActor
@Observable
final class TimerViewModel {
    /// Current timer state
    private(set) var state: TimerState = .idle

    /// The timer service actor
    private let timerService = TimerService()

    /// Task for observing timer state changes
    /// nonisolated(unsafe) to allow cancellation from deinit
    nonisolated(unsafe) private var observationTask: Task<Void, Never>?

    /// Formatted time string in MM:SS format
    var formattedTime: String {
        let timeValue: TimeInterval

        switch state {
        case .idle, .completed:
            return "00:00"
        case .running(let remaining, _), .paused(let remaining, _):
            timeValue = remaining
        case .stopwatchRunning(let elapsed), .stopwatchPaused(let elapsed):
            timeValue = elapsed
        }

        let minutes = Int(timeValue) / 60
        let seconds = Int(timeValue) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Formatted time with centiseconds (MM:SS.CC) for stopwatch display
    var formattedTimeWithMillis: String {
        let timeValue: TimeInterval

        switch state {
        case .idle, .completed:
            return "00:00.00"
        case .running(let remaining, _), .paused(let remaining, _):
            timeValue = remaining
        case .stopwatchRunning(let elapsed), .stopwatchPaused(let elapsed):
            timeValue = elapsed
        }

        let totalSeconds = Int(timeValue)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let centiseconds = Int((timeValue.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }

    /// Progress from 0.0 to 1.0
    var progress: Double {
        state.progress
    }

    /// Whether the timer is currently running
    var isRunning: Bool {
        state.isRunning
    }

    /// Whether the timer is paused
    var isPaused: Bool {
        state.isPaused
    }

    /// Whether there is an active timer (running or paused)
    var isActive: Bool {
        state.isActive
    }

    /// Whether the timer has completed
    var isCompleted: Bool {
        state.isCompleted
    }

    /// Whether currently in stopwatch mode
    var isStopwatch: Bool {
        state.isStopwatch
    }

    /// Current timer mode, or nil if idle
    var currentMode: TimerMode? {
        switch state {
        case .idle, .completed:
            return nil
        case .running, .paused:
            return .countdown
        case .stopwatchRunning, .stopwatchPaused:
            return .stopwatch
        }
    }

    init() {
        startObserving()
    }

    deinit {
        observationTask?.cancel()
    }

    /// Start observing timer state changes
    private func startObserving() {
        observationTask = Task { [weak self] in
            guard let self else { return }
            let stream = await timerService.stateStream
            for await newState in stream {
                self.state = newState
            }
        }
    }

    /// Start a timer with the given duration in seconds
    func startTimer(duration: TimeInterval) {
        Task {
            do {
                try await timerService.startTimer(duration: duration)
            } catch {
                Log.timer.error("Failed to start timer: \(error)")
            }
        }
    }

    /// Start a timer with the given duration in minutes
    func startTimer(minutes: Int) {
        startTimer(duration: TimeInterval(minutes * 60))
    }

    /// Pause the running timer
    func pauseTimer() {
        Task {
            do {
                try await timerService.pauseTimer()
            } catch {
                Log.timer.error("Failed to pause timer: \(error)")
            }
        }
    }

    /// Resume a paused timer
    func resumeTimer() {
        Task {
            do {
                try await timerService.resumeTimer()
            } catch {
                Log.timer.error("Failed to resume timer: \(error)")
            }
        }
    }

    /// Cancel the current timer
    func cancelTimer() {
        Task {
            do {
                try await timerService.cancelTimer()
            } catch {
                Log.timer.error("Failed to cancel timer: \(error)")
            }
        }
    }

    /// Toggle between running and paused states
    func toggleTimer() {
        if isRunning {
            if isStopwatch {
                pauseStopwatch()
            } else {
                pauseTimer()
            }
        } else if isPaused {
            if isStopwatch {
                resumeStopwatch()
            } else {
                resumeTimer()
            }
        }
    }

    /// Reset the timer to idle state
    func resetTimer() {
        Task {
            await timerService.reset()
        }
    }

    // MARK: - Stopwatch Methods

    /// Start the stopwatch
    func startStopwatch() {
        Task {
            await timerService.startStopwatch()
        }
    }

    /// Pause the stopwatch
    func pauseStopwatch() {
        Task {
            do {
                try await timerService.pauseStopwatch()
            } catch {
                Log.timer.error("Failed to pause stopwatch: \(error)")
            }
        }
    }

    /// Resume the stopwatch
    func resumeStopwatch() {
        Task {
            do {
                try await timerService.resumeStopwatch()
            } catch {
                Log.timer.error("Failed to resume stopwatch: \(error)")
            }
        }
    }

    /// Stop the stopwatch
    func stopStopwatch() {
        Task {
            await timerService.stopStopwatch()
        }
    }
}
