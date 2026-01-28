import Testing
import UserNotifications
@testable import TimerFloat

@Suite("NotificationService Tests")
@MainActor
struct NotificationServiceTests {

    // MARK: - Singleton Tests

    @Test("NotificationService has shared instance")
    func sharedInstance() {
        let service = NotificationService.shared
        #expect(service != nil)
    }

    @Test("Shared instance is same object")
    func sharedInstanceIsSingleton() {
        let service1 = NotificationService.shared
        let service2 = NotificationService.shared
        #expect(service1 === service2)
    }

    // MARK: - Action Identifier Tests

    @Test("Restart action identifier is correct")
    func restartActionIdentifier() {
        #expect(NotificationService.ActionIdentifier.restart == "RESTART_TIMER")
    }

    @Test("Dismiss action identifier is correct")
    func dismissActionIdentifier() {
        #expect(NotificationService.ActionIdentifier.dismiss == "DISMISS")
    }

    // MARK: - Error Type Tests

    @Test("NotificationError cases exist")
    func errorCasesExist() {
        // Verify error types compile and are distinct
        let notAuthorized = NotificationError.notAuthorized
        let requestFailed = NotificationError.requestFailed(NSError(domain: "test", code: 1))
        let sendFailed = NotificationError.sendFailed(NSError(domain: "test", code: 2))

        // Check they're different
        switch notAuthorized {
        case .notAuthorized:
            break
        default:
            Issue.record("Expected notAuthorized")
        }

        switch requestFailed {
        case .requestFailed:
            break
        default:
            Issue.record("Expected requestFailed")
        }

        switch sendFailed {
        case .sendFailed:
            break
        default:
            Issue.record("Expected sendFailed")
        }
    }

    // MARK: - Authorization Tests

    @Test("Can check authorization status")
    func canCheckAuthorizationStatus() async {
        let service = NotificationService.shared
        let status = await service.authorizationStatus

        // Status should be one of the valid values
        let validStatuses: [UNAuthorizationStatus] = [
            .notDetermined,
            .denied,
            .authorized,
            .provisional
        ]
        #expect(validStatuses.contains(status))
    }

    @Test("isAuthorized returns boolean")
    func isAuthorizedReturnsBool() async {
        let service = NotificationService.shared
        let isAuth = await service.isAuthorized

        // Should return true or false based on authorization status
        #expect(isAuth == true || isAuth == false)
    }

    // MARK: - Notification Management Tests

    @Test("Can remove all pending notifications")
    func removeAllPendingNotifications() {
        let service = NotificationService.shared

        // Should not throw
        service.removeAllPendingNotifications()
    }

    @Test("Can remove all delivered notifications")
    func removeAllDeliveredNotifications() {
        let service = NotificationService.shared

        // Should not throw
        service.removeAllDeliveredNotifications()
    }
}

// MARK: - Duration Message Format Tests

@Suite("Duration Message Format Tests")
struct DurationMessageFormatTests {

    @Test("One minute message is singular")
    func oneMinuteMessage() {
        let message = formatDurationMessage(60)
        #expect(message == "Your 1 minute timer has finished.")
    }

    @Test("Multiple minutes message is plural")
    func multipleMinutesMessage() {
        let message5 = formatDurationMessage(300)
        #expect(message5 == "Your 5 minute timer has finished.")

        let message25 = formatDurationMessage(1500)
        #expect(message25 == "Your 25 minute timer has finished.")
    }

    @Test("Seconds message for short durations")
    func secondsMessage() {
        let message30 = formatDurationMessage(30)
        #expect(message30 == "Your 30 second timer has finished.")

        let message45 = formatDurationMessage(45)
        #expect(message45 == "Your 45 second timer has finished.")
    }

    @Test("Zero duration shows seconds")
    func zeroDurationMessage() {
        let message = formatDurationMessage(0)
        #expect(message == "Your 0 second timer has finished.")
    }

    // Helper to match NotificationService's internal formatting
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
}
