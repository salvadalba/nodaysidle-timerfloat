import Testing
import Foundation
@testable import TimerFloat

@Suite("UserPreferences Tests")
struct UserPreferencesTests {

    // MARK: - Default Value Tests

    @Test("Default preferences have correct initial values")
    func defaultValues() {
        let prefs = UserPreferences.defaults

        #expect(prefs.overlayPositionX == -1)
        #expect(prefs.overlayPositionY == -1)
        #expect(prefs.notificationsEnabled == true)
        #expect(prefs.soundEnabled == true)
        #expect(prefs.launchAtLogin == false)
        #expect(prefs.defaultDurationMinutes == 25)
        #expect(prefs.overlayIdleOpacity == 0.8)
    }

    @Test("hasCustomOverlayPosition returns false for defaults")
    func noCustomPositionByDefault() {
        let prefs = UserPreferences.defaults

        #expect(prefs.hasCustomOverlayPosition == false)
        #expect(prefs.overlayPosition == nil)
    }

    @Test("Custom initializer sets values correctly")
    func customInitializer() {
        let prefs = UserPreferences(
            overlayPositionX: 100,
            overlayPositionY: 200,
            notificationsEnabled: false,
            soundEnabled: false,
            launchAtLogin: true,
            defaultDurationMinutes: 45,
            overlayIdleOpacity: 0.5
        )

        #expect(prefs.overlayPositionX == 100)
        #expect(prefs.overlayPositionY == 200)
        #expect(prefs.notificationsEnabled == false)
        #expect(prefs.soundEnabled == false)
        #expect(prefs.launchAtLogin == true)
        #expect(prefs.defaultDurationMinutes == 45)
        #expect(prefs.overlayIdleOpacity == 0.5)
    }

    // MARK: - Overlay Position Tests

    @Test("setOverlayPosition updates position values")
    func setOverlayPosition() {
        let prefs = UserPreferences.defaults
        let testPoint = CGPoint(x: 150, y: 250)

        prefs.setOverlayPosition(testPoint)

        #expect(prefs.overlayPositionX == 150)
        #expect(prefs.overlayPositionY == 250)
        #expect(prefs.hasCustomOverlayPosition == true)
    }

    @Test("overlayPosition returns CGPoint when set")
    func overlayPositionReturnsPoint() {
        let prefs = UserPreferences.defaults
        prefs.setOverlayPosition(CGPoint(x: 300, y: 400))

        let position = prefs.overlayPosition
        #expect(position != nil)
        #expect(position?.x == 300)
        #expect(position?.y == 400)
    }

    @Test("resetOverlayPosition clears position")
    func resetOverlayPosition() {
        let prefs = UserPreferences.defaults
        prefs.setOverlayPosition(CGPoint(x: 100, y: 100))
        #expect(prefs.hasCustomOverlayPosition == true)

        prefs.resetOverlayPosition()

        #expect(prefs.hasCustomOverlayPosition == false)
        #expect(prefs.overlayPosition == nil)
        #expect(prefs.overlayPositionX == -1)
        #expect(prefs.overlayPositionY == -1)
    }

    @Test("setOverlayPosition updates lastModified")
    func setPositionUpdatesTimestamp() {
        let prefs = UserPreferences.defaults
        let originalTime = prefs.lastModified

        // Small delay to ensure time difference
        Thread.sleep(forTimeInterval: 0.01)

        prefs.setOverlayPosition(CGPoint(x: 50, y: 50))

        #expect(prefs.lastModified > originalTime)
    }

    // MARK: - Edge Case Tests

    @Test("Zero position is considered custom")
    func zeroPositionIsCustom() {
        let prefs = UserPreferences(
            overlayPositionX: 0,
            overlayPositionY: 0
        )

        #expect(prefs.hasCustomOverlayPosition == true)
        #expect(prefs.overlayPosition != nil)
    }

    @Test("Negative X only is not custom position")
    func negativeXOnlyNotCustom() {
        let prefs = UserPreferences(
            overlayPositionX: -1,
            overlayPositionY: 100
        )

        #expect(prefs.hasCustomOverlayPosition == false)
    }

    @Test("Negative Y only is not custom position")
    func negativeYOnlyNotCustom() {
        let prefs = UserPreferences(
            overlayPositionX: 100,
            overlayPositionY: -1
        )

        #expect(prefs.hasCustomOverlayPosition == false)
    }

    // MARK: - Preference Field Tests

    @Test("notificationsEnabled can be toggled")
    func toggleNotifications() {
        let prefs = UserPreferences.defaults
        #expect(prefs.notificationsEnabled == true)

        prefs.notificationsEnabled = false
        #expect(prefs.notificationsEnabled == false)

        prefs.notificationsEnabled = true
        #expect(prefs.notificationsEnabled == true)
    }

    @Test("soundEnabled can be toggled")
    func toggleSound() {
        let prefs = UserPreferences.defaults
        #expect(prefs.soundEnabled == true)

        prefs.soundEnabled = false
        #expect(prefs.soundEnabled == false)
    }

    @Test("launchAtLogin can be toggled")
    func toggleLaunchAtLogin() {
        let prefs = UserPreferences.defaults
        #expect(prefs.launchAtLogin == false)

        prefs.launchAtLogin = true
        #expect(prefs.launchAtLogin == true)
    }

    @Test("defaultDurationMinutes can be changed")
    func changeDuration() {
        let prefs = UserPreferences.defaults
        #expect(prefs.defaultDurationMinutes == 25)

        prefs.defaultDurationMinutes = 60
        #expect(prefs.defaultDurationMinutes == 60)

        prefs.defaultDurationMinutes = 5
        #expect(prefs.defaultDurationMinutes == 5)
    }

    @Test("overlayIdleOpacity can be changed")
    func changeOpacity() {
        let prefs = UserPreferences.defaults
        #expect(prefs.overlayIdleOpacity == 0.8)

        prefs.overlayIdleOpacity = 0.5
        #expect(prefs.overlayIdleOpacity == 0.5)

        prefs.overlayIdleOpacity = 1.0
        #expect(prefs.overlayIdleOpacity == 1.0)
    }

    // MARK: - Timestamp Tests

    @Test("lastModified is set on creation")
    func lastModifiedSetOnCreation() {
        let beforeCreation = Date()
        let prefs = UserPreferences.defaults
        let afterCreation = Date()

        #expect(prefs.lastModified >= beforeCreation)
        #expect(prefs.lastModified <= afterCreation)
    }
}
