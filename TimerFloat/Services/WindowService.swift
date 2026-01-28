import AppKit
import SwiftUI

/// Service responsible for managing the floating overlay window lifecycle
@MainActor
final class WindowService {
    /// Shared instance for app-wide overlay management
    static let shared = WindowService()

    /// The floating overlay window (created lazily)
    private var overlayWindow: FloatingOverlayWindow?

    /// The hosting view for SwiftUI content
    private var hostingView: NSHostingView<AnyView>?

    /// Current visibility state
    private(set) var isVisible: Bool = false

    /// Default window size for the overlay
    private let defaultSize = NSSize(width: 120, height: 120)

    /// Reference to preferences service
    private let preferencesService = PreferencesService.shared

    /// Observer for window move notifications
    nonisolated(unsafe) private var moveObserver: NSObjectProtocol?

    /// Observer for screen configuration changes
    nonisolated(unsafe) private var screenChangeObserver: NSObjectProtocol?

    /// Default position (top-right corner with padding)
    private var defaultPosition: NSPoint {
        // Check for saved position first
        if let savedPosition = preferencesService.preferences?.overlayPosition {
            return NSPoint(x: savedPosition.x, y: savedPosition.y)
        }

        guard let screen = NSScreen.main else {
            return NSPoint(x: 100, y: 100)
        }
        let screenFrame = screen.visibleFrame
        return NSPoint(
            x: screenFrame.maxX - defaultSize.width - 20,
            y: screenFrame.maxY - defaultSize.height - 20
        )
    }

    private init() {
        setupMoveObserver()
        setupScreenChangeObserver()
        setupWindowPinning()
        Log.window.info("WindowService initialized")
    }

    deinit {
        if let observer = moveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = screenChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    /// Set up observer for window move notifications
    private func setupMoveObserver() {
        moveObserver = NotificationCenter.default.addObserver(
            forName: .overlayWindowDidMove,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let position = notification.userInfo?["position"] as? NSPoint else { return }
            Task { @MainActor in
                self?.savePosition(position)
            }
        }
    }

    /// Save the window position to preferences
    private func savePosition(_ position: NSPoint) {
        do {
            try preferencesService.updateOverlayPosition(CGPoint(x: position.x, y: position.y))
            MetricsService.shared.recordOverlayDrag()
            Log.window.debug("Saved overlay position: (\(position.x), \(position.y))")
        } catch {
            Log.window.error("Failed to save overlay position: \(error.localizedDescription)")
        }
    }

    /// Set up observer for screen configuration changes
    private func setupScreenChangeObserver() {
        screenChangeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.handleScreenConfigurationChange()
            }
        }
    }

    /// Connect window pinning service to update overlay position when pinned window moves
    private func setupWindowPinning() {
        let pinningService = WindowPinningService.shared

        pinningService.onWindowMoved = { [weak self] newPosition in
            guard let self = self else { return }
            // Convert from screen coordinates (top-left origin) to AppKit (bottom-left)
            if let screen = NSScreen.main {
                let windowHeight = self.overlayWindow?.frame.height ?? self.defaultSize.height
                let flippedY = screen.frame.height - newPosition.y - windowHeight
                let appKitPosition = NSPoint(x: newPosition.x, y: flippedY)
                self.updatePosition(to: appKitPosition, saveToDisk: false)
            }
        }

        pinningService.onWindowClosed = { [weak self] in
            // Window closed, unpin automatically and restore saved position
            Log.window.info("Pinned window closed, returning to saved position")
            self?.restoreDefaultPosition()
        }
    }

    /// Handle screen configuration changes (display connect/disconnect, resolution change)
    private func handleScreenConfigurationChange() {
        Log.window.info("Screen configuration changed")

        guard let window = overlayWindow, isVisible else {
            Log.window.debug("No visible overlay to reposition")
            return
        }

        let currentPosition = window.frame.origin
        let windowSize = window.frame.size

        // Check if current position is still valid
        if !isPositionValid(currentPosition, windowSize: windowSize) {
            Log.window.info("Overlay position invalid after screen change, repositioning")

            // Try to find the best screen for the overlay
            let newPosition = findValidPosition(for: windowSize, preferredPosition: currentPosition)
            window.setFrameOrigin(newPosition)

            // Save the new position
            savePosition(newPosition)

            Log.window.info("Overlay repositioned to (\(newPosition.x), \(newPosition.y))")
        }
    }

    /// Check if a position is valid on any connected screen
    private func isPositionValid(_ position: NSPoint, windowSize: NSSize) -> Bool {
        for screen in NSScreen.screens {
            let screenFrame = screen.visibleFrame
            let windowRect = NSRect(origin: position, size: windowSize)

            // Check if at least half the window is visible on this screen
            let intersection = screenFrame.intersection(windowRect)
            if !intersection.isNull {
                let visibleArea = intersection.width * intersection.height
                let totalArea = windowSize.width * windowSize.height
                if visibleArea >= totalArea * 0.5 {
                    return true
                }
            }
        }
        return false
    }

    /// Find a valid position for the overlay, preferring to stay close to the original position
    private func findValidPosition(for windowSize: NSSize, preferredPosition: NSPoint) -> NSPoint {
        // First, try to find the screen closest to the preferred position
        var bestScreen: NSScreen?
        var minDistance = Double.infinity

        for screen in NSScreen.screens {
            let screenCenter = NSPoint(
                x: screen.visibleFrame.midX,
                y: screen.visibleFrame.midY
            )
            let distance = hypot(screenCenter.x - preferredPosition.x, screenCenter.y - preferredPosition.y)
            if distance < minDistance {
                minDistance = distance
                bestScreen = screen
            }
        }

        // Use the best screen, or fall back to main screen
        let screen = bestScreen ?? NSScreen.main ?? NSScreen.screens.first

        guard let targetScreen = screen else {
            // No screens available - return a safe default
            return NSPoint(x: 100, y: 100)
        }

        let screenFrame = targetScreen.visibleFrame

        // Try to keep the overlay close to its original position, but clamped to screen bounds
        let clampedX = max(screenFrame.minX, min(preferredPosition.x, screenFrame.maxX - windowSize.width))
        let clampedY = max(screenFrame.minY, min(preferredPosition.y, screenFrame.maxY - windowSize.height))

        return NSPoint(x: clampedX, y: clampedY)
    }

    // MARK: - Public API

    /// Show the overlay window with the given SwiftUI content
    /// - Parameter content: The SwiftUI view to display in the overlay
    func showOverlay<Content: View>(with content: Content) {
        if overlayWindow == nil {
            createWindow()
        }

        guard let window = overlayWindow else {
            Log.window.error("Failed to create overlay window")
            return
        }

        // Update content
        let hostingView = NSHostingView(rootView: AnyView(content))
        hostingView.frame = NSRect(origin: .zero, size: defaultSize)
        window.contentView = hostingView
        self.hostingView = hostingView

        // Show window
        window.orderFrontRegardless()
        isVisible = true

        Log.window.info("Overlay shown at position: (\(window.frame.origin.x), \(window.frame.origin.y))")
    }

    /// Hide the overlay window without destroying it
    func hideOverlay() {
        guard let window = overlayWindow, isVisible else { return }

        window.orderOut(nil)
        isVisible = false

        Log.window.info("Overlay hidden")
    }

    /// Update the overlay position
    /// - Parameters:
    ///   - position: New position for the window origin
    ///   - saveToDisk: Whether to persist the position to preferences (default: true)
    func updatePosition(to position: NSPoint, saveToDisk: Bool = true) {
        guard let window = overlayWindow else { return }

        // Clamp to screen bounds
        let clampedPosition = clampToScreenBounds(position)
        window.setFrameOrigin(clampedPosition)

        if saveToDisk {
            savePosition(clampedPosition)
        }

        Log.window.debug("Overlay position updated to: (\(clampedPosition.x), \(clampedPosition.y))")
    }

    /// Restore the overlay to its default/saved position
    func restoreDefaultPosition() {
        let position = defaultPosition
        updatePosition(to: position, saveToDisk: false)
        Log.window.info("Overlay restored to default position: (\(position.x), \(position.y))")
    }

    /// Get the current overlay position
    var currentPosition: NSPoint? {
        overlayWindow?.frame.origin
    }

    /// Update the overlay content
    /// - Parameter content: New SwiftUI view to display
    func updateContent<Content: View>(_ content: Content) {
        guard let window = overlayWindow else { return }

        let hostingView = NSHostingView(rootView: AnyView(content))
        hostingView.frame = window.contentView?.bounds ?? NSRect(origin: .zero, size: defaultSize)
        window.contentView = hostingView
        self.hostingView = hostingView
    }

    /// Toggle overlay visibility
    func toggleOverlay<Content: View>(with content: Content) {
        if isVisible {
            hideOverlay()
        } else {
            showOverlay(with: content)
        }
    }

    // MARK: - Private Methods

    /// Create the overlay window lazily
    private func createWindow() {
        let position = defaultPosition
        let frame = NSRect(origin: position, size: defaultSize)

        overlayWindow = FloatingOverlayWindow(contentRect: frame)

        Log.window.info("Created overlay window at (\(position.x), \(position.y))")
    }

    /// Clamp a position to stay within screen bounds
    private func clampToScreenBounds(_ position: NSPoint) -> NSPoint {
        guard let screen = NSScreen.main else { return position }

        let screenFrame = screen.visibleFrame
        let windowSize = overlayWindow?.frame.size ?? defaultSize

        let clampedX = max(screenFrame.minX, min(position.x, screenFrame.maxX - windowSize.width))
        let clampedY = max(screenFrame.minY, min(position.y, screenFrame.maxY - windowSize.height))

        return NSPoint(x: clampedX, y: clampedY)
    }
}
