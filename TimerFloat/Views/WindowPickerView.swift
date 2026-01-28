import SwiftUI

/// View for selecting a window to pin to
struct WindowPickerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var availableWindows: [PinnableWindow] = []
    @State private var isLoading = true
    @State private var searchText = ""

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
            // Header
            HStack {
                Text("Pin to Window")
                    .font(.headline)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Search field
            TextField("Search windows...", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Window list
            if isLoading {
                Spacer()
                ProgressView()
                    .padding()
                Spacer()
            } else if filteredWindows.isEmpty {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "macwindow")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(searchText.isEmpty ? "No windows available" : "No matching windows")
                        .foregroundStyle(.secondary)
                }
                Spacer()
            } else {
                List(filteredWindows) { window in
                    WindowRow(window: window) {
                        onSelect(window)
                        dismiss()
                    }
                }
                .listStyle(.plain)
            }
        }
        .frame(width: 300, height: 400)
        .task {
            await loadWindows()
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

/// Row displaying a single window option
struct WindowRow: View {
    let window: PinnableWindow
    let onSelect: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            HStack {
                // App icon (if available)
                if let app = NSRunningApplication(processIdentifier: window.ownerPID),
                   let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: "macwindow")
                        .frame(width: 24, height: 24)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(window.ownerName)
                        .font(.body)
                        .lineLimit(1)

                    if !window.windowTitle.isEmpty {
                        Text(window.windowTitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    WindowPickerView { window in
        print("Selected: \(window.displayName)")
    }
}
