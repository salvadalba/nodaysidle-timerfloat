import Testing
import Foundation
@testable import TimerFloat

@Suite("TimerService Tests")
struct TimerServiceTests {

    // MARK: - Start Timer Tests

    @Test("Starting timer sets running state with correct duration")
    func startTimerSetsRunningState() async throws {
        let service = TimerService()
        try await service.startTimer(duration: 60)

        let state = await service.state
        guard case .running(let remaining, let total) = state else {
            Issue.record("Expected running state")
            return
        }

        #expect(total == 60)
        #expect(remaining <= 60)
        #expect(remaining > 59) // Should be very close to 60
    }

    @Test("Starting timer with zero duration throws invalidDuration")
    func startTimerWithZeroDurationThrows() async {
        let service = TimerService()

        await #expect(throws: TimerError.invalidDuration) {
            try await service.startTimer(duration: 0)
        }
    }

    @Test("Starting timer with negative duration throws invalidDuration")
    func startTimerWithNegativeDurationThrows() async {
        let service = TimerService()

        await #expect(throws: TimerError.invalidDuration) {
            try await service.startTimer(duration: -10)
        }
    }

    @Test("Starting timer when already running throws timerAlreadyRunning")
    func startTimerWhenRunningThrows() async throws {
        let service = TimerService()
        try await service.startTimer(duration: 60)

        await #expect(throws: TimerError.timerAlreadyRunning) {
            try await service.startTimer(duration: 30)
        }
    }

    // MARK: - Pause Timer Tests

    @Test("Pausing timer preserves remaining time")
    func pauseTimerPreservesRemainingTime() async throws {
        let service = TimerService()
        try await service.startTimer(duration: 60)

        // Wait to allow some time to elapse
        try await Task.sleep(for: .milliseconds(500))

        try await service.pauseTimer()

        let state = await service.state
        guard case .paused(let remaining, let total) = state else {
            Issue.record("Expected paused state")
            return
        }

        #expect(total == 60)
        // Remaining should be between 59 and 60 seconds (allowing for timing variance)
        #expect(remaining <= 60)
        #expect(remaining >= 59)
    }

    @Test("Pausing when not running throws timerNotRunning")
    func pauseWhenNotRunningThrows() async {
        let service = TimerService()

        await #expect(throws: TimerError.timerNotRunning) {
            try await service.pauseTimer()
        }
    }

    @Test("Pausing when paused throws timerNotRunning")
    func pauseWhenPausedThrows() async throws {
        let service = TimerService()
        try await service.startTimer(duration: 60)
        try await service.pauseTimer()

        await #expect(throws: TimerError.timerNotRunning) {
            try await service.pauseTimer()
        }
    }

    // MARK: - Resume Timer Tests

    @Test("Resuming timer continues from paused time")
    func resumeTimerContinuesFromPausedTime() async throws {
        let service = TimerService()
        try await service.startTimer(duration: 60)
        try await service.pauseTimer()

        let pausedState = await service.state
        guard case .paused(let pausedRemaining, _) = pausedState else {
            Issue.record("Expected paused state")
            return
        }

        try await service.resumeTimer()

        let state = await service.state
        guard case .running(let remaining, let total) = state else {
            Issue.record("Expected running state")
            return
        }

        #expect(total == 60)
        // Remaining should be close to what it was when paused
        #expect(abs(remaining - pausedRemaining) < 0.5)
    }

    @Test("Resuming when not paused throws timerNotPaused")
    func resumeWhenNotPausedThrows() async {
        let service = TimerService()

        await #expect(throws: TimerError.timerNotPaused) {
            try await service.resumeTimer()
        }
    }

    @Test("Resuming when running throws timerNotPaused")
    func resumeWhenRunningThrows() async throws {
        let service = TimerService()
        try await service.startTimer(duration: 60)

        await #expect(throws: TimerError.timerNotPaused) {
            try await service.resumeTimer()
        }
    }

    // MARK: - Cancel Timer Tests

    @Test("Cancelling timer resets to idle")
    func cancelTimerResetsToIdle() async throws {
        let service = TimerService()
        try await service.startTimer(duration: 60)
        try await service.cancelTimer()

        let state = await service.state
        #expect(state == .idle)
    }

    @Test("Cancelling paused timer resets to idle")
    func cancelPausedTimerResetsToIdle() async throws {
        let service = TimerService()
        try await service.startTimer(duration: 60)
        try await service.pauseTimer()
        try await service.cancelTimer()

        let state = await service.state
        #expect(state == .idle)
    }

    @Test("Cancelling when no timer active throws noActiveTimer")
    func cancelWhenNoTimerThrows() async {
        let service = TimerService()

        await #expect(throws: TimerError.noActiveTimer) {
            try await service.cancelTimer()
        }
    }

    // MARK: - Completion Tests

    @Test("Timer completes after duration elapses")
    func timerCompletesAfterDuration() async throws {
        let service = TimerService()
        try await service.startTimer(duration: 0.5) // 500ms timer

        // Wait for completion
        try await Task.sleep(for: .seconds(1))

        let state = await service.state
        #expect(state == .completed)
    }

    // MARK: - Reset Tests

    @Test("Reset returns to idle from any state")
    func resetReturnsToIdle() async throws {
        let service = TimerService()
        try await service.startTimer(duration: 60)

        await service.reset()

        let state = await service.state
        #expect(state == .idle)
    }

    // MARK: - State Stream Tests

    @Test("State stream emits initial idle state")
    func stateStreamEmitsInitialState() async throws {
        let service = TimerService()
        let stream = await service.stateStream

        // Get the first state from the stream
        var iterator = stream.makeAsyncIterator()
        let firstState = await iterator.next()

        #expect(firstState == .idle)
    }
}

// MARK: - TimerState Tests

@Suite("TimerState Tests")
struct TimerStateTests {

    @Test("Idle state has nil remaining time")
    func idleHasNilRemainingTime() {
        let state = TimerState.idle
        #expect(state.remainingTime == nil)
        #expect(state.totalTime == nil)
    }

    @Test("Running state returns correct remaining time")
    func runningReturnsCorrectRemainingTime() {
        let state = TimerState.running(remaining: 30, total: 60)
        #expect(state.remainingTime == 30)
        #expect(state.totalTime == 60)
    }

    @Test("Paused state returns correct remaining time")
    func pausedReturnsCorrectRemainingTime() {
        let state = TimerState.paused(remaining: 45, total: 60)
        #expect(state.remainingTime == 45)
        #expect(state.totalTime == 60)
    }

    @Test("Completed state has nil remaining time")
    func completedHasNilRemainingTime() {
        let state = TimerState.completed
        #expect(state.remainingTime == nil)
        #expect(state.totalTime == nil)
    }

    @Test("Progress is 0 for idle")
    func progressIsZeroForIdle() {
        let state = TimerState.idle
        #expect(state.progress == 0.0)
    }

    @Test("Progress is 1 for completed")
    func progressIsOneForCompleted() {
        let state = TimerState.completed
        #expect(state.progress == 1.0)
    }

    @Test("Progress is calculated correctly for running")
    func progressIsCalculatedForRunning() {
        let state = TimerState.running(remaining: 30, total: 60)
        #expect(state.progress == 0.5)
    }

    @Test("Progress is calculated correctly for paused")
    func progressIsCalculatedForPaused() {
        let state = TimerState.paused(remaining: 15, total: 60)
        #expect(state.progress == 0.75)
    }

    @Test("isRunning returns true only for running state")
    func isRunningOnlyForRunningState() {
        #expect(TimerState.idle.isRunning == false)
        #expect(TimerState.running(remaining: 30, total: 60).isRunning == true)
        #expect(TimerState.paused(remaining: 30, total: 60).isRunning == false)
        #expect(TimerState.completed.isRunning == false)
    }

    @Test("isPaused returns true only for paused state")
    func isPausedOnlyForPausedState() {
        #expect(TimerState.idle.isPaused == false)
        #expect(TimerState.running(remaining: 30, total: 60).isPaused == false)
        #expect(TimerState.paused(remaining: 30, total: 60).isPaused == true)
        #expect(TimerState.completed.isPaused == false)
    }

    @Test("isActive returns true for running and paused")
    func isActiveForRunningAndPaused() {
        #expect(TimerState.idle.isActive == false)
        #expect(TimerState.running(remaining: 30, total: 60).isActive == true)
        #expect(TimerState.paused(remaining: 30, total: 60).isActive == true)
        #expect(TimerState.completed.isActive == false)
    }

    @Test("TimerState is equatable")
    func timerStateIsEquatable() {
        #expect(TimerState.idle == TimerState.idle)
        #expect(TimerState.completed == TimerState.completed)
        #expect(TimerState.running(remaining: 30, total: 60) == TimerState.running(remaining: 30, total: 60))
        #expect(TimerState.running(remaining: 30, total: 60) != TimerState.running(remaining: 31, total: 60))
    }
}
