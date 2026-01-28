import Foundation
import SwiftData

/// User preferences model persisted with SwiftData
@Model
final class UserPreferences {
    /// Overlay window X position
    var overlayPositionX: Double

    /// Overlay window Y position
    var overlayPositionY: Double

    /// Whether notifications are enabled on timer completion
    var notificationsEnabled: Bool

    /// Whether sound is played on timer completion
    var soundEnabled: Bool

    /// Whether app launches at login
    var launchAtLogin: Bool

    /// Default timer duration in minutes
    var defaultDurationMinutes: Int

    /// Overlay opacity when not hovered (0.0 to 1.0)
    var overlayIdleOpacity: Double

    /// Whether completion animations are enabled
    var animationsEnabled: Bool

    /// Date when preferences were last modified
    var lastModified: Date

    /// Initialize with default values
    init(
        overlayPositionX: Double = -1,  // -1 indicates use default
        overlayPositionY: Double = -1,
        notificationsEnabled: Bool = true,
        soundEnabled: Bool = true,
        launchAtLogin: Bool = false,
        defaultDurationMinutes: Int = 25,
        overlayIdleOpacity: Double = 0.8,
        animationsEnabled: Bool = true
    ) {
        self.overlayPositionX = overlayPositionX
        self.overlayPositionY = overlayPositionY
        self.notificationsEnabled = notificationsEnabled
        self.soundEnabled = soundEnabled
        self.launchAtLogin = launchAtLogin
        self.defaultDurationMinutes = defaultDurationMinutes
        self.overlayIdleOpacity = overlayIdleOpacity
        self.animationsEnabled = animationsEnabled
        self.lastModified = Date()
    }

    /// Check if custom overlay position is set
    var hasCustomOverlayPosition: Bool {
        overlayPositionX >= 0 && overlayPositionY >= 0
    }

    /// Get overlay position as NSPoint if set
    var overlayPosition: CGPoint? {
        guard hasCustomOverlayPosition else { return nil }
        return CGPoint(x: overlayPositionX, y: overlayPositionY)
    }

    /// Update overlay position
    func setOverlayPosition(_ point: CGPoint) {
        overlayPositionX = point.x
        overlayPositionY = point.y
        lastModified = Date()
    }

    /// Reset overlay position to default
    func resetOverlayPosition() {
        overlayPositionX = -1
        overlayPositionY = -1
        lastModified = Date()
    }
}

// MARK: - Default Preferences

extension UserPreferences {
    /// Create default preferences
    static var defaults: UserPreferences {
        UserPreferences()
    }
}
