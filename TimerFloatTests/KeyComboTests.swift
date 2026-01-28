import Testing
import Foundation
import Carbon
@testable import TimerFloat

@Suite("KeyCombo Tests")
struct KeyComboTests {

    // MARK: - Initialization Tests

    @Test("Initialize with key code and modifiers")
    func initWithKeyCodeAndModifiers() {
        let combo = KeyCombo(keyCode: UInt32(kVK_ANSI_T), modifiers: KeyCombo.ModifierFlags.command)

        #expect(combo.keyCode == UInt32(kVK_ANSI_T))
        #expect(combo.modifiers == KeyCombo.ModifierFlags.command)
    }

    @Test("Initialize with zero modifiers by default")
    func initWithDefaultModifiers() {
        let combo = KeyCombo(keyCode: UInt32(kVK_ANSI_A))

        #expect(combo.keyCode == UInt32(kVK_ANSI_A))
        #expect(combo.modifiers == 0)
    }

    // MARK: - Modifier Flag Tests

    @Test("hasCommand returns true when command modifier is set")
    func hasCommandModifier() {
        let combo = KeyCombo(keyCode: 0, modifiers: KeyCombo.ModifierFlags.command)
        #expect(combo.hasCommand == true)
        #expect(combo.hasOption == false)
        #expect(combo.hasControl == false)
        #expect(combo.hasShift == false)
    }

    @Test("hasOption returns true when option modifier is set")
    func hasOptionModifier() {
        let combo = KeyCombo(keyCode: 0, modifiers: KeyCombo.ModifierFlags.option)
        #expect(combo.hasCommand == false)
        #expect(combo.hasOption == true)
        #expect(combo.hasControl == false)
        #expect(combo.hasShift == false)
    }

    @Test("hasControl returns true when control modifier is set")
    func hasControlModifier() {
        let combo = KeyCombo(keyCode: 0, modifiers: KeyCombo.ModifierFlags.control)
        #expect(combo.hasCommand == false)
        #expect(combo.hasOption == false)
        #expect(combo.hasControl == true)
        #expect(combo.hasShift == false)
    }

    @Test("hasShift returns true when shift modifier is set")
    func hasShiftModifier() {
        let combo = KeyCombo(keyCode: 0, modifiers: KeyCombo.ModifierFlags.shift)
        #expect(combo.hasCommand == false)
        #expect(combo.hasOption == false)
        #expect(combo.hasControl == false)
        #expect(combo.hasShift == true)
    }

    @Test("Multiple modifiers can be combined")
    func combinedModifiers() {
        let modifiers = KeyCombo.ModifierFlags.command | KeyCombo.ModifierFlags.shift
        let combo = KeyCombo(keyCode: 0, modifiers: modifiers)

        #expect(combo.hasCommand == true)
        #expect(combo.hasShift == true)
        #expect(combo.hasOption == false)
        #expect(combo.hasControl == false)
    }

    // MARK: - Display String Tests

    @Test("Display string for Command+T")
    func displayStringCommandT() {
        let combo = KeyCombo.command(UInt32(kVK_ANSI_T))
        #expect(combo.displayString == "⌘T")
    }

    @Test("Display string for Command+Shift+S")
    func displayStringCommandShiftS() {
        let combo = KeyCombo.commandShift(UInt32(kVK_ANSI_S))
        #expect(combo.displayString == "⇧⌘S")
    }

    @Test("Display string for Control+Option+T")
    func displayStringControlOptionT() {
        let combo = KeyCombo.controlOption(UInt32(kVK_ANSI_T))
        #expect(combo.displayString == "⌃⌥T")
    }

    @Test("Display string includes all modifiers in correct order")
    func displayStringModifierOrder() {
        // Control, Option, Shift, Command order
        let modifiers = KeyCombo.ModifierFlags.command |
                       KeyCombo.ModifierFlags.option |
                       KeyCombo.ModifierFlags.control |
                       KeyCombo.ModifierFlags.shift
        let combo = KeyCombo(keyCode: UInt32(kVK_ANSI_A), modifiers: modifiers)

        #expect(combo.displayString == "⌃⌥⇧⌘A")
    }

    @Test("Display string for function keys")
    func displayStringFunctionKeys() {
        let f1 = KeyCombo(keyCode: UInt32(kVK_F1), modifiers: 0)
        #expect(f1.displayString == "F1")

        let f12 = KeyCombo(keyCode: UInt32(kVK_F12), modifiers: 0)
        #expect(f12.displayString == "F12")
    }

    @Test("Display string for special keys")
    func displayStringSpecialKeys() {
        let space = KeyCombo(keyCode: UInt32(kVK_Space), modifiers: 0)
        #expect(space.displayString == "Space")

        let escape = KeyCombo(keyCode: UInt32(kVK_Escape), modifiers: 0)
        #expect(escape.displayString == "⎋")

        let returnKey = KeyCombo(keyCode: UInt32(kVK_Return), modifiers: 0)
        #expect(returnKey.displayString == "↩")
    }

    // MARK: - Factory Method Tests

    @Test("command factory creates correct combo")
    func commandFactory() {
        let combo = KeyCombo.command(UInt32(kVK_ANSI_P))

        #expect(combo.keyCode == UInt32(kVK_ANSI_P))
        #expect(combo.hasCommand == true)
        #expect(combo.hasOption == false)
        #expect(combo.hasControl == false)
        #expect(combo.hasShift == false)
    }

    @Test("commandShift factory creates correct combo")
    func commandShiftFactory() {
        let combo = KeyCombo.commandShift(UInt32(kVK_ANSI_N))

        #expect(combo.keyCode == UInt32(kVK_ANSI_N))
        #expect(combo.hasCommand == true)
        #expect(combo.hasShift == true)
        #expect(combo.hasOption == false)
        #expect(combo.hasControl == false)
    }

    @Test("commandOption factory creates correct combo")
    func commandOptionFactory() {
        let combo = KeyCombo.commandOption(UInt32(kVK_ANSI_O))

        #expect(combo.keyCode == UInt32(kVK_ANSI_O))
        #expect(combo.hasCommand == true)
        #expect(combo.hasOption == true)
        #expect(combo.hasControl == false)
        #expect(combo.hasShift == false)
    }

    @Test("controlOption factory creates correct combo")
    func controlOptionFactory() {
        let combo = KeyCombo.controlOption(UInt32(kVK_ANSI_T))

        #expect(combo.keyCode == UInt32(kVK_ANSI_T))
        #expect(combo.hasControl == true)
        #expect(combo.hasOption == true)
        #expect(combo.hasCommand == false)
        #expect(combo.hasShift == false)
    }

    @Test("defaultToggle is Control+Option+T")
    func defaultToggleCombo() {
        let combo = KeyCombo.defaultToggle

        #expect(combo.keyCode == UInt32(kVK_ANSI_T))
        #expect(combo.hasControl == true)
        #expect(combo.hasOption == true)
        #expect(combo.displayString == "⌃⌥T")
    }

    @Test("defaultPause is Control+Option+P")
    func defaultPauseCombo() {
        let combo = KeyCombo.defaultPause

        #expect(combo.keyCode == UInt32(kVK_ANSI_P))
        #expect(combo.hasControl == true)
        #expect(combo.hasOption == true)
        #expect(combo.displayString == "⌃⌥P")
    }

    // MARK: - Codable Tests

    @Test("KeyCombo encodes and decodes correctly")
    func codableRoundTrip() throws {
        let original = KeyCombo.commandShift(UInt32(kVK_ANSI_S))

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(KeyCombo.self, from: data)

        #expect(decoded.keyCode == original.keyCode)
        #expect(decoded.modifiers == original.modifiers)
        #expect(decoded == original)
    }

    @Test("KeyCombo with all modifiers encodes correctly")
    func codableAllModifiers() throws {
        let modifiers = KeyCombo.ModifierFlags.command |
                       KeyCombo.ModifierFlags.option |
                       KeyCombo.ModifierFlags.control |
                       KeyCombo.ModifierFlags.shift
        let original = KeyCombo(keyCode: UInt32(kVK_ANSI_Z), modifiers: modifiers)

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(KeyCombo.self, from: data)

        #expect(decoded == original)
        #expect(decoded.hasCommand == true)
        #expect(decoded.hasOption == true)
        #expect(decoded.hasControl == true)
        #expect(decoded.hasShift == true)
    }

    // MARK: - Equatable Tests

    @Test("Equal combos are equal")
    func equalCombos() {
        let combo1 = KeyCombo.command(UInt32(kVK_ANSI_A))
        let combo2 = KeyCombo.command(UInt32(kVK_ANSI_A))

        #expect(combo1 == combo2)
    }

    @Test("Different key codes are not equal")
    func differentKeyCodes() {
        let combo1 = KeyCombo.command(UInt32(kVK_ANSI_A))
        let combo2 = KeyCombo.command(UInt32(kVK_ANSI_B))

        #expect(combo1 != combo2)
    }

    @Test("Different modifiers are not equal")
    func differentModifiers() {
        let combo1 = KeyCombo.command(UInt32(kVK_ANSI_A))
        let combo2 = KeyCombo.commandShift(UInt32(kVK_ANSI_A))

        #expect(combo1 != combo2)
    }

    // MARK: - Key Code Constants Tests

    @Test("KeyCodes constants are correct")
    func keyCodeConstants() {
        #expect(KeyCombo.KeyCodes.t == UInt32(kVK_ANSI_T))
        #expect(KeyCombo.KeyCodes.p == UInt32(kVK_ANSI_P))
        #expect(KeyCombo.KeyCodes.s == UInt32(kVK_ANSI_S))
        #expect(KeyCombo.KeyCodes.space == UInt32(kVK_Space))
        #expect(KeyCombo.KeyCodes.escape == UInt32(kVK_Escape))
    }
}
