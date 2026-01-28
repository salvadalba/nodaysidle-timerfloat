import AppKit

/// Custom NSWindow subclass for the floating timer overlay
/// Configured to float above all apps including fullscreen applications
final class FloatingOverlayWindow: NSWindow {

    /// Initialize the floating overlay window
    /// - Parameter contentRect: Initial frame for the window
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        configureWindow()
    }

    /// Configure window properties for floating overlay behavior
    private func configureWindow() {
        // Set window level above all other windows including fullscreen apps
        // .statusBar + 1 ensures visibility over fullscreen applications
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.statusWindow)) + 1)

        // Transparent background - content will provide visual appearance
        backgroundColor = .clear

        // Window should not become key or main to avoid stealing focus
        // But we need to allow it to receive mouse events for dragging
        collectionBehavior = [
            .canJoinAllSpaces,      // Visible on all spaces/desktops
            .fullScreenAuxiliary,   // Can appear alongside fullscreen apps
            .stationary             // Doesn't move with space switches
        ]

        // Allow transparency in the window
        isOpaque = false
        hasShadow = true

        // Prevent the window from appearing in screenshots by default
        // (can be changed if user wants to include it)
        sharingType = .none

        // Don't show in window menu or expose
        isExcludedFromWindowsMenu = true

        // Enable mouse moved events for hover effects
        acceptsMouseMovedEvents = true

        Log.window.info("Floating overlay window configured at level \(self.level.rawValue)")
    }

    // MARK: - Mouse Event Handling

    /// Allow the window to become key when clicked for interaction
    override var canBecomeKey: Bool {
        return true
    }

    /// Prevent the window from becoming main
    override var canBecomeMain: Bool {
        return false
    }

    // MARK: - Dragging Support

    /// Track the initial mouse location for dragging
    private var initialMouseLocation: NSPoint = .zero

    /// Handle mouse down for drag initiation
    override func mouseDown(with event: NSEvent) {
        initialMouseLocation = event.locationInWindow
        super.mouseDown(with: event)
    }

    /// Handle mouse drag to move the window
    override func mouseDragged(with event: NSEvent) {
        // Don't allow dragging when pinned to another window
        let isPinned = MainActor.assumeIsolated { WindowPinningService.shared.isPinned }
        guard !isPinned else {
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

    /// Handle mouse up to complete drag
    override func mouseUp(with event: NSEvent) {
        // Don't save position when pinned (position is controlled by pinning service)
        let isPinned = MainActor.assumeIsolated { WindowPinningService.shared.isPinned }
        guard !isPinned else {
            super.mouseUp(with: event)
            return
        }

        super.mouseUp(with: event)
        // Post notification for position persistence
        NotificationCenter.default.post(
            name: .overlayWindowDidMove,
            object: self,
            userInfo: ["position": frame.origin]
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the overlay window is moved to a new position
    static let overlayWindowDidMove = Notification.Name("overlayWindowDidMove")
}
