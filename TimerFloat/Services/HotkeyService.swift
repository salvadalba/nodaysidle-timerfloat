import Carbon
import AppKit
import os

/// Actions that can be triggered by hotkeys
enum HotkeyAction: String, CaseIterable, Sendable {
    case toggleTimer
    case pauseResume
    case cancelTimer
    case showOverlay
}

/// Errors that can occur during hotkey operations
enum HotkeyError: Error, Sendable {
    case registrationFailed(OSStatus)
    case unregistrationFailed(OSStatus)
    case invalidKeyCombo
    case hotkeyNotFound
}

/// Service for managing global keyboard shortcuts using Carbon Events API
@MainActor
final class HotkeyService {
    /// Shared instance for app-wide hotkey management
    static let shared = HotkeyService()

    /// Registered hotkey references mapped by action
    private var registeredHotkeys: [HotkeyAction: (ref: EventHotKeyRef?, id: UInt32)] = [:]

    /// Counter for generating unique hotkey IDs
    private var nextHotkeyID: UInt32 = 1

    /// Event handler reference
    private var eventHandlerRef: EventHandlerRef?

    /// Callback closure for hotkey events
    var onHotkeyPressed: ((HotkeyAction) -> Void)?

    private init() {
        installEventHandler()
        Log.hotkey.info("HotkeyService initialized")
    }

    deinit {
        // Note: Cleanup happens when the app terminates
        // Individual hotkey cleanup is handled by unregisterHotkey calls
    }

    // MARK: - Public API

    /// Register a hotkey for an action
    /// - Parameters:
    ///   - keyCombo: The key combination to register
    ///   - action: The action to trigger when pressed
    func registerHotkey(_ keyCombo: KeyCombo, for action: HotkeyAction) throws(HotkeyError) {
        // Unregister existing hotkey for this action if any
        try? unregisterHotkey(for: action)

        let hotkeyID = nextHotkeyID
        nextHotkeyID += 1

        var hotKeyRef: EventHotKeyRef?
        var hotKeyID = EventHotKeyID(signature: OSType(0x54464C54), id: hotkeyID)  // 'TFLT' signature

        let status = RegisterEventHotKey(
            keyCombo.keyCode,
            keyCombo.modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        guard status == noErr else {
            Log.hotkey.error("Failed to register hotkey for \(action.rawValue): \(status)")
            throw .registrationFailed(status)
        }

        registeredHotkeys[action] = (ref: hotKeyRef, id: hotkeyID)
        Log.hotkey.info("Registered hotkey \(keyCombo.displayString) for \(action.rawValue)")
    }

    /// Unregister the hotkey for an action
    /// - Parameter action: The action to unregister
    func unregisterHotkey(for action: HotkeyAction) throws(HotkeyError) {
        guard let entry = registeredHotkeys[action], let ref = entry.ref else {
            throw .hotkeyNotFound
        }

        let status = UnregisterEventHotKey(ref)
        guard status == noErr else {
            Log.hotkey.error("Failed to unregister hotkey for \(action.rawValue): \(status)")
            throw .unregistrationFailed(status)
        }

        registeredHotkeys.removeValue(forKey: action)
        Log.hotkey.info("Unregistered hotkey for \(action.rawValue)")
    }

    /// Unregister all hotkeys
    func unregisterAllHotkeys() {
        for action in registeredHotkeys.keys {
            try? unregisterHotkey(for: action)
        }
    }

    /// Check if a hotkey is registered for an action
    func isHotkeyRegistered(for action: HotkeyAction) -> Bool {
        registeredHotkeys[action] != nil
    }

    /// Get the hotkey ID for an action
    func hotkeyID(for action: HotkeyAction) -> UInt32? {
        registeredHotkeys[action]?.id
    }

    // MARK: - Event Handling

    /// Install the Carbon event handler for hotkey events
    private func installEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        // Store self reference for callback
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, userData) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                let service = Unmanaged<HotkeyService>.fromOpaque(userData).takeUnretainedValue()
                return service.handleHotkeyEvent(event)
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        if status != noErr {
            Log.hotkey.error("Failed to install event handler: \(status)")
        } else {
            Log.hotkey.debug("Event handler installed")
        }
    }

    /// Handle a hotkey event
    private func handleHotkeyEvent(_ event: EventRef?) -> OSStatus {
        guard let event = event else { return OSStatus(eventNotHandledErr) }

        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            UInt32(kEventParamDirectObject),
            UInt32(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )

        guard status == noErr else {
            return OSStatus(eventNotHandledErr)
        }

        // Find the action for this hotkey ID
        for (action, entry) in registeredHotkeys {
            if entry.id == hotKeyID.id {
                Log.hotkey.debug("Hotkey pressed for action: \(action.rawValue)")
                Task { @MainActor in
                    self.onHotkeyPressed?(action)
                }
                return noErr
            }
        }

        return OSStatus(eventNotHandledErr)
    }

    // MARK: - Default Hotkeys

    /// Register default hotkeys
    func registerDefaultHotkeys() {
        do {
            try registerHotkey(.defaultToggle, for: .toggleTimer)
            try registerHotkey(.defaultPause, for: .pauseResume)
            Log.hotkey.info("Default hotkeys registered")
        } catch {
            Log.hotkey.error("Failed to register default hotkeys: \(error)")
        }
    }
}

// MARK: - Accessibility Permission

extension HotkeyService {
    /// Check if accessibility permissions are granted
    nonisolated static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    /// Request accessibility permissions
    /// - Returns: true if permissions were already granted
    @discardableResult
    nonisolated static func requestAccessibilityPermission() -> Bool {
        // Use the string key directly to avoid concurrency issues with the global constant
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
}
