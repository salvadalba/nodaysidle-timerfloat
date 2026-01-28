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
    @State private var headerButtonPressed: String?

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
            VStack(spacing: 16) {
                // Header with branding
                HStack(spacing: 8) {
                    // App icon/branding
                    Image(systemName: "timer.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color.TimerFloat.primary)

                    Text("TimerFloat")
                        .font(TimerTypography.label(size: 16))
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)

                    Spacer()

                    // Action buttons with press feedback
                    HStack(spacing: 4) {
                        PopoverIconButton(
                            systemName: "plus.circle",
                            isPressed: headerButtonPressed == "new",
                            action: {
                                headerButtonPressed = "new"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    headerButtonPressed = nil
                                }
                                spawnNewTimer()
                            },
                            help: "New Timer"
                        )

                        PopoverIconButton(
                            systemName: "gear",
                            isPressed: headerButtonPressed == "settings",
                            action: {
                                headerButtonPressed = "settings"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    headerButtonPressed = nil
                                }
                                showingSettings = true
                            },
                            help: "Settings"
                        )
                    }
                }

                Divider()
                    .padding(.horizontal, -16)

                // Timer state display or quick start buttons
                if appController.timerViewModel.isActive {
                    // Active timer controls
                    ActiveTimerView(appController: appController)
                } else {
                    // Quick start presets
                    QuickStartView(appController: appController)
                }
            }
            .padding(16)
            .frame(width: 240)
            .background(.ultraThinMaterial)
            .navigationDestination(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

/// Icon button with press feedback for popover
struct PopoverIconButton: View {
    let systemName: String
    let isPressed: Bool
    let action: () -> Void
    let help: String

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(Color.primary.opacity(isPressed ? 0.1 : 0))
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? TimerDesign.pressScale : 1.0)
        .animation(TimerAnimations.press, value: isPressed)
        .help(help)
        .accessibilityLabel(help)
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
        VStack(spacing: 0) {
            // Header with back button
            HStack {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption.weight(.semibold))
                        Text("Back")
                            .font(.subheadline)
                    }
                }
                .buttonStyle(.plain)
                .foregroundStyle(Color.TimerFloat.primary)

                Spacer()

                Image(systemName: "gearshape.fill")
                    .foregroundStyle(.secondary)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Notifications section
                    SettingsSection(title: "Notifications", icon: "bell.fill") {
                        NotificationPermissionRow()

                        SettingsToggle(
                            title: "Show alerts",
                            isOn: $notificationsEnabled,
                            onChange: { newValue in
                                try? preferencesService.updateNotificationsEnabled(newValue)
                            }
                        )

                        SettingsToggle(
                            title: "Play sound",
                            subtitle: "Celebration chime on completion",
                            isOn: $soundEnabled,
                            onChange: { newValue in
                                try? preferencesService.updateSoundEnabled(newValue)
                            }
                        )
                    }

                    // Timer section
                    SettingsSection(title: "Timer", icon: "timer") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Default duration")
                                    .font(.subheadline)
                                Text("For quick start")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Picker("", selection: $defaultDuration) {
                                Text("5 min").tag(5)
                                Text("15 min").tag(15)
                                Text("25 min").tag(25)
                                Text("45 min").tag(45)
                                Text("60 min").tag(60)
                            }
                            .labelsHidden()
                            .frame(width: 90)
                            .onChange(of: defaultDuration) { _, newValue in
                                try? preferencesService.updateDefaultDuration(newValue)
                            }
                        }
                    }

                    // Overlay section
                    SettingsSection(title: "Overlay", icon: "square.on.square") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Idle opacity")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(overlayOpacity * 100))%")
                                    .font(TimerTypography.label(size: 13))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            Slider(value: $overlayOpacity, in: 0.3...1.0, step: 0.1)
                                .tint(Color.TimerFloat.primary)
                                .onChange(of: overlayOpacity) { _, newValue in
                                    try? preferencesService.updateOverlayIdleOpacity(newValue)
                                }
                        }

                        SettingsToggle(
                            title: "Completion animations",
                            subtitle: "Celebratory effects when done",
                            isOn: $animationsEnabled,
                            onChange: { newValue in
                                try? preferencesService.updateAnimationsEnabled(newValue)
                            }
                        )

                        Button {
                            try? preferencesService.resetOverlayPosition()
                        } label: {
                            Label("Reset position", systemImage: "arrow.counterclockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }

                    // General section
                    SettingsSection(title: "General", icon: "gearshape") {
                        LaunchAtLoginToggle(isEnabled: $launchAtLogin)
                    }

                    // Hotkeys section
                    SettingsSection(title: "Shortcuts", icon: "keyboard") {
                        HotkeySettingsView()
                    }
                }
                .padding()
            }
        }
        .frame(width: 260, height: 480)
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

/// Settings toggle with optional subtitle
struct SettingsToggle: View {
    let title: String
    var subtitle: String? = nil
    @Binding var isOn: Bool
    let onChange: (Bool) -> Void

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
        .tint(Color.TimerFloat.primary)
        .onChange(of: isOn) { _, newValue in
            onChange(newValue)
        }
    }
}

/// Reusable settings section container
struct SettingsSection<Content: View>: View {
    let title: String
    var icon: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(Color.TimerFloat.primary.opacity(0.8))
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                content
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primary.opacity(0.03))
            )
        }
    }
}

/// View showing quick start timer presets and mode selection
struct QuickStartView: View {
    let appController: AppController
    @State private var selectedMode: TimerMode = .countdown

    var body: some View {
        VStack(spacing: 12) {
            // Mode picker with custom styling
            Picker("Mode", selection: $selectedMode) {
                ForEach(TimerMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.iconName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if selectedMode == .countdown {
                // Countdown section
                VStack(spacing: 10) {
                    // Section header
                    HStack {
                        Text("Quick Start")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    // Preset buttons in a grid
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            PresetButton(minutes: 5, appController: appController)
                            PresetButton(minutes: 15, appController: appController)
                        }

                        HStack(spacing: 8) {
                            PresetButton(minutes: 25, appController: appController, isPomodoro: true)
                            PresetButton(minutes: 45, appController: appController)
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.03))
                )

                // Custom duration section
                VStack(spacing: 10) {
                    HStack {
                        Text("Custom")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }

                    CustomDurationInputView(appController: appController)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.03))
                )
            } else {
                // Stopwatch section
                VStack(spacing: 16) {
                    // Stopwatch illustration
                    ZStack {
                        Circle()
                            .fill(Color.TimerFloat.stopwatch.opacity(0.1))
                            .frame(width: 70, height: 70)

                        Image(systemName: "stopwatch.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color.TimerFloat.stopwatch)
                    }

                    Text("Track elapsed time")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button {
                        appController.startStopwatch()
                    } label: {
                        Label("Start Stopwatch", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 2)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color.TimerFloat.stopwatch)
                    .accessibilityLabel("Start stopwatch")
                    .accessibilityHint("Starts counting time from zero")
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primary.opacity(0.03))
                )
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
    var isPomodoro: Bool = false

    @State private var isPressed = false

    var body: some View {
        Button {
            appController.startTimer(minutes: minutes)
        } label: {
            VStack(spacing: 2) {
                Text("\(minutes)m")
                    .font(TimerTypography.label(size: 15))
                    .fontWeight(.semibold)

                if isPomodoro {
                    Text("Pomodoro")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, isPomodoro ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: TimerDesign.buttonCornerRadius)
                    .fill(Color.TimerFloat.primary)
            )
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? TimerDesign.pressScale : 1.0)
        .animation(TimerAnimations.press, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .accessibilityLabel("Start \(minutes) minute timer")
        .accessibilityHint("Starts a \(minutes) minute countdown timer")
    }
}

/// View showing active timer controls
struct ActiveTimerView: View {
    let appController: AppController
    @State private var showWindowPicker: Bool = false
    @State private var pauseButtonPressed = false
    @State private var cancelButtonPressed = false

    private var isStopwatch: Bool {
        appController.timerViewModel.isStopwatch
    }

    private var accentColor: Color {
        isStopwatch ? Color.TimerFloat.stopwatch : Color.TimerFloat.primary
    }

    var body: some View {
        VStack(spacing: 14) {
            // Mode indicator with icon
            HStack(spacing: 6) {
                Image(systemName: isStopwatch ? "stopwatch.fill" : "timer")
                    .font(.caption)
                    .foregroundStyle(accentColor)
                Text(isStopwatch ? "Stopwatch" : "Countdown")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(accentColor.opacity(0.1))
            )

            // Time display
            if isStopwatch {
                Text(appController.timerViewModel.formattedTimeWithMillis)
                    .font(TimerTypography.timeMedium(size: 28))
                    .foregroundStyle(.primary)
                    .accessibilityLabel("Time elapsed")
                    .accessibilityValue(appController.timerViewModel.formattedTime)
            } else {
                Text(appController.timerViewModel.formattedTime)
                    .font(TimerTypography.timeLarge(size: 32))
                    .foregroundStyle(timerTextColor)
                    .accessibilityLabel("Time remaining")
                    .accessibilityValue(appController.timerViewModel.formattedTime)

                // Progress bar with gradient
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.primary.opacity(0.1))
                            .frame(height: 6)

                        // Progress fill
                        RoundedRectangle(cornerRadius: 3)
                            .fill(progressGradient)
                            .frame(width: geometry.size.width * appController.timerViewModel.progress, height: 6)
                            .animation(.linear(duration: 0.1), value: appController.timerViewModel.progress)
                    }
                }
                .frame(height: 6)
                .accessibilityLabel("Timer progress")
                .accessibilityValue("\(Int(appController.timerViewModel.progress * 100)) percent complete")
            }

            // Control buttons with press feedback
            HStack(spacing: 12) {
                // Pause/Resume button
                Button {
                    appController.toggleTimer()
                } label: {
                    Image(systemName: appController.timerViewModel.isRunning ? "pause.fill" : "play.fill")
                        .font(.title2)
                        .frame(width: 44, height: 36)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentColor)
                .scaleEffect(pauseButtonPressed ? TimerDesign.pressScale : 1.0)
                .animation(TimerAnimations.press, value: pauseButtonPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in pauseButtonPressed = true }
                        .onEnded { _ in pauseButtonPressed = false }
                )
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
                        .frame(width: 44, height: 36)
                }
                .buttonStyle(.bordered)
                .scaleEffect(cancelButtonPressed ? TimerDesign.pressScale : 1.0)
                .animation(TimerAnimations.press, value: cancelButtonPressed)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in cancelButtonPressed = true }
                        .onEnded { _ in cancelButtonPressed = false }
                )
                .accessibilityLabel(isStopwatch ? "Stop stopwatch" : "Cancel timer")
            }

            Divider()
                .padding(.horizontal, -16)

            // Pin status section
            HStack {
                if WindowPinningService.shared.isPinned {
                    HStack(spacing: 4) {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                        Text("Pinned")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(Color.TimerFloat.warning)

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
                            .font(.caption)
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

    /// Text color based on progress
    private var timerTextColor: Color {
        let progress = appController.timerViewModel.progress
        switch progress {
        case 0.9...:
            return Color.TimerFloat.urgent
        case 0.75..<0.9:
            return Color.TimerFloat.warning
        default:
            return .primary
        }
    }

    /// Gradient for progress bar
    private var progressGradient: LinearGradient {
        LinearGradient.timerProgress(progress: appController.timerViewModel.progress)
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
