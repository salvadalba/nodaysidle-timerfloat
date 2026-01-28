import Foundation
import SwiftData
import os

/// Errors that can occur during preferences operations
enum PreferencesError: Error, Sendable {
    case containerNotInitialized
    case fetchFailed(underlying: Error)
    case saveFailed(underlying: Error)
}

/// Service for managing user preferences with SwiftData persistence
@MainActor
final class PreferencesService {
    /// Shared instance for app-wide preferences access
    static let shared = PreferencesService()

    /// SwiftData model container
    private var container: ModelContainer?

    /// SwiftData model context
    private var context: ModelContext?

    /// Cached preferences for quick access
    private var cachedPreferences: UserPreferences?

    private init() {
        do {
            try initializeContainer()
            Log.preferences.info("PreferencesService initialized successfully")
        } catch {
            Log.preferences.error("Failed to initialize PreferencesService: \(error.localizedDescription)")
        }
    }

    // MARK: - Initialization

    /// Initialize the SwiftData container
    private func initializeContainer() throws {
        let schema = Schema([UserPreferences.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        container = try ModelContainer(for: schema, configurations: [configuration])
        context = container?.mainContext

        Log.preferences.debug("SwiftData container initialized")
    }

    // MARK: - Public API

    /// Fetch existing preferences or create default ones
    /// - Returns: The user preferences
    func fetchOrCreatePreferences() throws(PreferencesError) -> UserPreferences {
        // Return cached if available
        if let cached = cachedPreferences {
            return cached
        }

        guard let context else {
            throw .containerNotInitialized
        }

        do {
            let descriptor = FetchDescriptor<UserPreferences>()
            let results = try context.fetch(descriptor)

            if let existing = results.first {
                cachedPreferences = existing
                Log.preferences.debug("Fetched existing preferences")
                return existing
            }

            // Create default preferences
            let defaults = UserPreferences.defaults
            context.insert(defaults)
            try context.save()
            cachedPreferences = defaults

            Log.preferences.info("Created default preferences")
            return defaults
        } catch {
            throw .fetchFailed(underlying: error)
        }
    }

    /// Get the current preferences (convenience accessor)
    var preferences: UserPreferences? {
        try? fetchOrCreatePreferences()
    }

    /// Save any pending changes to preferences
    func save() throws(PreferencesError) {
        guard let context else {
            throw .containerNotInitialized
        }

        do {
            if context.hasChanges {
                cachedPreferences?.lastModified = Date()
                try context.save()
                Log.preferences.debug("Preferences saved")
            }
        } catch {
            throw .saveFailed(underlying: error)
        }
    }

    // MARK: - Overlay Position

    /// Update the saved overlay position
    /// - Parameter position: The new position
    func updateOverlayPosition(_ position: CGPoint) throws(PreferencesError) {
        let prefs = try fetchOrCreatePreferences()
        prefs.setOverlayPosition(position)
        try save()

        Log.preferences.debug("Overlay position updated to (\(position.x), \(position.y))")
    }

    /// Reset overlay position to default
    func resetOverlayPosition() throws(PreferencesError) {
        let prefs = try fetchOrCreatePreferences()
        prefs.resetOverlayPosition()
        try save()

        Log.preferences.debug("Overlay position reset to default")
    }

    // MARK: - Notification Settings

    /// Update notifications enabled preference
    /// - Parameter enabled: Whether notifications are enabled
    func updateNotificationsEnabled(_ enabled: Bool) throws(PreferencesError) {
        let prefs = try fetchOrCreatePreferences()
        prefs.notificationsEnabled = enabled
        try save()

        Log.preferences.debug("Notifications enabled: \(enabled)")
    }

    /// Update sound enabled preference
    /// - Parameter enabled: Whether sound is enabled
    func updateSoundEnabled(_ enabled: Bool) throws(PreferencesError) {
        let prefs = try fetchOrCreatePreferences()
        prefs.soundEnabled = enabled
        try save()

        Log.preferences.debug("Sound enabled: \(enabled)")
    }

    // MARK: - App Settings

    /// Update launch at login preference
    /// - Parameter enabled: Whether to launch at login
    func updateLaunchAtLogin(_ enabled: Bool) throws(PreferencesError) {
        let prefs = try fetchOrCreatePreferences()
        prefs.launchAtLogin = enabled
        try save()

        Log.preferences.debug("Launch at login: \(enabled)")
    }

    /// Update default timer duration
    /// - Parameter minutes: Default duration in minutes
    func updateDefaultDuration(_ minutes: Int) throws(PreferencesError) {
        let prefs = try fetchOrCreatePreferences()
        prefs.defaultDurationMinutes = max(1, minutes)
        try save()

        Log.preferences.debug("Default duration: \(minutes) minutes")
    }

    /// Update overlay idle opacity
    /// - Parameter opacity: Opacity value (0.0 to 1.0)
    func updateOverlayIdleOpacity(_ opacity: Double) throws(PreferencesError) {
        let prefs = try fetchOrCreatePreferences()
        prefs.overlayIdleOpacity = max(0.1, min(1.0, opacity))
        try save()

        Log.preferences.debug("Overlay idle opacity: \(opacity)")
    }

    /// Update animations enabled preference
    /// - Parameter enabled: Whether animations are enabled
    func updateAnimationsEnabled(_ enabled: Bool) throws(PreferencesError) {
        let prefs = try fetchOrCreatePreferences()
        prefs.animationsEnabled = enabled
        try save()

        Log.preferences.debug("Animations enabled: \(enabled)")
    }
}
