import ServiceManagement
import os

/// Service for managing launch at login functionality using SMAppService
@MainActor
final class LaunchAtLoginService {
    /// Shared instance for app-wide access
    static let shared = LaunchAtLoginService()

    /// The login item service
    private let loginItem = SMAppService.mainApp

    private init() {
        Log.app.info("LaunchAtLoginService initialized")
    }

    // MARK: - Public API

    /// Check if the app is registered to launch at login
    var isEnabled: Bool {
        loginItem.status == .enabled
    }

    /// Current status of the login item
    var status: SMAppService.Status {
        loginItem.status
    }

    /// Enable launch at login
    /// - Throws: Error if registration fails
    func enable() throws {
        guard !isEnabled else {
            Log.app.debug("Launch at login already enabled")
            return
        }

        do {
            try loginItem.register()
            Log.app.info("Launch at login enabled")
        } catch {
            Log.app.error("Failed to enable launch at login: \(error.localizedDescription)")
            throw error
        }
    }

    /// Disable launch at login
    /// - Throws: Error if unregistration fails
    func disable() throws {
        guard isEnabled else {
            Log.app.debug("Launch at login already disabled")
            return
        }

        do {
            try loginItem.unregister()
            Log.app.info("Launch at login disabled")
        } catch {
            Log.app.error("Failed to disable launch at login: \(error.localizedDescription)")
            throw error
        }
    }

    /// Set launch at login state
    /// - Parameter enabled: Whether to enable or disable launch at login
    /// - Throws: Error if the operation fails
    func setEnabled(_ enabled: Bool) throws {
        if enabled {
            try enable()
        } else {
            try disable()
        }
    }

    /// Sync the preference with the actual login item status
    /// Call this on app launch to ensure preference matches reality
    func syncWithPreference() {
        let prefs = PreferencesService.shared.preferences
        let prefEnabled = prefs?.launchAtLogin ?? false
        let actualEnabled = isEnabled

        if prefEnabled != actualEnabled {
            Log.app.info("Syncing launch at login preference: pref=\(prefEnabled), actual=\(actualEnabled)")
            // Update preference to match actual state
            try? PreferencesService.shared.updateLaunchAtLogin(actualEnabled)
        }
    }
}
