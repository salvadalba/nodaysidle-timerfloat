import SwiftUI

/// Floating overlay view displaying the stopwatch
struct StopwatchOverlayView: View {
    /// The timer view model
    @Bindable var viewModel: TimerViewModel

    /// Base opacity when not hovered (from preferences)
    var idleOpacity: Double = 0.8

    /// Size of the circular display area
    private let displaySize: CGFloat = 100

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
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)

            // Stopwatch content
            VStack(spacing: 4) {
                // Stopwatch icon
                Image(systemName: "stopwatch.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)

                // Time display with centiseconds
                TimelineView(.periodic(from: .now, by: 0.1)) { _ in
                    Text(viewModel.formattedTimeWithMillis)
                        .font(.system(size: 22, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.primary)
                }

                // State indicator
                if viewModel.isPaused {
                    Label("Paused", systemImage: "pause.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
            }
        }
        .frame(width: 120, height: 120)
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        .opacity(currentOpacity)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
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
