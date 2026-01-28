import UserNotifications
import AppKit
import os

/// Errors that can occur during notification operations
enum NotificationError: Error, Sendable {
    case notAuthorized
    case requestFailed(Error)
    case sendFailed(Error)
}

/// Service for managing local notifications
@MainActor
final class NotificationService: NSObject {
    /// Shared instance for app-wide notification management
    static let shared = NotificationService()

    /// The notification center
    private let notificationCenter = UNUserNotificationCenter.current()

    /// Notification category identifier for timer completion
    private static let timerCompletedCategory = "TIMER_COMPLETED"

    /// Notification action identifiers
    enum ActionIdentifier {
        static let restart = "RESTART_TIMER"
        static let dismiss = "DISMISS"
    }

    private override init() {
        super.init()
        setupNotificationCategories()
        notificationCenter.delegate = self
        Log.notification.info("NotificationService initialized")
    }

    // MARK: - Authorization

    /// Current authorization status
    var authorizationStatus: UNAuthorizationStatus {
        get async {
            let settings = await notificationCenter.notificationSettings()
            return settings.authorizationStatus
        }
    }

    /// Check if notifications are authorized
    var isAuthorized: Bool {
        get async {
            let status = await authorizationStatus
            return status == .authorized || status == .provisional
        }
    }

    /// Request notification authorization
    /// - Returns: true if authorization was granted
    @discardableResult
    func requestAuthorization() async throws(NotificationError) -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            Log.notification.info("Notification authorization \(granted ? "granted" : "denied")")
            return granted
        } catch {
            Log.notification.error("Failed to request notification authorization: \(error.localizedDescription)")
            throw .requestFailed(error)
        }
    }

    // MARK: - Notification Categories

    /// Set up notification categories and actions
    private func setupNotificationCategories() {
        let restartAction = UNNotificationAction(
            identifier: ActionIdentifier.restart,
            title: "Start Again",
            options: .foreground
        )

        let dismissAction = UNNotificationAction(
            identifier: ActionIdentifier.dismiss,
            title: "Dismiss",
            options: .destructive
        )

        let timerCategory = UNNotificationCategory(
            identifier: Self.timerCompletedCategory,
            actions: [restartAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )

        notificationCenter.setNotificationCategories([timerCategory])
        Log.notification.debug("Notification categories configured")
    }

    // MARK: - Send Notifications

    /// Send a timer completed notification
    /// - Parameter duration: The original timer duration in seconds
    func sendTimerCompletedNotification(duration: TimeInterval) async throws(NotificationError) {
        // Check authorization
        guard await isAuthorized else {
            Log.notification.warning("Cannot send notification - not authorized")
            throw .notAuthorized
        }

        // Check if notifications are enabled in preferences
        guard PreferencesService.shared.preferences?.notificationsEnabled == true else {
            Log.notification.debug("Notifications disabled in preferences")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Timer Complete!"
        content.body = formatDurationMessage(duration)
        content.categoryIdentifier = Self.timerCompletedCategory

        // Add sound if enabled in preferences
        if PreferencesService.shared.preferences?.soundEnabled == true {
            content.sound = .default
        }

        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil  // Deliver immediately
        )

        do {
            try await notificationCenter.add(request)
            Log.notification.info("Timer completed notification sent")
        } catch {
            Log.notification.error("Failed to send notification: \(error.localizedDescription)")
            throw .sendFailed(error)
        }
    }

    /// Format duration for notification body
    private func formatDurationMessage(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes == 1 {
            return "Your 1 minute timer has finished."
        } else if minutes > 0 {
            return "Your \(minutes) minute timer has finished."
        } else {
            let seconds = Int(duration)
            return "Your \(seconds) second timer has finished."
        }
    }

    // MARK: - Clear Notifications

    /// Remove all pending notifications
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        Log.notification.debug("All pending notifications removed")
    }

    /// Remove all delivered notifications
    func removeAllDeliveredNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        Log.notification.debug("All delivered notifications removed")
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension NotificationService: UNUserNotificationCenterDelegate {
    /// Handle notification when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.banner, .sound]
    }

    /// Handle notification action response
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionIdentifier = response.actionIdentifier

        await MainActor.run {
            switch actionIdentifier {
            case ActionIdentifier.restart:
                Log.notification.info("User tapped restart action")
                // Restart timer with default duration
                let duration = PreferencesService.shared.preferences?.defaultDurationMinutes ?? 25
                AppController.shared.startTimer(minutes: duration)

            case ActionIdentifier.dismiss, UNNotificationDismissActionIdentifier:
                Log.notification.debug("Notification dismissed")

            case UNNotificationDefaultActionIdentifier:
                Log.notification.debug("Notification tapped")
                // Could bring app to foreground or show overlay

            default:
                Log.notification.debug("Unknown action: \(actionIdentifier)")
            }
        }
    }
}
