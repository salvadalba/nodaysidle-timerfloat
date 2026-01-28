import AppKit
import AVFoundation
import os

/// Service for playing UI sounds
/// Provides completion celebration sounds and optional tick sounds
@MainActor
final class SoundService {
    /// Shared singleton instance
    static let shared = SoundService()

    /// Logger for sound operations
    private let logger = Logger(subsystem: "com.timerfloat", category: "sound")

    /// Audio player for completion sound
    private var completionPlayer: AVAudioPlayer?

    /// Audio player for tick sound
    private var tickPlayer: AVAudioPlayer?

    /// Whether sounds are enabled
    var soundEnabled: Bool = true

    private init() {
        setupSounds()
    }

    /// Setup audio players with system sounds
    private func setupSounds() {
        // Use system sounds for reliability
        // NSSound names: "Glass", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
        // "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"
    }

    /// Play the completion celebration sound (casino cha-ching style)
    /// Uses a quick sequence of sounds for the jackpot effect
    func playCompletionSound() {
        guard soundEnabled else { return }

        // Play system sounds in quick succession for "cha-ching" effect
        // Using Glass and Hero for a rewarding, casino-like feel
        Task {
            // First chime
            playSystemSound("Glass")

            // Short delay
            try? await Task.sleep(for: .milliseconds(80))

            // Second chime (the "ching" part)
            playSystemSound("Hero")
        }

        logger.debug("Playing completion celebration sound")
    }

    /// Play a subtle tick sound (optional, for second updates)
    func playTickSound() {
        guard soundEnabled else { return }
        playSystemSound("Tink")
    }

    /// Play a system sound by name
    private func playSystemSound(_ name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }

    /// Play a custom sound from bundle
    func playCustomSound(named filename: String, type: String = "wav") {
        guard soundEnabled else { return }

        guard let url = Bundle.main.url(forResource: filename, withExtension: type) else {
            logger.warning("Sound file not found: \(filename).\(type)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.play()
        } catch {
            logger.error("Failed to play sound: \(error.localizedDescription)")
        }
    }
}
