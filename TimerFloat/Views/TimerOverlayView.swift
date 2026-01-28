import SwiftUI

/// Pin button overlay component
struct PinButtonOverlay: View {
    let isPinned: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            onTap()
        } label: {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .font(.system(size: 12))
                .foregroundStyle(isPinned ? Color.TimerFloat.warning : .secondary)
                .padding(6)
                .background(.ultraThinMaterial, in: Circle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? TimerDesign.pressScale : 1.0)
        .animation(TimerAnimations.press, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .help(isPinned ? "Unpin from window" : "Pin to window")
        .accessibilityLabel(isPinned ? "Unpin from window" : "Pin to window")
    }
}

/// Floating overlay view displaying the countdown timer
/// Uses TimelineView for smooth, frame-aligned updates
struct TimerOverlayView: View {
    /// The timer view model
    @Bindable var viewModel: TimerViewModel

    /// Base opacity when not hovered (from preferences)
    var idleOpacity: Double = 0.8

    /// Size of the circular progress indicator
    private let progressSize: CGFloat = TimerDesign.progressSize

    /// Line width for the progress ring
    private let progressLineWidth: CGFloat = TimerDesign.progressLineWidth

    /// Track hover state
    @State private var isHovered: Bool = false

    /// Whether to show window picker sheet
    @State private var showWindowPicker: Bool = false

    /// Current opacity based on hover state
    private var currentOpacity: Double {
        isHovered ? 1.0 : idleOpacity
    }

    var body: some View {
        ZStack {
            // Background with material effect
            RoundedRectangle(cornerRadius: TimerDesign.overlayCornerRadius)
                .fill(.regularMaterial)

            // Timer content
            VStack(spacing: 8) {
                // Circular progress indicator with time
                ZStack {
                    // Subtle tick marks
                    TickMarks(
                        count: 60,
                        radius: progressSize / 2 - 2,
                        color: .primary
                    )

                    // Background circle
                    Circle()
                        .stroke(Color.TimerFloat.ringBackground, lineWidth: progressLineWidth)
                        .frame(width: progressSize, height: progressSize)

                    // Tapered progress arc with gradient
                    TaperedProgressRing(
                        progress: viewModel.progress,
                        baseWidth: TimerDesign.progressLineWidthThick,
                        color: progressColor,
                        size: progressSize
                    )
                    .animation(TimerAnimations.progress, value: viewModel.progress)

                    // Glowing endpoint
                    if viewModel.progress > 0.01 && viewModel.isRunning {
                        ProgressEndpoint(
                            progress: viewModel.progress,
                            radius: progressSize / 2,
                            color: progressColor
                        )
                    }

                    // Time display using TimelineView for precise updates
                    TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                        Text(viewModel.formattedTime)
                            .font(TimerTypography.timeDisplay(size: 24))
                            .foregroundStyle(.primary)
                    }
                }

                // State indicator
                if viewModel.isPaused {
                    Label("Paused", systemImage: "pause.fill")
                        .font(.caption)
                        .foregroundStyle(Color.TimerFloat.warning)
                }
            }
            .padding(12)

            // Pin button (top-right corner, visible on hover)
            if isHovered {
                VStack {
                    HStack {
                        Spacer()
                        PinButtonOverlay(
                            isPinned: WindowPinningService.shared.isPinned,
                            onTap: onPinTap
                        )
                    }
                    Spacer()
                }
                .padding(4)
                .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .frame(width: TimerDesign.overlaySize, height: TimerDesign.overlaySize)
        .overlayShadow()
        .opacity(currentOpacity)
        .hoverScale(isHovered)
        .animation(TimerAnimations.hover, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .sheet(isPresented: $showWindowPicker) {
            WindowPickerView { window in
                WindowPinningService.shared.pinToWindow(window)
            }
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(viewModel.formattedTime)
        .accessibilityHint("Timer overlay. Drag to reposition.")
    }

    /// Handle pin button tap
    private func onPinTap() {
        if WindowPinningService.shared.isPinned {
            WindowPinningService.shared.unpin()
        } else {
            showWindowPicker = true
        }
    }

    /// Accessibility label based on timer state
    private var accessibilityLabel: String {
        if viewModel.isPaused {
            return "Timer paused"
        } else if viewModel.isRunning {
            return "Timer running"
        } else {
            return "Timer"
        }
    }

    /// Color for the progress ring based on timer state
    private var progressColor: Color {
        switch true {
        case viewModel.isCompleted:
            return Color.TimerFloat.complete
        case viewModel.isPaused:
            return Color.TimerFloat.warning
        case viewModel.progress > 0.9:
            return Color.TimerFloat.urgent
        case viewModel.progress > 0.75:
            return Color.TimerFloat.warning
        default:
            return Color.TimerFloat.primary
        }
    }
}

// MARK: - Completed State View

/// Animation phases for completion celebration
enum CompletionAnimationPhase: CaseIterable {
    case initial
    case burst
    case pulse1
    case pulse2
    case settle

    /// Scale factor for each phase
    var scale: CGFloat {
        switch self {
        case .initial: return 0.6
        case .burst: return 1.2
        case .pulse1: return 1.1
        case .pulse2: return 0.95
        case .settle: return 1.0
        }
    }

    /// Opacity for golden glow effect
    var glowOpacity: Double {
        switch self {
        case .initial: return 0
        case .burst: return 0.9
        case .pulse1: return 0.6
        case .pulse2: return 0.3
        case .settle: return 0.15
        }
    }

    /// Warm background tint opacity
    var warmBackgroundOpacity: Double {
        switch self {
        case .initial: return 0
        case .burst: return 0.4
        case .pulse1: return 0.3
        case .pulse2: return 0.15
        case .settle: return 0.05
        }
    }

    /// Rotation for checkmark entrance
    var rotation: Double {
        switch self {
        case .initial: return -45
        case .burst, .pulse1, .pulse2, .settle: return 0
        }
    }
}

/// View displayed when timer completes with celebration animation
struct TimerCompletedOverlayView: View {
    /// Whether animations are enabled (from preferences)
    var animationsEnabled: Bool = true

    /// Base opacity when not hovered (from preferences)
    var idleOpacity: Double = 0.8

    /// Callback when completion sound should play
    var onPlaySound: (() -> Void)?

    /// Track hover state
    @State private var isHovered: Bool = false

    /// Whether sound has been played
    @State private var soundPlayed: Bool = false

    /// Current opacity based on hover state
    private var currentOpacity: Double {
        isHovered ? 1.0 : idleOpacity
    }

    var body: some View {
        ZStack {
            // Warm glow background layer
            if animationsEnabled {
                RoundedRectangle(cornerRadius: TimerDesign.overlayCornerRadius)
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.TimerFloat.celebrationGlow.opacity(0.3),
                                Color.TimerFloat.celebrationWarm.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
            }

            // Background with material effect
            RoundedRectangle(cornerRadius: TimerDesign.overlayCornerRadius)
                .fill(.regularMaterial)

            if animationsEnabled {
                animatedContent
            } else {
                staticContent
            }
        }
        .frame(width: TimerDesign.overlaySize, height: TimerDesign.overlaySize)
        .overlayShadow()
        .opacity(currentOpacity)
        .hoverScale(isHovered)
        .animation(TimerAnimations.hover, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            if !soundPlayed {
                soundPlayed = true
                onPlaySound?()
            }
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Timer complete")
        .accessibilityHint("Your timer has finished.")
        .accessibilityAddTraits(.updatesFrequently)
    }

    /// Animated celebration content using PhaseAnimator
    @ViewBuilder
    private var animatedContent: some View {
        PhaseAnimator(CompletionAnimationPhase.allCases) { phase in
            ZStack {
                // Warm golden glow effect (casino-inspired)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.TimerFloat.celebrationGlow,
                                Color.TimerFloat.celebrationWarm.opacity(0.5),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                    .blur(radius: TimerDesign.celebrationGlowRadius)
                    .opacity(phase.glowOpacity)

                // Secondary emerald glow
                Circle()
                    .fill(Color.TimerFloat.complete.opacity(0.4))
                    .frame(width: 60, height: 60)
                    .blur(radius: 12)
                    .opacity(phase.glowOpacity * 0.7)

                VStack(spacing: 8) {
                    // Checkmark with golden accent
                    ZStack {
                        // Golden ring behind checkmark
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.TimerFloat.celebrationGlow,
                                        Color.TimerFloat.celebrationWarm
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 54, height: 54)
                            .opacity(phase.glowOpacity * 0.8)

                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.TimerFloat.complete)
                    }
                    .scaleEffect(phase.scale)
                    .rotationEffect(.degrees(phase.rotation))

                    Text("Complete!")
                        .font(TimerTypography.label(size: 14))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .opacity(phase == .initial ? 0 : 1)
                }
            }
            .padding(12)
        } animation: { phase in
            switch phase {
            case .initial:
                .easeOut(duration: 0.05)
            case .burst:
                .spring(response: 0.25, dampingFraction: 0.4)
            case .pulse1:
                .spring(response: 0.3, dampingFraction: 0.5)
            case .pulse2:
                .spring(response: 0.2, dampingFraction: 0.6)
            case .settle:
                .easeInOut(duration: 0.4)
            }
        }
    }

    /// Static content when animations are disabled
    private var staticContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(Color.TimerFloat.complete)

            Text("Complete!")
                .font(TimerTypography.label(size: 14))
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
        }
        .padding(12)
    }
}

// MARK: - Preview

#Preview("Running Timer") {
    @Previewable @State var viewModel = TimerViewModel()
    TimerOverlayView(viewModel: viewModel)
        .onAppear {
            viewModel.startTimer(minutes: 5)
        }
}

#Preview("Completed - Animated") {
    TimerCompletedOverlayView(animationsEnabled: true)
}

#Preview("Completed - Static") {
    TimerCompletedOverlayView(animationsEnabled: false)
}
