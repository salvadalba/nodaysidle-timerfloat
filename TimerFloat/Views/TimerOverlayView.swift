import SwiftUI

/// Floating overlay view displaying the countdown timer
/// Uses TimelineView for smooth, frame-aligned updates
struct TimerOverlayView: View {
    /// The timer view model
    @Bindable var viewModel: TimerViewModel

    /// Base opacity when not hovered (from preferences)
    var idleOpacity: Double = 0.8

    /// Size of the circular progress indicator
    private let progressSize: CGFloat = 100

    /// Line width for the progress ring
    private let progressLineWidth: CGFloat = 6

    /// Track hover state
    @State private var isHovered: Bool = false

    /// Current opacity based on hover state
    private var currentOpacity: Double {
        isHovered ? 1.0 : idleOpacity
    }

    var body: some View {
        ZStack {
            // Background with material effect
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)

            // Timer content
            VStack(spacing: 8) {
                // Circular progress indicator with time
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(Color.primary.opacity(0.1), lineWidth: progressLineWidth)
                        .frame(width: progressSize, height: progressSize)

                    // Progress arc
                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(
                            progressColor,
                            style: StrokeStyle(
                                lineWidth: progressLineWidth,
                                lineCap: .round
                            )
                        )
                        .frame(width: progressSize, height: progressSize)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: viewModel.progress)

                    // Time display using TimelineView for precise updates
                    TimelineView(.periodic(from: .now, by: 1.0)) { _ in
                        Text(viewModel.formattedTime)
                            .font(.system(size: 24, weight: .semibold, design: .monospaced))
                            .foregroundStyle(.primary)
                    }
                }

                // State indicator
                if viewModel.isPaused {
                    Label("Paused", systemImage: "pause.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
        }
        .frame(width: 120, height: 120)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .opacity(currentOpacity)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(viewModel.formattedTime)
        .accessibilityHint("Timer overlay. Drag to reposition.")
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
            return .green
        case viewModel.isPaused:
            return .orange
        case viewModel.progress > 0.9:
            return .red
        case viewModel.progress > 0.75:
            return .orange
        default:
            return .accentColor
        }
    }
}

// MARK: - Completed State View

/// Animation phases for completion celebration
enum CompletionAnimationPhase: CaseIterable {
    case initial
    case pulse1
    case pulse2
    case settle

    /// Scale factor for each phase
    var scale: CGFloat {
        switch self {
        case .initial: return 0.8
        case .pulse1: return 1.15
        case .pulse2: return 0.95
        case .settle: return 1.0
        }
    }

    /// Opacity for glow effect
    var glowOpacity: Double {
        switch self {
        case .initial: return 0
        case .pulse1: return 0.6
        case .pulse2: return 0.3
        case .settle: return 0
        }
    }

    /// Rotation for checkmark entrance
    var rotation: Double {
        switch self {
        case .initial: return -45
        case .pulse1, .pulse2, .settle: return 0
        }
    }
}

/// View displayed when timer completes with celebration animation
struct TimerCompletedOverlayView: View {
    /// Whether animations are enabled (from preferences)
    var animationsEnabled: Bool = true

    /// Base opacity when not hovered (from preferences)
    var idleOpacity: Double = 0.8

    /// Track hover state
    @State private var isHovered: Bool = false

    /// Current opacity based on hover state
    private var currentOpacity: Double {
        isHovered ? 1.0 : idleOpacity
    }

    var body: some View {
        ZStack {
            // Background with material effect
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)

            if animationsEnabled {
                animatedContent
            } else {
                staticContent
            }
        }
        .frame(width: 120, height: 120)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .opacity(currentOpacity)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
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
                // Glow effect behind the checkmark
                Circle()
                    .fill(.green.opacity(0.3))
                    .frame(width: 70, height: 70)
                    .blur(radius: 15)
                    .opacity(phase.glowOpacity)

                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                        .scaleEffect(phase.scale)
                        .rotationEffect(.degrees(phase.rotation))

                    Text("Complete!")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .opacity(phase == .initial ? 0 : 1)
                }
            }
            .padding(12)
        } animation: { phase in
            switch phase {
            case .initial:
                .easeOut(duration: 0.1)
            case .pulse1:
                .spring(response: 0.3, dampingFraction: 0.5)
            case .pulse2:
                .spring(response: 0.2, dampingFraction: 0.6)
            case .settle:
                .easeInOut(duration: 0.3)
            }
        }
    }

    /// Static content when animations are disabled
    private var staticContent: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Complete!")
                .font(.headline)
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
