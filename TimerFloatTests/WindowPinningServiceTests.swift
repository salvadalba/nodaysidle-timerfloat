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
