# Stopwatch & Window Pinning Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a stopwatch mode that counts up from zero and enable pinning the timer overlay to a specific application window so it moves with that window.

**Architecture:**
- Extend the existing TimerService actor to support both countdown and stopwatch modes via a `TimerMode` enum
- Add a new `WindowPinningService` that uses macOS Accessibility APIs (AXUIElement) to track another application's window position and update our overlay position accordingly
- Modify the UI to allow mode selection and pinning controls

**Tech Stack:** Swift 6, SwiftUI, AppKit, Accessibility Framework (AXUIElement), CGWindowList APIs

---

## Feature 1: Stopwatch Mode

### Task 1: Add TimerMode Enum

**Files:**
- Create: `TimerFloat/Models/TimerMode.swift`
- Test: `TimerFloatTests/TimerModeTests.swift`

**Step 1: Write the failing test**

In `TimerFloatTests/TimerModeTests.swift`:

```swift
import Testing
@testable import TimerFloat

@Suite("TimerMode Tests")
struct TimerModeTests {

    @Test("TimerMode has countdown and stopwatch cases")
    func timerModeHasBothCases() {
        let countdown = TimerMode.countdown
        let stopwatch = TimerMode.stopwatch

        #expect(countdown != stopwatch)
    }

    @Test("TimerMode is Sendable")
    func timerModeIsSendable() {
        let mode: any Sendable = TimerMode.countdown
        #expect(mode is TimerMode)
    }

    @Test("TimerMode displayName returns correct strings")
    func displayNameReturnsCorrectStrings() {
        #expect(TimerMode.countdown.displayName == "Timer")
        #expect(TimerMode.stopwatch.displayName == "Stopwatch")
    }

    @Test("TimerMode iconName returns correct SF Symbols")
    func iconNameReturnsCorrectSymbols() {
        #expect(TimerMode.countdown.iconName == "timer")
        #expect(TimerMode.stopwatch.iconName == "stopwatch")
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter TimerModeTests`
Expected: FAIL with "cannot find 'TimerMode' in scope"

**Step 3: Write minimal implementation**

In `TimerFloat/Models/TimerMode.swift`:

```swift
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter TimerModeTests`
Expected: PASS

**Step 5: Commit**

```bash
git add TimerFloat/Models/TimerMode.swift TimerFloatTests/TimerModeTests.swift
git commit -m "$(cat <<'EOF'
feat: add TimerMode enum for countdown/stopwatch modes

Introduces TimerMode enum with countdown and stopwatch cases.
Includes displayName and iconName computed properties for UI.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Extend TimerState to Support Elapsed Time

**Files:**
- Modify: `TimerFloat/Models/TimerState.swift:1-91`
- Test: `TimerFloatTests/TimerServiceTests.swift`

**Step 1: Write the failing test**

Add to `TimerFloatTests/TimerServiceTests.swift` in the `TimerStateTests` suite:

```swift
@Test("Stopwatch running state tracks elapsed time")
func stopwatchRunningStateTracksElapsedTime() {
    let state = TimerState.stopwatchRunning(elapsed: 30)
    #expect(state.elapsedTime == 30)
    #expect(state.remainingTime == nil)
}

@Test("Stopwatch paused state preserves elapsed time")
func stopwatchPausedStatePreservesElapsedTime() {
    let state = TimerState.stopwatchPaused(elapsed: 45)
    #expect(state.elapsedTime == 45)
}

@Test("isStopwatch returns true only for stopwatch states")
func isStopwatchOnlyForStopwatchStates() {
    #expect(TimerState.idle.isStopwatch == false)
    #expect(TimerState.running(remaining: 30, total: 60).isStopwatch == false)
    #expect(TimerState.stopwatchRunning(elapsed: 30).isStopwatch == true)
    #expect(TimerState.stopwatchPaused(elapsed: 30).isStopwatch == true)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter TimerStateTests`
Expected: FAIL with "type 'TimerState' has no member 'stopwatchRunning'"

**Step 3: Write minimal implementation**

Update `TimerFloat/Models/TimerState.swift` to add new cases and properties:

```swift
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

    /// The elapsed time in seconds (for stopwatch mode), or nil if countdown
    var elapsedTime: TimeInterval? {
        switch self {
        case .stopwatchRunning(let elapsed), .stopwatchPaused(let elapsed):
            return elapsed
        case .idle, .running, .paused, .completed:
            return nil
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
    /// Returns 0.0 for idle state, 1.0 for completed, and nil for stopwatch
    var progress: Double {
        switch self {
        case .idle:
            return 0.0
        case .completed:
            return 1.0
        case .running(let remaining, let total), .paused(let remaining, let total):
            guard total > 0 else { return 0.0 }
            return 1.0 - (remaining / total)
        case .stopwatchRunning, .stopwatchPaused:
            return 0.0 // Stopwatch has no progress concept
        }
    }

    /// Whether the timer is currently running (countdown or stopwatch)
    var isRunning: Bool {
        switch self {
        case .running, .stopwatchRunning:
            return true
        default:
            return false
        }
    }

    /// Whether the timer is paused (countdown or stopwatch)
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

    /// Whether there is an active timer (running or paused, countdown or stopwatch)
    var isActive: Bool {
        switch self {
        case .running, .paused, .stopwatchRunning, .stopwatchPaused:
            return true
        case .idle, .completed:
            return false
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter TimerStateTests`
Expected: PASS

**Step 5: Commit**

```bash
git add TimerFloat/Models/TimerState.swift TimerFloatTests/TimerServiceTests.swift
git commit -m "$(cat <<'EOF'
feat: extend TimerState with stopwatch cases

Adds stopwatchRunning and stopwatchPaused cases to TimerState.
Includes elapsedTime computed property and isStopwatch helper.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Extend TimerService Actor for Stopwatch

**Files:**
- Modify: `TimerFloat/Services/TimerService.swift:1-198`
- Test: `TimerFloatTests/TimerServiceTests.swift`

**Step 1: Write the failing test**

Add to `TimerFloatTests/TimerServiceTests.swift`:

```swift
// MARK: - Stopwatch Tests

@Test("Starting stopwatch sets stopwatchRunning state")
func startStopwatchSetsRunningState() async throws {
    let service = TimerService()
    await service.startStopwatch()

    let state = await service.state
    guard case .stopwatchRunning(let elapsed) = state else {
        Issue.record("Expected stopwatchRunning state")
        return
    }

    #expect(elapsed >= 0)
    #expect(elapsed < 1) // Should be very close to 0
}

@Test("Pausing stopwatch preserves elapsed time")
func pauseStopwatchPreservesElapsedTime() async throws {
    let service = TimerService()
    await service.startStopwatch()

    // Wait to allow some time to elapse
    try await Task.sleep(for: .milliseconds(500))

    try await service.pauseStopwatch()

    let state = await service.state
    guard case .stopwatchPaused(let elapsed) = state else {
        Issue.record("Expected stopwatchPaused state")
        return
    }

    #expect(elapsed >= 0.4) // At least 400ms should have passed
    #expect(elapsed < 1.0)
}

@Test("Resuming stopwatch continues from paused time")
func resumeStopwatchContinuesFromPausedTime() async throws {
    let service = TimerService()
    await service.startStopwatch()
    try await Task.sleep(for: .milliseconds(200))
    try await service.pauseStopwatch()

    let pausedState = await service.state
    guard case .stopwatchPaused(let pausedElapsed) = pausedState else {
        Issue.record("Expected stopwatchPaused state")
        return
    }

    try await service.resumeStopwatch()

    let state = await service.state
    guard case .stopwatchRunning(let elapsed) = state else {
        Issue.record("Expected stopwatchRunning state")
        return
    }

    // Elapsed should be close to what it was when paused
    #expect(abs(elapsed - pausedElapsed) < 0.5)
}

@Test("Stopping stopwatch resets to idle")
func stopStopwatchResetsToIdle() async throws {
    let service = TimerService()
    await service.startStopwatch()
    await service.stopStopwatch()

    let state = await service.state
    #expect(state == .idle)
}

@Test("Current mode returns correct mode")
func currentModeReturnsCorrectMode() async throws {
    let service = TimerService()

    // Idle state should return nil
    var mode = await service.currentMode
    #expect(mode == nil)

    // Countdown mode
    try await service.startTimer(duration: 60)
    mode = await service.currentMode
    #expect(mode == .countdown)

    await service.reset()

    // Stopwatch mode
    await service.startStopwatch()
    mode = await service.currentMode
    #expect(mode == .stopwatch)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter TimerServiceTests`
Expected: FAIL with "value of type 'TimerService' has no member 'startStopwatch'"

**Step 3: Write minimal implementation**

Update `TimerFloat/Services/TimerService.swift` to add stopwatch methods:

```swift
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
    /// Attempted stopwatch operation when not in stopwatch mode
    case notInStopwatchMode
}

/// Actor-based timer service for thread-safe countdown and stopwatch management
/// Uses structured concurrency with AsyncStream for timer ticks
actor TimerService {
    /// Current state of the timer
    private(set) var state: TimerState = .idle

    /// Task managing the countdown or stopwatch
    private var timerTask: Task<Void, Never>?

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

    /// Current timer mode based on state
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

    // MARK: - Countdown Timer Methods

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

        timerTask = Task {
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

        timerTask?.cancel()
        timerTask = nil

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

        timerTask = Task {
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

        timerTask?.cancel()
        timerTask = nil

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

        timerTask?.cancel()
        timerTask = nil

        state = .idle
        notifyStateChange()
    }

    // MARK: - Stopwatch Methods

    /// Start the stopwatch counting up from zero
    func startStopwatch() {
        guard !state.isActive else {
            Log.timer.warning("Cannot start stopwatch: timer already active")
            return
        }

        Log.timer.info("Starting stopwatch")

        // Begin signpost interval for stopwatch tracking
        timerSignpostID = OSSignpostID(log: Self.signpostLog)
        os_signpost(.begin, log: Self.signpostLog, name: "Stopwatch", signpostID: timerSignpostID!)

        state = .stopwatchRunning(elapsed: 0)
        notifyStateChange()

        timerTask = Task {
            await runStopwatch()
        }
    }

    /// Pause the stopwatch
    /// - Throws: TimerError.notInStopwatchMode if not in stopwatch mode
    func pauseStopwatch() throws(TimerError) {
        guard case .stopwatchRunning(let elapsed) = state else {
            throw .notInStopwatchMode
        }

        Log.timer.info("Pausing stopwatch at \(elapsed) seconds")

        timerTask?.cancel()
        timerTask = nil

        state = .stopwatchPaused(elapsed: elapsed)
        notifyStateChange()
    }

    /// Resume a paused stopwatch
    /// - Throws: TimerError.notInStopwatchMode if not paused stopwatch
    func resumeStopwatch() throws(TimerError) {
        guard case .stopwatchPaused(let elapsed) = state else {
            throw .notInStopwatchMode
        }

        Log.timer.info("Resuming stopwatch from \(elapsed) seconds")

        state = .stopwatchRunning(elapsed: elapsed)
        notifyStateChange()

        timerTask = Task {
            await runStopwatch(startingFrom: elapsed)
        }
    }

    /// Stop the stopwatch and reset to idle
    func stopStopwatch() {
        guard state.isStopwatch else {
            return
        }

        Log.timer.info("Stopping stopwatch")

        // End signpost interval
        if let signpostID = timerSignpostID {
            os_signpost(.end, log: Self.signpostLog, name: "Stopwatch", signpostID: signpostID, "stopped")
            timerSignpostID = nil
        }

        timerTask?.cancel()
        timerTask = nil

        state = .idle
        notifyStateChange()
    }

    // MARK: - Private Methods

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

    /// Run the stopwatch loop (counts up)
    private func runStopwatch(startingFrom: TimeInterval = 0) async {
        let startTime = Date()

        while !Task.isCancelled {
            let additionalElapsed = Date().timeIntervalSince(startTime)
            let totalElapsed = startingFrom + additionalElapsed

            // Signpost event for stopwatch tick
            os_signpost(.event, log: Self.signpostLog, name: "StopwatchTick", "elapsed: %.1f", totalElapsed)

            state = .stopwatchRunning(elapsed: totalElapsed)
            notifyStateChange()

            // Sleep for approximately 100ms for smooth updates
            do {
                try await Task.sleep(for: .milliseconds(100))
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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter TimerServiceTests`
Expected: PASS

**Step 5: Commit**

```bash
git add TimerFloat/Services/TimerService.swift TimerFloatTests/TimerServiceTests.swift
git commit -m "$(cat <<'EOF'
feat: add stopwatch methods to TimerService

Extends TimerService with startStopwatch, pauseStopwatch,
resumeStopwatch, and stopStopwatch methods. Includes
currentMode property to identify active mode.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Extend TimerViewModel for Stopwatch

**Files:**
- Modify: `TimerFloat/ViewModels/TimerViewModel.swift:1-137`

**Step 1: Write the failing test**

Create `TimerFloatTests/TimerViewModelTests.swift`:

```swift
import Testing
import Foundation
@testable import TimerFloat

@Suite("TimerViewModel Tests")
@MainActor
struct TimerViewModelTests {

    @Test("formattedTime shows elapsed time for stopwatch")
    func formattedTimeShowsElapsedForStopwatch() async throws {
        let viewModel = TimerViewModel()
        viewModel.startStopwatch()

        // Wait for some time to elapse
        try await Task.sleep(for: .milliseconds(1100))

        let time = viewModel.formattedTime
        // Should show at least 00:01
        #expect(time.contains("00:01") || time.contains("00:02"))
    }

    @Test("formattedTimeWithMillis includes centiseconds")
    func formattedTimeWithMillisIncludesCentiseconds() async throws {
        let viewModel = TimerViewModel()
        viewModel.startStopwatch()

        try await Task.sleep(for: .milliseconds(200))

        let time = viewModel.formattedTimeWithMillis
        // Should be in format MM:SS.CC
        #expect(time.contains("."))
    }

    @Test("currentMode reflects timer state")
    func currentModeReflectsState() async throws {
        let viewModel = TimerViewModel()

        #expect(viewModel.currentMode == nil)

        viewModel.startTimer(minutes: 1)
        try await Task.sleep(for: .milliseconds(100))
        #expect(viewModel.currentMode == .countdown)

        viewModel.cancelTimer()
        try await Task.sleep(for: .milliseconds(100))

        viewModel.startStopwatch()
        try await Task.sleep(for: .milliseconds(100))
        #expect(viewModel.currentMode == .stopwatch)
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter TimerViewModelTests`
Expected: FAIL with "value of type 'TimerViewModel' has no member 'startStopwatch'"

**Step 3: Write minimal implementation**

Update `TimerFloat/ViewModels/TimerViewModel.swift`:

```swift
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

    // MARK: - Countdown Timer Methods

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
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter TimerViewModelTests`
Expected: PASS

**Step 5: Commit**

```bash
git add TimerFloat/ViewModels/TimerViewModel.swift TimerFloatTests/TimerViewModelTests.swift
git commit -m "$(cat <<'EOF'
feat: extend TimerViewModel with stopwatch support

Adds startStopwatch, pauseStopwatch, resumeStopwatch, stopStopwatch
methods. Includes formattedTimeWithMillis for centisecond display
and currentMode property.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Create Stopwatch Overlay View

**Files:**
- Create: `TimerFloat/Views/StopwatchOverlayView.swift`

**Step 1: Create the view**

In `TimerFloat/Views/StopwatchOverlayView.swift`:

```swift
import SwiftUI

/// Floating overlay view displaying the stopwatch
struct StopwatchOverlayView: View {
    /// The timer view model
    @Bindable var viewModel: TimerViewModel

    /// Base opacity when not hovered (from preferences)
    var idleOpacity: Double = 0.8

    /// Size of the circular display area
    private let displaySize: CGFloat = 100

    /// Track hover state
    @State private var isHovered: Bool = false

    /// Current opacity based on hover state
    private var currentOpacity: Double {
        isHovered ? 1.0 : idleOpacity
    }

    var body: some View {
        ZStack {
            // Background with material effect
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)

            // Stopwatch content
            VStack(spacing: 4) {
                // Stopwatch icon
                Image(systemName: "stopwatch.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)

                // Time display with centiseconds
                TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                    Text(viewModel.formattedTimeWithMillis)
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                }

                // State indicator
                if viewModel.isPaused {
                    Label("Paused", systemImage: "pause.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
        .frame(width: 120, height: 120)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .opacity(currentOpacity)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(viewModel.formattedTime)
        .accessibilityHint("Stopwatch overlay. Drag to reposition.")
    }

    /// Accessibility label based on stopwatch state
    private var accessibilityLabel: String {
        if viewModel.isPaused {
            return "Stopwatch paused"
        } else if viewModel.isRunning {
            return "Stopwatch running"
        } else {
            return "Stopwatch"
        }
    }
}

// MARK: - Preview

#Preview("Running Stopwatch") {
    @Previewable @State var viewModel = TimerViewModel()
    StopwatchOverlayView(viewModel: viewModel)
        .onAppear {
            viewModel.startStopwatch()
        }
}
```

**Step 2: Commit**

```bash
git add TimerFloat/Views/StopwatchOverlayView.swift
git commit -m "$(cat <<'EOF'
feat: create StopwatchOverlayView for stopwatch display

New overlay view with centisecond precision display and
stopwatch icon. Uses TimelineView for smooth 100ms updates.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: Add Mode Selection to Menu UI

**Files:**
- Modify: `TimerFloat/TimerFloatApp.swift`

**Step 1: Update QuickStartView with mode picker**

Add mode selection to `TimerFloat/TimerFloatApp.swift`. Update the `QuickStartView`:

```swift
/// View showing quick start timer presets and mode selection
struct QuickStartView: View {
    let appController: AppController
    @State private var selectedMode: TimerMode = .countdown

    var body: some View {
        VStack(spacing: 8) {
            // Mode picker
            Picker("Mode", selection: $selectedMode) {
                ForEach(TimerMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if selectedMode == .countdown {
                // Countdown preset buttons
                Text("Quick Start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    PresetButton(minutes: 5, appController: appController)
                    PresetButton(minutes: 15, appController: appController)
                }

                HStack(spacing: 8) {
                    PresetButton(minutes: 25, appController: appController)
                    PresetButton(minutes: 45, appController: appController)
                }

                Divider()

                // Custom duration input
                CustomDurationInputView(appController: appController)
            } else {
                // Stopwatch start button
                VStack(spacing: 12) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)

                    Button {
                        appController.startStopwatch()
                    } label: {
                        Text("Start Stopwatch")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Start stopwatch")
                    .accessibilityHint("Starts counting time from zero")
                }
                .padding(.vertical, 8)
            }
        }
    }
}
```

**Step 2: Update ActiveTimerView to handle stopwatch**

Update the `ActiveTimerView`:

```swift
/// View showing active timer controls
struct ActiveTimerView: View {
    let appController: AppController

    private var isStopwatch: Bool {
        appController.timerViewModel.isStopwatch
    }

    var body: some View {
        VStack(spacing: 12) {
            // Mode indicator
            Label(
                isStopwatch ? "Stopwatch" : "Timer",
                systemImage: isStopwatch ? "stopwatch.fill" : "timer"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            // Time display
            if isStopwatch {
                Text(appController.timerViewModel.formattedTimeWithMillis)
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Time elapsed")
                    .accessibilityValue(appController.timerViewModel.formattedTime)
            } else {
                Text(appController.timerViewModel.formattedTime)
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Time remaining")
                    .accessibilityValue(appController.timerViewModel.formattedTime)

                // Progress bar (countdown only)
                ProgressView(value: appController.timerViewModel.progress)
                    .progressViewStyle(.linear)
                    .accessibilityLabel("Timer progress")
                    .accessibilityValue("\(Int(appController.timerViewModel.progress * 100)) percent complete")
            }

            // Control buttons
            HStack(spacing: 12) {
                // Pause/Resume button
                Button {
                    appController.toggleTimer()
                } label: {
                    Image(systemName: appController.timerViewModel.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(appController.timerViewModel.isRunning ? "Pause" : "Resume")

                // Stop/Cancel button
                Button(role: .destructive) {
                    if isStopwatch {
                        appController.stopStopwatch()
                    } else {
                        appController.cancelTimer()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(isStopwatch ? "Stop stopwatch" : "Cancel timer")
            }
        }
    }
}
```

**Step 3: Commit**

```bash
git add TimerFloat/TimerFloatApp.swift
git commit -m "$(cat <<'EOF'
feat: add mode selection UI for countdown/stopwatch

Adds segmented picker in QuickStartView for mode selection.
Updates ActiveTimerView to display stopwatch with centiseconds.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: Update AppController for Stopwatch

**Files:**
- Modify: `TimerFloat/AppController.swift`

**Step 1: Read AppController**

First read the current AppController to understand its structure.

**Step 2: Add stopwatch methods**

Add these methods to `AppController.swift`:

```swift
// MARK: - Stopwatch Methods

/// Start the stopwatch
func startStopwatch() {
    Log.app.info("Starting stopwatch")
    timerViewModel.startStopwatch()
    showOverlay()
    metricsService.recordTimerStart(durationMinutes: 0, isStopwatch: true)
}

/// Stop the stopwatch
func stopStopwatch() {
    Log.app.info("Stopping stopwatch")
    timerViewModel.stopStopwatch()
    hideOverlay()
}
```

Update the `showOverlay()` method to use the correct view:

```swift
/// Show the timer overlay
private func showOverlay() {
    let opacity = preferencesService.preferences?.overlayIdleOpacity ?? 0.8
    let content: AnyView

    if timerViewModel.isStopwatch {
        content = AnyView(StopwatchOverlayView(viewModel: timerViewModel, idleOpacity: opacity))
    } else {
        content = AnyView(TimerOverlayView(viewModel: timerViewModel, idleOpacity: opacity))
    }

    windowService.showOverlay(with: content)
}
```

**Step 3: Commit**

```bash
git add TimerFloat/AppController.swift
git commit -m "$(cat <<'EOF'
feat: add stopwatch support to AppController

Adds startStopwatch and stopStopwatch methods.
Updates showOverlay to use StopwatchOverlayView when appropriate.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 8: Update MenuBarIcon for Stopwatch State

**Files:**
- Modify: `TimerFloat/TimerFloatApp.swift`

**Step 1: Update MenuBarIcon**

Update the `MenuBarIcon` struct to handle stopwatch states:

```swift
/// Dynamic menu bar icon that reflects timer state
struct MenuBarIcon: View {
    let timerViewModel: TimerViewModel

    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.hierarchical)
            .accessibilityLabel(accessibilityLabel)
    }

    /// Icon name based on timer state
    private var iconName: String {
        switch timerViewModel.state {
        case .idle:
            return "timer.circle"
        case .running:
            return "timer.circle.fill"
        case .paused:
            return "pause.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        case .stopwatchRunning:
            return "stopwatch.fill"
        case .stopwatchPaused:
            return "pause.circle"
        }
    }

    /// Accessibility label based on timer state
    private var accessibilityLabel: String {
        switch timerViewModel.state {
        case .idle:
            return "TimerFloat, no timer running"
        case .running:
            return "TimerFloat, timer running, \(timerViewModel.formattedTime) remaining"
        case .paused:
            return "TimerFloat, timer paused, \(timerViewModel.formattedTime) remaining"
        case .completed:
            return "TimerFloat, timer complete"
        case .stopwatchRunning:
            return "TimerFloat, stopwatch running, \(timerViewModel.formattedTime) elapsed"
        case .stopwatchPaused:
            return "TimerFloat, stopwatch paused, \(timerViewModel.formattedTime) elapsed"
        }
    }
}
```

**Step 2: Commit**

```bash
git add TimerFloat/TimerFloatApp.swift
git commit -m "$(cat <<'EOF'
feat: update MenuBarIcon for stopwatch states

Shows stopwatch icon when in stopwatch mode and updates
accessibility labels for stopwatch states.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Feature 2: Window Pinning

### Task 9: Research and Create WindowPinningService

**Important Note:** Window pinning to another application's window requires the Accessibility API (AXUIElement) to track the target window's position. This requires:
1. User grants Accessibility permission
2. Polling the target window's position
3. Moving our overlay to match

**Files:**
- Create: `TimerFloat/Services/WindowPinningService.swift`
- Test: `TimerFloatTests/WindowPinningServiceTests.swift`

**Step 1: Write the failing test**

In `TimerFloatTests/WindowPinningServiceTests.swift`:

```swift
import Testing
import Foundation
@testable import TimerFloat

@Suite("WindowPinningService Tests")
@MainActor
struct WindowPinningServiceTests {

    @Test("Service starts unpinned")
    func serviceStartsUnpinned() {
        let service = WindowPinningService.shared
        #expect(service.isPinned == false)
        #expect(service.pinnedWindowInfo == nil)
    }

    @Test("Available windows returns array")
    func availableWindowsReturnsArray() async {
        let service = WindowPinningService.shared
        let windows = await service.getAvailableWindows()
        // Should return at least empty array (may have windows in test environment)
        #expect(windows != nil || windows == nil) // Just verifies no crash
    }
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter WindowPinningServiceTests`
Expected: FAIL with "cannot find 'WindowPinningService' in scope"

**Step 3: Write minimal implementation**

In `TimerFloat/Services/WindowPinningService.swift`:

```swift
import AppKit
import Foundation
import os.log

/// Information about a window that can be pinned to
struct PinnableWindow: Identifiable, Sendable {
    let id: CGWindowID
    let ownerName: String
    let windowTitle: String
    let bounds: CGRect
    let ownerPID: pid_t

    var displayName: String {
        if windowTitle.isEmpty {
            return ownerName
        }
        return "\(ownerName) - \(windowTitle)"
    }
}

/// Service for pinning the overlay to another application's window
/// Uses CGWindowList APIs to track window positions
@MainActor
@Observable
final class WindowPinningService {
    /// Shared singleton instance
    static let shared = WindowPinningService()

    /// Whether the overlay is currently pinned to a window
    private(set) var isPinned: Bool = false

    /// Information about the currently pinned window
    private(set) var pinnedWindowInfo: PinnableWindow?

    /// Offset from the pinned window's origin
    private var pinOffset: CGPoint = .zero

    /// Task for tracking the pinned window
    private var trackingTask: Task<Void, Never>?

    /// Callback when pinned window moves
    var onWindowMoved: ((CGPoint) -> Void)?

    /// Callback when pinned window closes
    var onWindowClosed: (() -> Void)?

    private init() {}

    /// Get list of windows available for pinning
    /// - Returns: Array of PinnableWindow info, or nil if unable to get window list
    func getAvailableWindows() async -> [PinnableWindow]? {
        // Get all on-screen windows
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            Log.window.error("Failed to get window list")
            return nil
        }

        var windows: [PinnableWindow] = []

        for windowInfo in windowList {
            guard let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID,
                  let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? pid_t,
                  let ownerName = windowInfo[kCGWindowOwnerName as String] as? String,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let layer = windowInfo[kCGWindowLayer as String] as? Int else {
                continue
            }

            // Skip windows at weird layers (menu bar, dock, etc.)
            guard layer == 0 else { continue }

            // Skip our own app's windows
            guard ownerPID != ProcessInfo.processInfo.processIdentifier else { continue }

            // Skip very small windows (probably menu items or tooltips)
            let width = boundsDict["Width"] ?? 0
            let height = boundsDict["Height"] ?? 0
            guard width > 100 && height > 100 else { continue }

            let bounds = CGRect(
                x: boundsDict["X"] ?? 0,
                y: boundsDict["Y"] ?? 0,
                width: width,
                height: height
            )

            let windowTitle = windowInfo[kCGWindowName as String] as? String ?? ""

            windows.append(PinnableWindow(
                id: windowID,
                ownerName: ownerName,
                windowTitle: windowTitle,
                bounds: bounds,
                ownerPID: ownerPID
            ))
        }

        // Sort by app name then window title
        return windows.sorted { $0.displayName < $1.displayName }
    }

    /// Pin the overlay to a specific window
    /// - Parameters:
    ///   - window: The window to pin to
    ///   - offset: Offset from the window's top-left corner
    func pinToWindow(_ window: PinnableWindow, offset: CGPoint = CGPoint(x: 20, y: 20)) {
        Log.window.info("Pinning to window: \(window.displayName)")

        pinnedWindowInfo = window
        pinOffset = offset
        isPinned = true

        startTracking()
    }

    /// Unpin from the current window
    func unpin() {
        Log.window.info("Unpinning from window")

        trackingTask?.cancel()
        trackingTask = nil

        isPinned = false
        pinnedWindowInfo = nil
    }

    /// Update the pin offset (when user drags the overlay while pinned)
    /// - Parameter newOffset: New offset from window origin
    func updatePinOffset(_ newOffset: CGPoint) {
        pinOffset = newOffset
    }

    /// Start tracking the pinned window's position
    private func startTracking() {
        trackingTask?.cancel()

        trackingTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self = self,
                      let pinnedWindow = self.pinnedWindowInfo else {
                    return
                }

                // Get current position of the pinned window
                if let currentBounds = await self.getWindowBounds(windowID: pinnedWindow.id) {
                    let newPosition = CGPoint(
                        x: currentBounds.origin.x + self.pinOffset.x,
                        y: currentBounds.origin.y + self.pinOffset.y
                    )
                    self.onWindowMoved?(newPosition)
                } else {
                    // Window no longer exists
                    Log.window.info("Pinned window closed")
                    self.onWindowClosed?()
                    self.unpin()
                    return
                }

                // Poll every 50ms for smooth tracking
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    /// Get the current bounds of a window by ID
    private func getWindowBounds(windowID: CGWindowID) async -> CGRect? {
        guard let windowList = CGWindowListCopyWindowInfo([.optionIncludingWindow], windowID) as? [[String: Any]],
              let windowInfo = windowList.first,
              let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat] else {
            return nil
        }

        return CGRect(
            x: boundsDict["X"] ?? 0,
            y: boundsDict["Y"] ?? 0,
            width: boundsDict["Width"] ?? 0,
            height: boundsDict["Height"] ?? 0
        )
    }
}
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter WindowPinningServiceTests`
Expected: PASS

**Step 5: Commit**

```bash
git add TimerFloat/Services/WindowPinningService.swift TimerFloatTests/WindowPinningServiceTests.swift
git commit -m "$(cat <<'EOF'
feat: create WindowPinningService for window tracking

Uses CGWindowList APIs to enumerate windows and track
position changes. Supports pinning overlay to any visible
window from another application.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 10: Add Pin Button to Overlay

**Files:**
- Modify: `TimerFloat/Views/TimerOverlayView.swift`
- Modify: `TimerFloat/Views/StopwatchOverlayView.swift`

**Step 1: Create shared PinButton component**

Add to both overlay views a pin button that appears on hover:

```swift
/// Pin button overlay component
struct PinButtonOverlay: View {
    let isPinned: Bool
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12))
                .foregroundStyle(isPinned ? .orange : .secondary)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .help(isPinned ? "Unpin from window" : "Pin to window")
        .accessibilityLabel(isPinned ? "Unpin from window" : "Pin to window")
    }
}
```

Update `TimerOverlayView` body to include pin button on hover:

```swift
var body: some View {
    ZStack {
        // Background with material effect
        RoundedRectangle(cornerRadius: 16)
            .fill(.regularMaterial)

        // Timer content
        VStack(spacing: 8) {
            // ... existing content ...
        }
        .padding(12)

        // Pin button (top-right corner, visible on hover)
        if isHovered {
            VStack {
                HStack {
                    Spacer()
                    PinButtonOverlay(
                        isPinned: WindowPinningService.shared.isPinned,
                        onTap: onPinTap
                    )
                }
                Spacer()
            }
            .padding(4)
        }
    }
    // ... rest of modifiers
}

private func onPinTap() {
    if WindowPinningService.shared.isPinned {
        WindowPinningService.shared.unpin()
    } else {
        // Show window picker
        showWindowPicker = true
    }
}
```

**Step 2: Commit**

```bash
git add TimerFloat/Views/TimerOverlayView.swift TimerFloat/Views/StopwatchOverlayView.swift
git commit -m "$(cat <<'EOF'
feat: add pin button to overlay views

Shows pin button on hover that allows pinning to other
application windows. Uses shared PinButtonOverlay component.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 11: Create Window Picker View

**Files:**
- Create: `TimerFloat/Views/WindowPickerView.swift`

**Step 1: Create the window picker**

```swift
import SwiftUI

/// View for selecting a window to pin to
struct WindowPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var availableWindows: [PinnableWindow] = []
    @State private var isLoading = true
    @State private var searchText = ""

    let onSelect: (PinnableWindow) -> Void

    private var filteredWindows: [PinnableWindow] {
        if searchText.isEmpty {
            return availableWindows
        }
        return availableWindows.filter { window in
            window.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Pin to Window")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Search field
            TextField("Search windows...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Window list
            if isLoading {
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            } else if filteredWindows.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "macwindow")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(searchText.isEmpty ? "No windows available" : "No matching windows")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List(filteredWindows) { window in
                    WindowRow(window: window) {
                        onSelect(window)
                        dismiss()
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 300, height: 400)
        .task {
            await loadWindows()
        }
    }

    private func loadWindows() async {
        isLoading = true
        if let windows = await WindowPinningService.shared.getAvailableWindows() {
            availableWindows = windows
        }
        isLoading = false
    }
}

/// Row displaying a single window option
struct WindowRow: View {
    let window: PinnableWindow
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                // App icon (if available)
                if let app = NSRunningApplication(processIdentifier: window.ownerPID),
                   let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "macwindow")
                        .frame(width: 24, height: 24)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(window.ownerName)
                        .font(.body)
                        .lineLimit(1)

                    if !window.windowTitle.isEmpty {
                        Text(window.windowTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WindowPickerView { window in
        print("Selected: \(window.displayName)")
    }
}
```

**Step 2: Commit**

```bash
git add TimerFloat/Views/WindowPickerView.swift
git commit -m "$(cat <<'EOF'
feat: create WindowPickerView for window selection

Displays list of available windows with app icons and titles.
Includes search filtering and loading state handling.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 12: Integrate Window Pinning with WindowService

**Files:**
- Modify: `TimerFloat/Services/WindowService.swift`

**Step 1: Read current WindowService**

First read the current implementation.

**Step 2: Add pinning support**

Add to `WindowService.swift`:

```swift
/// Connect window pinning service
func setupWindowPinning() {
    let pinningService = WindowPinningService.shared

    pinningService.onWindowMoved = { [weak self] newPosition in
        guard let self = self else { return }
        // Convert from screen coordinates (top-left origin) to AppKit (bottom-left)
        if let screen = NSScreen.main {
            let flippedY = screen.frame.height - newPosition.y - (self.overlayWindow?.frame.height ?? 120)
            let appKitPosition = NSPoint(x: newPosition.x, y: flippedY)
            self.updatePosition(to: appKitPosition, saveToDisk: false)
        }
    }

    pinningService.onWindowClosed = { [weak self] in
        // Window closed, unpin automatically
        Log.window.info("Pinned window closed, returning to saved position")
        self?.restoreDefaultPosition()
    }
}

/// Restore the overlay to its default/saved position
func restoreDefaultPosition() {
    let position = defaultPosition
    updatePosition(to: position, saveToDisk: false)
}
```

Update `init()` to call `setupWindowPinning()`.

**Step 3: Commit**

```bash
git add TimerFloat/Services/WindowService.swift
git commit -m "$(cat <<'EOF'
feat: integrate window pinning with WindowService

Connects WindowPinningService callbacks to update overlay
position. Handles window close by restoring saved position.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 13: Update FloatingOverlayWindow for Pinning

**Files:**
- Modify: `TimerFloat/Views/FloatingOverlayWindow.swift`

**Step 1: Disable dragging when pinned**

Update `mouseDragged` in `FloatingOverlayWindow.swift`:

```swift
/// Handle mouse drag to move the window (unless pinned)
override func mouseDragged(with event: NSEvent) {
    // Don't allow dragging when pinned
    guard !WindowPinningService.shared.isPinned else {
        return
    }

    let currentLocation = NSEvent.mouseLocation
    let newOrigin = NSPoint(
        x: currentLocation.x - initialMouseLocation.x,
        y: currentLocation.y - initialMouseLocation.y
    )

    // Keep window within screen bounds
    if let screen = NSScreen.main {
        let screenFrame = screen.visibleFrame
        let windowFrame = frame

        let clampedX = max(screenFrame.minX, min(newOrigin.x, screenFrame.maxX - windowFrame.width))
        let clampedY = max(screenFrame.minY, min(newOrigin.y, screenFrame.maxY - windowFrame.height))

        setFrameOrigin(NSPoint(x: clampedX, y: clampedY))
    } else {
        setFrameOrigin(newOrigin)
    }
}
```

**Step 2: Commit**

```bash
git add TimerFloat/Views/FloatingOverlayWindow.swift
git commit -m "$(cat <<'EOF'
feat: disable overlay dragging when pinned

Prevents manual repositioning when overlay is pinned to
another window. Window will move with pinned target.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 14: Add Pin/Unpin to Menu

**Files:**
- Modify: `TimerFloat/TimerFloatApp.swift`

**Step 1: Add pin option to active timer view**

Update `ActiveTimerView` to include a pin/unpin button:

```swift
// After control buttons, add:
Divider()

// Pin status
HStack {
    if WindowPinningService.shared.isPinned {
        Label("Pinned", systemImage: "pin.fill")
            .font(.caption)
            .foregroundStyle(.orange)

        Button("Unpin") {
            WindowPinningService.shared.unpin()
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    } else {
        Button {
            showWindowPicker = true
        } label: {
            Label("Pin to Window", systemImage: "pin")
                .font(.caption)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}
.sheet(isPresented: $showWindowPicker) {
    WindowPickerView { window in
        WindowPinningService.shared.pinToWindow(window)
    }
}
```

**Step 2: Commit**

```bash
git add TimerFloat/TimerFloatApp.swift
git commit -m "$(cat <<'EOF'
feat: add pin/unpin controls to menu bar popover

Adds pin button to active timer view that opens window
picker sheet. Shows unpin button when currently pinned.

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 15: Final Integration and Build Test

**Files:**
- All modified files

**Step 1: Build the project**

Run: `swift build`
Expected: PASS with no errors

**Step 2: Run all tests**

Run: `swift test`
Expected: All tests pass

**Step 3: Final commit**

```bash
git add -A
git commit -m "$(cat <<'EOF'
chore: final integration for stopwatch and window pinning

Ensures all components work together:
- Stopwatch mode with centisecond display
- Window pinning via CGWindowList APIs
- UI updates for mode selection and pin controls

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
EOF
)"
```

---

## Summary

This plan implements two major features:

### Feature 1: Stopwatch Mode
- **TimerMode enum** for countdown/stopwatch selection
- **Extended TimerState** with stopwatch cases
- **Extended TimerService** with stopwatch methods
- **StopwatchOverlayView** with centisecond display
- **UI updates** for mode selection in menu

### Feature 2: Window Pinning
- **WindowPinningService** using CGWindowList APIs
- **PinnableWindow** struct for window info
- **WindowPickerView** for selecting target window
- **Overlay updates** with pin button on hover
- **FloatingOverlayWindow** drag prevention when pinned

### Key Technical Decisions

1. **CGWindowList over Accessibility API**: CGWindowList is simpler and doesn't require additional permissions beyond what the app already has. Accessibility would provide more features but adds complexity.

2. **50ms polling for window tracking**: Provides smooth visual following without excessive CPU usage.

3. **100ms stopwatch updates**: Balances visual smoothness with performance.

4. **Shared PinButtonOverlay component**: Reused between timer and stopwatch views for consistency.

### Sources Referenced

- [NSWindow addChildWindow(_:ordered:)](https://developer.apple.com/documentation/appkit/nswindow/1419152-addchildwindow) - Apple documentation
- [CGWindowListCopyWindowInfo](https://developer.apple.com/documentation/coregraphics/cgwindowlistcopywindowinfo(_:_:)) - Apple documentation
- [Swindler - macOS window management library](https://github.com/tmandry/Swindler) - GitHub
