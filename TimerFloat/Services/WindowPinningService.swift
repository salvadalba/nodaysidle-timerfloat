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

        trackingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self = self,
                      let pinnedWindow = self.pinnedWindowInfo else {
                    return
                }

                // Get current position of the pinned window
                if let currentBounds = self.getWindowBounds(windowID: pinnedWindow.id) {
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
    private func getWindowBounds(windowID: CGWindowID) -> CGRect? {
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
