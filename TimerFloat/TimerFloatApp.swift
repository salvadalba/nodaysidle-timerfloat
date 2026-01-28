import SwiftUI

/// TimerFloat - A minimalist floating timer for macOS
/// Main application entry point using SwiftUI App lifecycle
@main
struct TimerFloatApp: App {
    /// Shared app controller
    @State private var appController = AppController.shared

    var body: some Scene {
        MenuBarExtra {
            MenuPopoverView(appController: appController)
        } label: {
            MenuBarIcon(timerViewModel: appController.timerViewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

/// Dynamic menu bar icon that reflects timer state
struct MenuBarIcon: View {
    let timerViewModel: TimerViewModel

    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.hierarchical)
            .accessibilityLabel(accessibilityLabel)
    }

    /// Icon name based on timer state
    private var iconName: String {
        switch timerViewModel.state {
        case .idle:
            return "timer.circle"
        case .running, .stopwatchRunning:
            return "timer.circle.fill"
        case .paused, .stopwatchPaused:
            return "pause.circle.fill"
        case .completed:
            return "checkmark.circle.fill"
        }
    }

    /// Accessibility label based on timer state
    private var accessibilityLabel: String {
        switch timerViewModel.state {
        case .idle:
            return "TimerFloat, no timer running"
        case .running:
            return "TimerFloat, timer running, \(timerViewModel.formattedTime) remaining"
        case .paused:
            return "TimerFloat, timer paused, \(timerViewModel.formattedTime) remaining"
        case .completed:
            return "TimerFloat, timer complete"
        case .stopwatchRunning:
            return "TimerFloat, stopwatch running, \(timerViewModel.formattedTime) elapsed"
        case .stopwatchPaused:
            return "TimerFloat, stopwatch paused, \(timerViewModel.formattedTime) elapsed"
        }
    }
}

/// Menu bar popover view with timer controls
struct MenuPopoverView: View {
    let appController: AppController
    @State private var showingSettings = false

    /// Spawn a new TimerFloat instance
    private func spawnNewTimer() {
        if let appURL = Bundle.main.bundleURL as URL? {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = true
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
                if let error {
                    Log.app.error("Failed to spawn new timer: \(error.localizedDescription)")
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                // Header
                HStack {
                    Text("TimerFloat")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Button {
                        spawnNewTimer()
                    } label: {
                        Image(systemName: "plus.circle")
                            .font(.body)
                    }
                    .buttonStyle(.borderless)
                    .help("New Timer")
                    .accessibilityLabel("New Timer")
                    .accessibilityHint("Opens a new TimerFloat instance")

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .font(.body)
                    }
                    .buttonStyle(.borderless)
                    .help("Settings")
                    .accessibilityLabel("Settings")
                    .accessibilityHint("Opens the settings panel")
                }

                Divider()

                // Timer state display or quick start buttons
                if appController.timerViewModel.isActive {
                    // Active timer controls
                    ActiveTimerView(appController: appController)
                } else {
                    // Quick start presets
                    QuickStartView(appController: appController)
                }
            }
            .padding()
            .frame(width: 200)
            .background(.ultraThinMaterial)
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

/// Settings view for user preferences
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    /// Preferences service
    private let preferencesService = PreferencesService.shared

    /// Local state for toggles (synced with preferences)
    @State private var notificationsEnabled: Bool = true
    @State private var soundEnabled: Bool = true
    @State private var launchAtLogin: Bool = false
    @State private var defaultDuration: Int = 25
    @State private var overlayOpacity: Double = 0.8
    @State private var animationsEnabled: Bool = true

    var body: some View {
        VStack(spacing: 12) {
            // Header with back button
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
                .buttonStyle(.borderless)
                Spacer()
            }

            Text("Settings")
                .font(.headline)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Notifications section
                    SettingsSection(title: "Notifications") {
                        NotificationPermissionRow()

                        Toggle("Show alerts", isOn: $notificationsEnabled)
                            .onChange(of: notificationsEnabled) { _, newValue in
                                try? preferencesService.updateNotificationsEnabled(newValue)
                            }

                        Toggle("Play sound", isOn: $soundEnabled)
                            .onChange(of: soundEnabled) { _, newValue in
                                try? preferencesService.updateSoundEnabled(newValue)
                            }
                    }

                    // Timer section
                    SettingsSection(title: "Timer") {
                        HStack {
                            Text("Default duration")
                            Spacer()
                            Picker("", selection: $defaultDuration) {
                                Text("5 min").tag(5)
                                Text("15 min").tag(15)
                                Text("25 min").tag(25)
                                Text("45 min").tag(45)
                                Text("60 min").tag(60)
                            }
                            .labelsHidden()
                            .frame(width: 80)
                            .onChange(of: defaultDuration) { _, newValue in
                                try? preferencesService.updateDefaultDuration(newValue)
                            }
                        }
                    }

                    // Overlay section
                    SettingsSection(title: "Overlay") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Idle opacity: \(Int(overlayOpacity * 100))%")
                                .font(.caption)
                            Slider(value: $overlayOpacity, in: 0.3...1.0, step: 0.1)
                                .onChange(of: overlayOpacity) { _, newValue in
                                    try? preferencesService.updateOverlayIdleOpacity(newValue)
                                }
                        }

                        Toggle("Completion animations", isOn: $animationsEnabled)
                            .onChange(of: animationsEnabled) { _, newValue in
                                try? preferencesService.updateAnimationsEnabled(newValue)
                            }

                        Button("Reset position") {
                            try? preferencesService.resetOverlayPosition()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    // General section
                    SettingsSection(title: "General") {
                        LaunchAtLoginToggle(isEnabled: $launchAtLogin)
                    }

                    // Hotkeys section
                    SettingsSection(title: "Keyboard Shortcuts") {
                        HotkeySettingsView()
                    }
                }
            }
        }
        .padding()
        .frame(width: 220, height: 420)
        .background(.ultraThinMaterial)
        .onAppear {
            loadPreferences()
        }
    }

    /// Load current preferences into local state
    private func loadPreferences() {
        guard let prefs = preferencesService.preferences else { return }
        notificationsEnabled = prefs.notificationsEnabled
        soundEnabled = prefs.soundEnabled
        launchAtLogin = prefs.launchAtLogin
        defaultDuration = prefs.defaultDurationMinutes
        overlayOpacity = prefs.overlayIdleOpacity
        animationsEnabled = prefs.animationsEnabled
    }
}

/// Reusable settings section container
struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                content
            }
        }
    }
}

/// View showing quick start timer presets and mode selection
struct QuickStartView: View {
    let appController: AppController
    @State private var selectedMode: TimerMode = .countdown

    var body: some View {
        VStack(spacing: 8) {
            // Mode picker
            Picker("Mode", selection: $selectedMode) {
                ForEach(TimerMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if selectedMode == .countdown {
                // Countdown preset buttons
                Text("Quick Start")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    PresetButton(minutes: 5, appController: appController)
                    PresetButton(minutes: 15, appController: appController)
                }

                HStack(spacing: 8) {
                    PresetButton(minutes: 25, appController: appController)
                    PresetButton(minutes: 45, appController: appController)
                }

                Divider()

                // Custom duration input
                CustomDurationInputView(appController: appController)
            } else {
                // Stopwatch start button
                VStack(spacing: 12) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)

                    Button {
                        appController.startStopwatch()
                    } label: {
                        Text("Start Stopwatch")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Start stopwatch")
                    .accessibilityHint("Starts counting time from zero")
                }
                .padding(.vertical, 8)
            }
        }
    }
}

/// View for custom duration input with validation
struct CustomDurationInputView: View {
    let appController: AppController

    @State private var durationText: String = ""
    @State private var isInvalid: Bool = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("Custom")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                TextField("min", text: $durationText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .focused($isTextFieldFocused)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isInvalid ? Color.red : Color.clear, lineWidth: 1)
                    )
                    .onSubmit {
                        startCustomTimer()
                    }
                    .onChange(of: durationText) { _, newValue in
                        // Reset invalid state when user types
                        if isInvalid {
                            isInvalid = false
                        }
                        // Filter to only allow numeric input
                        let filtered = newValue.filter { $0.isNumber }
                        if filtered != newValue {
                            durationText = filtered
                        }
                    }
                    .accessibilityLabel("Custom duration in minutes")
                    .accessibilityHint("Enter the number of minutes for your timer")

                Button {
                    startCustomTimer()
                } label: {
                    Text("Start")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(durationText.isEmpty)
                .accessibilityLabel("Start custom timer")
                .accessibilityHint(durationText.isEmpty ? "Enter a duration first" : "Starts a \(durationText) minute timer")
            }

            if isInvalid {
                Text("Enter a valid number")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .accessibilityLabel("Error: Enter a valid number")
            }
        }
    }

    /// Validates input and starts the timer
    private func startCustomTimer() {
        guard let minutes = Int(durationText), minutes > 0 else {
            isInvalid = true
            return
        }

        appController.startTimer(minutes: minutes)
        durationText = ""
        isInvalid = false
    }
}

/// Button for starting a preset timer duration
struct PresetButton: View {
    let minutes: Int
    let appController: AppController

    var body: some View {
        Button {
            appController.startTimer(minutes: minutes)
        } label: {
            Text("\(minutes)m")
                .font(.system(.body, design: .rounded, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.borderedProminent)
        .accessibilityLabel("Start \(minutes) minute timer")
        .accessibilityHint("Starts a \(minutes) minute countdown timer")
    }
}

/// View showing active timer controls
struct ActiveTimerView: View {
    let appController: AppController
    @State private var showWindowPicker: Bool = false

    private var isStopwatch: Bool {
        appController.timerViewModel.isStopwatch
    }

    var body: some View {
        VStack(spacing: 12) {
            // Mode indicator
            Label(
                isStopwatch ? "Stopwatch" : "Timer",
                systemImage: isStopwatch ? "stopwatch.fill" : "timer"
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            // Time display
            if isStopwatch {
                Text(appController.timerViewModel.formattedTimeWithMillis)
                    .font(.system(size: 28, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Time elapsed")
                    .accessibilityValue(appController.timerViewModel.formattedTime)
            } else {
                Text(appController.timerViewModel.formattedTime)
                    .font(.system(size: 32, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Time remaining")
                    .accessibilityValue(appController.timerViewModel.formattedTime)

                // Progress bar (countdown only)
                ProgressView(value: appController.timerViewModel.progress)
                    .progressViewStyle(.linear)
                    .accessibilityLabel("Timer progress")
                    .accessibilityValue("\(Int(appController.timerViewModel.progress * 100)) percent complete")
            }

            // Control buttons
            HStack(spacing: 12) {
                // Pause/Resume button
                Button {
                    appController.toggleTimer()
                } label: {
                    Image(systemName: appController.timerViewModel.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(appController.timerViewModel.isRunning ? "Pause" : "Resume")

                // Stop/Cancel button
                Button(role: .destructive) {
                    if isStopwatch {
                        appController.stopStopwatch()
                    } else {
                        appController.cancelTimer()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.title2)
                }
                .buttonStyle(.bordered)
                .accessibilityLabel(isStopwatch ? "Stop stopwatch" : "Cancel timer")
            }

            Divider()

            // Pin status
            HStack {
                if WindowPinningService.shared.isPinned {
                    Label("Pinned", systemImage: "pin.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)

                    Spacer()

                    Button("Unpin") {
                        WindowPinningService.shared.unpin()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Button {
                        showWindowPicker = true
                    } label: {
                        Label("Pin to Window", systemImage: "pin")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .sheet(isPresented: $showWindowPicker) {
                WindowPickerView { window in
                    WindowPinningService.shared.pinToWindow(window)
                }
            }
        }
    }
}

// MARK: - Hotkey Settings

/// View for configuring keyboard shortcuts
struct HotkeySettingsView: View {
    @State private var hasAccessibility = HotkeyService.hasAccessibilityPermission
    @State private var toggleHotkey: KeyCombo? = .defaultToggle
    @State private var pauseHotkey: KeyCombo? = .defaultPause
    @State private var recordingAction: HotkeyAction?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !hasAccessibility {
                // Accessibility permission prompt
                AccessibilityPermissionView(hasAccessibility: $hasAccessibility)
            } else {
                // Hotkey rows
                HotkeyRow(
                    label: "Toggle timer",
                    keyCombo: toggleHotkey,
                    isRecording: recordingAction == .toggleTimer,
                    onRecord: { startRecording(.toggleTimer) },
                    onClear: { clearHotkey(.toggleTimer) }
                )

                HotkeyRow(
                    label: "Pause/Resume",
                    keyCombo: pauseHotkey,
                    isRecording: recordingAction == .pauseResume,
                    onRecord: { startRecording(.pauseResume) },
                    onClear: { clearHotkey(.pauseResume) }
                )
            }
        }
        .onAppear {
            hasAccessibility = HotkeyService.hasAccessibilityPermission
        }
    }

    private func startRecording(_ action: HotkeyAction) {
        recordingAction = action
        // Note: Full recording implementation requires NSEvent monitoring
        // For now, we use default hotkeys
    }

    private func clearHotkey(_ action: HotkeyAction) {
        switch action {
        case .toggleTimer:
            toggleHotkey = nil
            try? HotkeyService.shared.unregisterHotkey(for: .toggleTimer)
        case .pauseResume:
            pauseHotkey = nil
            try? HotkeyService.shared.unregisterHotkey(for: .pauseResume)
        default:
            break
        }
    }
}

/// Row displaying a single hotkey configuration
struct HotkeyRow: View {
    let label: String
    let keyCombo: KeyCombo?
    let isRecording: Bool
    let onRecord: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)

            Spacer()

            if isRecording {
                Text("Press keys...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary)
                    .cornerRadius(4)
            } else if let combo = keyCombo {
                Button {
                    onRecord()
                } label: {
                    Text(combo.displayString)
                        .font(.system(.caption, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .controlSize(.small)
            } else {
                Button("Set") {
                    onRecord()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}

/// Row showing notification permission status
struct NotificationPermissionRow: View {
    @State private var permissionStatus: String = "Checking..."
    @State private var isAuthorized = false
    @State private var isRequesting = false

    var body: some View {
        HStack {
            if isAuthorized {
                Label("Notifications enabled", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                    Text(permissionStatus)
                        .font(.caption)
                }

                Spacer()

                Button {
                    requestPermission()
                } label: {
                    if isRequesting {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Text("Enable")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isRequesting)
            }
        }
        .task {
            await checkPermission()
        }
    }

    private func checkPermission() async {
        let status = await NotificationService.shared.authorizationStatus
        await MainActor.run {
            switch status {
            case .authorized, .provisional:
                isAuthorized = true
                permissionStatus = "Enabled"
            case .denied:
                isAuthorized = false
                permissionStatus = "Denied"
            case .notDetermined:
                isAuthorized = false
                permissionStatus = "Not enabled"
            @unknown default:
                isAuthorized = false
                permissionStatus = "Unknown"
            }
        }
    }

    private func requestPermission() {
        isRequesting = true
        Task {
            do {
                let granted = try await NotificationService.shared.requestAuthorization()
                await MainActor.run {
                    isAuthorized = granted
                    permissionStatus = granted ? "Enabled" : "Denied"
                    isRequesting = false
                }
            } catch {
                await MainActor.run {
                    permissionStatus = "Error"
                    isRequesting = false
                }
            }
        }
    }
}

/// View prompting for accessibility permission
struct AccessibilityPermissionView: View {
    @Binding var hasAccessibility: Bool
    @State private var isChecking = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
                Text("Accessibility access required")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Global hotkeys need accessibility permission to work.")
                .font(.caption2)
                .foregroundStyle(.tertiary)

            HStack(spacing: 8) {
                Button("Open Settings") {
                    openAccessibilitySettings()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    checkPermission()
                } label: {
                    if isChecking {
                        ProgressView()
                            .scaleEffect(0.6)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isChecking)
            }
        }
    }

    private func openAccessibilitySettings() {
        // Request permission (shows system dialog)
        HotkeyService.requestAccessibilityPermission()

        // Also open System Settings directly
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    private func checkPermission() {
        isChecking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            hasAccessibility = HotkeyService.hasAccessibilityPermission
            isChecking = false

            // If permission granted, register hotkeys
            if hasAccessibility {
                AppController.shared.tryRegisterHotkeys()
            }
        }
    }
}

// MARK: - Launch at Login Toggle

/// Toggle for launch at login with SMAppService integration
struct LaunchAtLoginToggle: View {
    @Binding var isEnabled: Bool
    @State private var isUpdating = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let launchService = LaunchAtLoginService.shared
    private let preferencesService = PreferencesService.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Toggle("Launch at login", isOn: $isEnabled)
                    .disabled(isUpdating)
                    .onChange(of: isEnabled) { _, newValue in
                        updateLaunchAtLogin(newValue)
                    }

                if isUpdating {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }

            if showError {
                Text(errorMessage)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
        }
        .onAppear {
            // Sync with actual status
            isEnabled = launchService.isEnabled
        }
    }

    private func updateLaunchAtLogin(_ enabled: Bool) {
        isUpdating = true
        showError = false

        do {
            try launchService.setEnabled(enabled)
            try preferencesService.updateLaunchAtLogin(enabled)
        } catch {
            // Revert the toggle
            isEnabled = launchService.isEnabled
            errorMessage = "Failed to update: \(error.localizedDescription)"
            showError = true
        }

        isUpdating = false
    }
}
