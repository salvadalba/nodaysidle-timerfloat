import SwiftUI
import Observation

/// Main application controller coordinating timer and overlay
@MainActor
@Observable
final class AppController {
    /// Shared instance for app-wide access
    static let shared = AppController()

    /// The timer view model
    let timerViewModel = TimerViewModel()

    /// Reference to window service
    private let windowService = WindowService.shared

    /// Reference to hotkey service
    private let hotkeyService = HotkeyService.shared

    /// Reference to notification service
    private let notificationService = NotificationService.shared

    /// Reference to metrics service
    private let metricsService = MetricsService.shared

    /// Task for observing timer state changes
    nonisolated(unsafe) private var stateObservationTask: Task<Void, Never>?

    /// Track previous state to detect transitions
    private var previousState: TimerState = .idle

    /// Store the total duration for notification
    private var lastTimerDuration: TimeInterval = 0

    private init() {
        startObservingTimerState()
        setupHotkeys()
    }

    deinit {
        stateObservationTask?.cancel()
    }

    // MARK: - Timer Actions

    /// Start a timer with the given duration in minutes
    func startTimer(minutes: Int) {
        lastTimerDuration = TimeInterval(minutes * 60)
        timerViewModel.startTimer(minutes: minutes)
        metricsService.recordTimerStart(duration: lastTimerDuration)
        showOverlay()
    }

    /// Start a timer with the given duration in seconds
    func startTimer(seconds: TimeInterval) {
        lastTimerDuration = seconds
        timerViewModel.startTimer(duration: seconds)
        metricsService.recordTimerStart(duration: lastTimerDuration)
        showOverlay()
    }

    /// Pause the current timer
    func pauseTimer() {
        timerViewModel.pauseTimer()
    }

    /// Resume the paused timer
    func resumeTimer() {
        timerViewModel.resumeTimer()
    }

    /// Cancel the current timer
    func cancelTimer() {
        // Only record cancellation if timer was actually active
        if timerViewModel.isActive {
            metricsService.recordTimerCancellation()
        }
        timerViewModel.cancelTimer()
        hideOverlay()
    }

    /// Toggle timer pause/resume
    func toggleTimer() {
        timerViewModel.toggleTimer()
    }

    // MARK: - Overlay Management

    /// Show the timer overlay
    func showOverlay() {
        let idleOpacity = PreferencesService.shared.preferences?.overlayIdleOpacity ?? 0.8
        windowService.showOverlay(with: TimerOverlayView(viewModel: timerViewModel, idleOpacity: idleOpacity))
    }

    /// Hide the timer overlay
    func hideOverlay() {
        windowService.hideOverlay()
    }

    /// Update the overlay content
    func updateOverlay() {
        if windowService.isVisible {
            let idleOpacity = PreferencesService.shared.preferences?.overlayIdleOpacity ?? 0.8
            windowService.updateContent(TimerOverlayView(viewModel: timerViewModel, idleOpacity: idleOpacity))
        }
    }

    // MARK: - Hotkey Setup

    /// Set up global hotkeys and their callbacks
    private func setupHotkeys() {
        // Set up callback for hotkey events (do this regardless of permission)
        hotkeyService.onHotkeyPressed = { [weak self] action in
            guard let self else { return }
            self.handleHotkeyAction(action)
        }

        // Start monitoring for accessibility permission changes
        startMonitoringAccessibilityPermission()

        // Try to register hotkeys if permission is already granted
        tryRegisterHotkeys()
    }

    /// Attempt to register hotkeys if accessibility permission is granted
    func tryRegisterHotkeys() {
        guard HotkeyService.hasAccessibilityPermission else {
            Log.hotkey.info("Cannot register hotkeys - no accessibility permission")
            return
        }

        // Register default hotkeys
        hotkeyService.registerDefaultHotkeys()
        Log.hotkey.info("Hotkeys registered and connected to timer actions")
    }

    /// Monitor for accessibility permission changes
    private func startMonitoringAccessibilityPermission() {
        // Poll for permission changes periodically
        // (There's no reliable notification for accessibility permission changes)
        Task {
            var wasGranted = HotkeyService.hasAccessibilityPermission

            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))

                let isGranted = HotkeyService.hasAccessibilityPermission
                if isGranted && !wasGranted {
                    Log.hotkey.info("Accessibility permission granted - registering hotkeys")
                    await MainActor.run {
                        self.tryRegisterHotkeys()
                    }
                }
                wasGranted = isGranted
            }
        }
    }

    /// Handle a hotkey action
    private func handleHotkeyAction(_ action: HotkeyAction) {
        Log.hotkey.debug("Handling hotkey action: \(action.rawValue)")

        switch action {
        case .toggleTimer:
            if timerViewModel.isActive {
                cancelTimer()
            } else {
                // Start with default duration from preferences
                let duration = PreferencesService.shared.preferences?.defaultDurationMinutes ?? 25
                startTimer(minutes: duration)
            }

        case .pauseResume:
            if timerViewModel.isActive {
                toggleTimer()
            }

        case .cancelTimer:
            if timerViewModel.isActive {
                cancelTimer()
            }

        case .showOverlay:
            if timerViewModel.isActive {
                showOverlay()
            }
        }
    }

    // MARK: - Private

    /// Observe timer state to manage overlay visibility
    private func startObservingTimerState() {
        stateObservationTask = Task { [weak self] in
            guard let self else { return }

            // Simple polling approach to check timer state
            while !Task.isCancelled {
                await self.handleTimerStateChange()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    /// Handle timer state changes
    private func handleTimerStateChange() {
        let state = timerViewModel.state

        // Detect transition to completed state
        let justCompleted = state.isCompleted && !previousState.isCompleted
        previousState = state

        switch state {
        case .completed:
            // Show completed state briefly then hide
            let animationsEnabled = PreferencesService.shared.preferences?.animationsEnabled ?? true
            let idleOpacity = PreferencesService.shared.preferences?.overlayIdleOpacity ?? 0.8
            windowService.updateContent(TimerCompletedOverlayView(animationsEnabled: animationsEnabled, idleOpacity: idleOpacity))

            // Send notification and record metrics if just completed
            if justCompleted {
                metricsService.recordTimerCompletion()
                sendCompletionNotification()
            }

            Task {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run {
                    if self.timerViewModel.isCompleted {
                        self.hideOverlay()
                        self.timerViewModel.resetTimer()
                    }
                }
            }
        case .idle:
            // Hide overlay when idle
            if windowService.isVisible {
                hideOverlay()
            }
        case .running, .paused:
            // Ensure overlay is showing
            if !windowService.isVisible {
                showOverlay()
            }
        }
    }

    /// Send notification when timer completes
    private func sendCompletionNotification() {
        Task {
            do {
                try await notificationService.sendTimerCompletedNotification(duration: lastTimerDuration)
                Log.notification.info("Timer completion notification sent")
            } catch {
                Log.notification.error("Failed to send completion notification: \(error)")
            }
        }
    }
}
