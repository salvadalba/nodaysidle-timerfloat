import SwiftUI

/// Floating overlay view displaying the stopwatch
/// Uses a distinct pill shape and teal color to differentiate from countdown timer
struct StopwatchOverlayView: View {
    /// The timer view model
    @Bindable var viewModel: TimerViewModel

    /// Base opacity when not hovered (from preferences)
    var idleOpacity: Double = 0.8

    /// Track hover state
    @State private var isHovered: Bool = false

    /// Whether to show window picker sheet
    @State private var showWindowPicker: Bool = false

    /// Animated pulse for running state
    @State private var isPulsing: Bool = false

    /// Current opacity based on hover state
    private var currentOpacity: Double {
        isHovered ? 1.0 : idleOpacity
    }

    var body: some View {
        ZStack {
            // Subtle teal tint background layer
            RoundedRectangle(cornerRadius: TimerDesign.stopwatchCornerRadius)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.TimerFloat.stopwatch.opacity(0.08),
                            Color.TimerFloat.stopwatchLight.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Background with material effect
            RoundedRectangle(cornerRadius: TimerDesign.stopwatchCornerRadius)
                .fill(.regularMaterial)

            // Stopwatch content
            HStack(spacing: 12) {
                // Animated stopwatch icon
                ZStack {
                    // Glow effect when running
                    if viewModel.isRunning {
                        Circle()
                            .fill(Color.TimerFloat.stopwatch.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .blur(radius: 8)
                            .scaleEffect(isPulsing ? 1.2 : 1.0)
                    }

                    // Stopwatch icon with teal accent
                    Image(systemName: viewModel.isRunning ? "stopwatch.fill" : "stopwatch")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(
                            viewModel.isRunning
                                ? Color.TimerFloat.stopwatch
                                : .secondary
                        )
                        .symbolEffect(.pulse, options: .repeating, isActive: viewModel.isRunning)
                }
                .frame(width: 44, height: 44)

                // Time display with centiseconds
                VStack(alignment: .leading, spacing: 2) {
                    TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                        Text(viewModel.formattedTimeWithMillis)
                            .font(TimerTypography.stopwatchDisplay(size: 22))
                            .foregroundStyle(.primary)
                            .monospacedDigit()
                    }

                    // State indicator
                    if viewModel.isPaused {
                        Label("Paused", systemImage: "pause.fill")
                            .font(.caption2)
                            .foregroundStyle(Color.TimerFloat.warning)
                    } else if viewModel.isRunning {
                        Text("Running")
                            .font(.caption2)
                            .foregroundStyle(Color.TimerFloat.stopwatch)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

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
        .frame(width: TimerDesign.stopwatchWidth, height: TimerDesign.stopwatchHeight)
        .overlayShadow()
        .opacity(currentOpacity)
        .hoverScale(isHovered)
        .animation(TimerAnimations.hover, value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            // Start subtle pulse animation
            withAnimation(TimerAnimations.glowPulse) {
                isPulsing = true
            }
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
        .accessibilityHint("Stopwatch overlay. Drag to reposition.")
    }

    /// Handle pin button tap
    private func onPinTap() {
        if WindowPinningService.shared.isPinned {
            WindowPinningService.shared.unpin()
        } else {
            showWindowPicker = true
        }
    }

    /// Accessibility label based on stopwatch state
    private var accessibilityLabel: String {
        if viewModel.isPaused {
            return "Stopwatch paused"
        } else if viewModel.isRunning {
            return "Stopwatch running"
        } else {
            return "Stopwatch"
        }
    }
}

// MARK: - Preview

#Preview("Running Stopwatch") {
    @Previewable @State var viewModel = TimerViewModel()
    StopwatchOverlayView(viewModel: viewModel)
        .onAppear {
            viewModel.startStopwatch()
        }
}
