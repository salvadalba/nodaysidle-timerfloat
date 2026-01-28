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
