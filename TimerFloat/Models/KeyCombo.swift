import Carbon
import AppKit

/// Represents a keyboard shortcut combination (key + modifiers)
struct KeyCombo: Codable, Equatable, Sendable {
    /// The virtual key code (Carbon key codes)
    let keyCode: UInt32

    /// The modifier flags (Command, Option, Control, Shift)
    let modifiers: UInt32

    /// Initialize with key code and modifiers
    /// - Parameters:
    ///   - keyCode: Carbon virtual key code
    ///   - modifiers: Modifier flags (use ModifierFlags constants)
    init(keyCode: UInt32, modifiers: UInt32 = 0) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    /// Initialize from NSEvent modifier flags
    /// - Parameters:
    ///   - keyCode: Carbon virtual key code
    ///   - eventModifiers: NSEvent.ModifierFlags
    init(keyCode: UInt32, eventModifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = Self.carbonModifiers(from: eventModifiers)
    }
}

// MARK: - Modifier Flags

extension KeyCombo {
    /// Carbon modifier flag constants
    enum ModifierFlags {
        static let command: UInt32 = UInt32(cmdKey)
        static let option: UInt32 = UInt32(optionKey)
        static let control: UInt32 = UInt32(controlKey)
        static let shift: UInt32 = UInt32(shiftKey)
    }

    /// Check if Command modifier is set
    var hasCommand: Bool {
        modifiers & ModifierFlags.command != 0
    }

    /// Check if Option modifier is set
    var hasOption: Bool {
        modifiers & ModifierFlags.option != 0
    }

    /// Check if Control modifier is set
    var hasControl: Bool {
        modifiers & ModifierFlags.control != 0
    }

    /// Check if Shift modifier is set
    var hasShift: Bool {
        modifiers & ModifierFlags.shift != 0
    }

    /// Convert NSEvent.ModifierFlags to Carbon modifier flags
    static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= ModifierFlags.command }
        if flags.contains(.option) { result |= ModifierFlags.option }
        if flags.contains(.control) { result |= ModifierFlags.control }
        if flags.contains(.shift) { result |= ModifierFlags.shift }
        return result
    }

    /// Convert Carbon modifiers to NSEvent.ModifierFlags
    var nsEventModifiers: NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if hasCommand { flags.insert(.command) }
        if hasOption { flags.insert(.option) }
        if hasControl { flags.insert(.control) }
        if hasShift { flags.insert(.shift) }
        return flags
    }
}

// MARK: - Display String

extension KeyCombo {
    /// Human-readable string representation of the key combo
    var displayString: String {
        var parts: [String] = []

        // Modifiers in standard macOS order
        if hasControl { parts.append("⌃") }
        if hasOption { parts.append("⌥") }
        if hasShift { parts.append("⇧") }
        if hasCommand { parts.append("⌘") }

        // Key name
        parts.append(keyName)

        return parts.joined()
    }

    /// Name of the key based on key code
    private var keyName: String {
        switch Int(keyCode) {
        // Letters
        case kVK_ANSI_A: return "A"
        case kVK_ANSI_B: return "B"
        case kVK_ANSI_C: return "C"
        case kVK_ANSI_D: return "D"
        case kVK_ANSI_E: return "E"
        case kVK_ANSI_F: return "F"
        case kVK_ANSI_G: return "G"
        case kVK_ANSI_H: return "H"
        case kVK_ANSI_I: return "I"
        case kVK_ANSI_J: return "J"
        case kVK_ANSI_K: return "K"
        case kVK_ANSI_L: return "L"
        case kVK_ANSI_M: return "M"
        case kVK_ANSI_N: return "N"
        case kVK_ANSI_O: return "O"
        case kVK_ANSI_P: return "P"
        case kVK_ANSI_Q: return "Q"
        case kVK_ANSI_R: return "R"
        case kVK_ANSI_S: return "S"
        case kVK_ANSI_T: return "T"
        case kVK_ANSI_U: return "U"
        case kVK_ANSI_V: return "V"
        case kVK_ANSI_W: return "W"
        case kVK_ANSI_X: return "X"
        case kVK_ANSI_Y: return "Y"
        case kVK_ANSI_Z: return "Z"

        // Numbers
        case kVK_ANSI_0: return "0"
        case kVK_ANSI_1: return "1"
        case kVK_ANSI_2: return "2"
        case kVK_ANSI_3: return "3"
        case kVK_ANSI_4: return "4"
        case kVK_ANSI_5: return "5"
        case kVK_ANSI_6: return "6"
        case kVK_ANSI_7: return "7"
        case kVK_ANSI_8: return "8"
        case kVK_ANSI_9: return "9"

        // Function keys
        case kVK_F1: return "F1"
        case kVK_F2: return "F2"
        case kVK_F3: return "F3"
        case kVK_F4: return "F4"
        case kVK_F5: return "F5"
        case kVK_F6: return "F6"
        case kVK_F7: return "F7"
        case kVK_F8: return "F8"
        case kVK_F9: return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"

        // Special keys
        case kVK_Space: return "Space"
        case kVK_Return: return "↩"
        case kVK_Tab: return "⇥"
        case kVK_Delete: return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Escape: return "⎋"
        case kVK_LeftArrow: return "←"
        case kVK_RightArrow: return "→"
        case kVK_UpArrow: return "↑"
        case kVK_DownArrow: return "↓"
        case kVK_Home: return "↖"
        case kVK_End: return "↘"
        case kVK_PageUp: return "⇞"
        case kVK_PageDown: return "⇟"

        default: return "Key\(keyCode)"
        }
    }
}

// MARK: - Factory Methods

extension KeyCombo {
    /// Create a key combo with Command modifier
    static func command(_ keyCode: UInt32) -> KeyCombo {
        KeyCombo(keyCode: keyCode, modifiers: ModifierFlags.command)
    }

    /// Create a key combo with Command+Shift modifiers
    static func commandShift(_ keyCode: UInt32) -> KeyCombo {
        KeyCombo(keyCode: keyCode, modifiers: ModifierFlags.command | ModifierFlags.shift)
    }

    /// Create a key combo with Command+Option modifiers
    static func commandOption(_ keyCode: UInt32) -> KeyCombo {
        KeyCombo(keyCode: keyCode, modifiers: ModifierFlags.command | ModifierFlags.option)
    }

    /// Create a key combo with Control+Option modifiers
    static func controlOption(_ keyCode: UInt32) -> KeyCombo {
        KeyCombo(keyCode: keyCode, modifiers: ModifierFlags.control | ModifierFlags.option)
    }

    /// Default hotkey for starting/stopping timer (Ctrl+Opt+T)
    static var defaultToggle: KeyCombo {
        controlOption(UInt32(kVK_ANSI_T))
    }

    /// Default hotkey for pausing timer (Ctrl+Opt+P)
    static var defaultPause: KeyCombo {
        controlOption(UInt32(kVK_ANSI_P))
    }
}

// MARK: - Common Key Codes

extension KeyCombo {
    /// Common key codes for convenience
    enum KeyCodes {
        static let t = UInt32(kVK_ANSI_T)
        static let p = UInt32(kVK_ANSI_P)
        static let s = UInt32(kVK_ANSI_S)
        static let space = UInt32(kVK_Space)
        static let escape = UInt32(kVK_Escape)
    }
}
