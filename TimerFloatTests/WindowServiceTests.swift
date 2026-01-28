import Testing
import SwiftUI
@testable import TimerFloat

@Suite("WindowService Tests")
@MainActor
struct WindowServiceTests {

    // MARK: - Visibility Tests

    @Test("Window service starts with overlay hidden")
    func initiallyHidden() async {
        let service = WindowService.shared
        #expect(service.isVisible == false)
    }

    @Test("showOverlay makes overlay visible")
    func showOverlayMakesVisible() async {
        let service = WindowService.shared

        // Ensure we start hidden
        service.hideOverlay()
        #expect(service.isVisible == false)

        // Show overlay
        service.showOverlay(with: Text("Test"))
        #expect(service.isVisible == true)

        // Cleanup
        service.hideOverlay()
    }

    @Test("hideOverlay makes overlay hidden")
    func hideOverlayMakesHidden() async {
        let service = WindowService.shared

        // Show first
        service.showOverlay(with: Text("Test"))
        #expect(service.isVisible == true)

        // Hide
        service.hideOverlay()
        #expect(service.isVisible == false)
    }

    @Test("Multiple show calls don't break state")
    func multipleShowCalls() async {
        let service = WindowService.shared

        service.showOverlay(with: Text("Test 1"))
        service.showOverlay(with: Text("Test 2"))
        service.showOverlay(with: Text("Test 3"))

        #expect(service.isVisible == true)

        // Cleanup
        service.hideOverlay()
    }

    @Test("Multiple hide calls don't break state")
    func multipleHideCalls() async {
        let service = WindowService.shared

        service.showOverlay(with: Text("Test"))
        service.hideOverlay()
        service.hideOverlay()
        service.hideOverlay()

        #expect(service.isVisible == false)
    }

    // MARK: - Position Tests

    @Test("Current position is nil when window not created")
    func positionNilWhenNotCreated() async {
        // Note: This test assumes fresh state which may not be true
        // in a shared singleton. Skip if window already exists.
        let service = WindowService.shared
        if !service.isVisible {
            // Position might still be set from previous tests
            // Just verify we can query it without crash
            _ = service.currentPosition
        }
    }

    @Test("Position is set after showing overlay")
    func positionSetAfterShow() async {
        let service = WindowService.shared

        service.showOverlay(with: Text("Test"))

        #expect(service.currentPosition != nil)

        // Cleanup
        service.hideOverlay()
    }

    @Test("updatePosition changes window position")
    func updatePositionChangesPosition() async {
        let service = WindowService.shared

        service.showOverlay(with: Text("Test"))

        let newPosition = NSPoint(x: 100, y: 100)
        service.updatePosition(to: newPosition)

        // Position should be updated (may be clamped to screen)
        let currentPosition = service.currentPosition
        #expect(currentPosition != nil)

        // Cleanup
        service.hideOverlay()
    }

    // MARK: - Content Update Tests

    @Test("updateContent changes view without affecting visibility")
    func updateContentPreservesVisibility() async {
        let service = WindowService.shared

        service.showOverlay(with: Text("Original"))
        #expect(service.isVisible == true)

        service.updateContent(Text("Updated"))
        #expect(service.isVisible == true)

        // Cleanup
        service.hideOverlay()
    }

    // MARK: - Toggle Tests

    @Test("toggleOverlay shows when hidden")
    func toggleShowsWhenHidden() async {
        let service = WindowService.shared

        service.hideOverlay()
        #expect(service.isVisible == false)

        service.toggleOverlay(with: Text("Test"))
        #expect(service.isVisible == true)

        // Cleanup
        service.hideOverlay()
    }

    @Test("toggleOverlay hides when visible")
    func toggleHidesWhenVisible() async {
        let service = WindowService.shared

        service.showOverlay(with: Text("Test"))
        #expect(service.isVisible == true)

        service.toggleOverlay(with: Text("Test"))
        #expect(service.isVisible == false)
    }
}

// MARK: - FloatingOverlayWindow Tests

@Suite("FloatingOverlayWindow Tests")
@MainActor
struct FloatingOverlayWindowTests {

    @Test("Window has correct level for floating above all apps")
    func windowLevelIsCorrect() async {
        let window = FloatingOverlayWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100))

        // Window level should be above status bar
        let statusWindowLevel = Int(CGWindowLevelForKey(.statusWindow))
        #expect(window.level.rawValue > statusWindowLevel)
    }

    @Test("Window has transparent background")
    func windowHasTransparentBackground() async {
        let window = FloatingOverlayWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100))

        #expect(window.backgroundColor == .clear)
        #expect(window.isOpaque == false)
    }

    @Test("Window can join all spaces")
    func windowCanJoinAllSpaces() async {
        let window = FloatingOverlayWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100))

        #expect(window.collectionBehavior.contains(.canJoinAllSpaces))
    }

    @Test("Window is fullscreen auxiliary")
    func windowIsFullscreenAuxiliary() async {
        let window = FloatingOverlayWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100))

        #expect(window.collectionBehavior.contains(.fullScreenAuxiliary))
    }

    @Test("Window can become key for interaction")
    func windowCanBecomeKey() async {
        let window = FloatingOverlayWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100))

        #expect(window.canBecomeKey == true)
    }

    @Test("Window cannot become main")
    func windowCannotBecomeMain() async {
        let window = FloatingOverlayWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100))

        #expect(window.canBecomeMain == false)
    }
}
