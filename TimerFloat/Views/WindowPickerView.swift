import SwiftUI

/// View for selecting a window to pin to
struct WindowPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var availableWindows: [PinnableWindow] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var selectedIndex: Int = 0

    let onSelect: (PinnableWindow) -> Void

    private var filteredWindows: [PinnableWindow] {
        if searchText.isEmpty {
            return availableWindows
        }
        return availableWindows.filter { window in
            window.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with pin icon
            HStack(spacing: 10) {
                Image(systemName: "pin.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color.TimerFloat.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Pin to Window")
                        .font(.headline)
                    Text("Timer will follow the selected window")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
            .padding()
            .background(Color.primary.opacity(0.03))

            // Search field with icon
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)

                TextField("Search windows...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.body)

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary.opacity(0.05))
            )
            .padding(.horizontal)
            .padding(.vertical, 10)

            Divider()

            // Window list
            if isLoading {
                Spacer()
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Finding windows...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else if filteredWindows.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.05))
                            .frame(width: 60, height: 60)
                        Image(systemName: "macwindow.badge.plus")
                            .font(.system(size: 28))
                            .foregroundStyle(.secondary)
                    }
                    Text(searchText.isEmpty ? "No windows available" : "No matching windows")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Open an app to pin to its window")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
            } else {
                List(Array(filteredWindows.enumerated()), id: \.element.id) { index, window in
                    WindowRow(window: window, isSelected: index == selectedIndex) {
                        onSelect(window)
                        dismiss()
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(index == selectedIndex ? Color.TimerFloat.primary.opacity(0.1) : Color.clear)
                    )
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            // Keyboard hints footer
            if !filteredWindows.isEmpty {
                HStack(spacing: 16) {
                    KeyboardHint(keys: "↑↓", action: "Navigate")
                    KeyboardHint(keys: "⏎", action: "Select")
                    KeyboardHint(keys: "esc", action: "Cancel")
                }
                .padding(.vertical, 8)
                .padding(.horizontal)
                .background(Color.primary.opacity(0.03))
            }
        }
        .frame(width: 320, height: 420)
        .task {
            await loadWindows()
        }
        .onKeyPress(.upArrow) {
            if selectedIndex > 0 {
                selectedIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if selectedIndex < filteredWindows.count - 1 {
                selectedIndex += 1
            }
            return .handled
        }
        .onKeyPress(.return) {
            if !filteredWindows.isEmpty && selectedIndex < filteredWindows.count {
                onSelect(filteredWindows[selectedIndex])
                dismiss()
            }
            return .handled
        }
    }

    private func loadWindows() async {
        isLoading = true
        if let windows = await WindowPinningService.shared.getAvailableWindows() {
            availableWindows = windows
        }
        isLoading = false
    }
}

/// Keyboard hint display
struct KeyboardHint: View {
    let keys: String
    let action: String

    var body: some View {
        HStack(spacing: 4) {
            Text(keys)
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.1))
                )
            Text(action)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

/// Cache for app icons to avoid repeated lookups
@MainActor
final class AppIconCache {
    static let shared = AppIconCache()
    private var cache: [pid_t: NSImage] = [:]

    func icon(for pid: pid_t) -> NSImage? {
        if let cached = cache[pid] {
            return cached
        }
        if let app = NSRunningApplication(processIdentifier: pid),
           let icon = app.icon {
            cache[pid] = icon
            return icon
        }
        return nil
    }
}

/// Row displaying a single window option
struct WindowRow: View {
    let window: PinnableWindow
    var isSelected: Bool = false
    let onSelect: () -> Void

    @State private var appIcon: NSImage?
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack(spacing: 12) {
                // App icon with badge styling
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.05))
                        .frame(width: 36, height: 36)

                    if let icon = appIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "macwindow")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(window.ownerName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(isSelected ? Color.TimerFloat.primary : .primary)

                    if !window.windowTitle.isEmpty {
                        Text(window.windowTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.TimerFloat.primary)
                        .font(.body)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? TimerDesign.pressScale : 1.0)
        .animation(TimerAnimations.press, value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onAppear {
            appIcon = AppIconCache.shared.icon(for: window.ownerPID)
        }
    }
}

#Preview {
    WindowPickerView { window in
        print("Selected: \(window.displayName)")
    }
}
