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
