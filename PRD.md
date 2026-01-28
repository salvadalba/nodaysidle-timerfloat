# TimerFloat

## 🎯 Product Vision
A minimalist floating timer that lives in your peripheral vision, keeping you aware of time without breaking focus or switching contexts.

## ❓ Problem Statement
Traditional timers hide in the menubar or require switching windows, forcing users to break their flow to check remaining time. Users need a way to track task duration while staying fully immersed in their work.

## 🎯 Goals
- Display a persistent floating timer overlay that remains visible across all applications including fullscreen apps
- Provide instant timer creation from the menubar with zero-friction interaction
- Maintain minimal visual footprint while ensuring timer visibility in peripheral vision
- Deliver zero-latency UI interactions with smooth animations
- Support common productivity timer presets (Pomodoro 25m, short break 5m, long break 15m)

## 🚫 Non-Goals
- Building a full-featured time tracking or analytics platform
- Supporting multiple simultaneous timers
- Integrating with third-party project management tools
- Cross-platform support (iOS, Windows, Linux)
- Cloud-based timer synchronization across devices

## 👥 Target Users
- Knowledge workers who use time-boxing techniques like Pomodoro
- Developers and designers who work in fullscreen applications
- Remote workers tracking focused work sessions
- Anyone who wants ambient time awareness without context switching

## 🧩 Core Features
- Menu bar app with quick-access timer presets (25m, 15m, 5m, custom)
- Floating overlay window using NSWindow.level for above-all-apps visibility
- Draggable timer position with corner snapping and position memory
- Visual countdown with .ultraThinMaterial background for minimal distraction
- Smooth animations using PhaseAnimator for state transitions
- TimelineView-based countdown display for precise timing
- Keyboard hotkeys for start, pause, reset without mouse interaction
- Gentle completion notification with optional sound
- Settings scene for customizing appearance, position, and timer presets

## ⚙️ Non-Functional Requirements
- macOS 15+ (Sequoia) minimum deployment target
- Sub-16ms frame time for all animations using Metal acceleration
- Less than 1% CPU usage during idle countdown
- Memory footprint under 50MB
- Launch to visible timer in under 500ms
- Local-first architecture with no network dependency
- Full Accessibility API compliance for VoiceOver users

## 📊 Success Metrics
- Timer visible and functional over fullscreen apps 100% of the time
- User can start a timer within 2 clicks or 1 hotkey press
- App launch to timer display under 500ms
- Zero UI jank during countdown updates
- User retention: daily active usage over 5 days per week

## 📌 Assumptions
- Users have macOS 15 (Sequoia) or later installed
- Users prefer visual timers over audio-only alerts
- A single active timer covers the primary use case
- Screen corner placement is sufficient for most workflows
- Users will grant necessary permissions for overlay and hotkey functionality

## ❓ Open Questions
- Should the timer support custom durations beyond presets, and if so, what input method?
- What visual treatment works best for the timer when overlaying both light and dark application backgrounds?
- Should there be multiple size options for the floating timer display?
- How should the timer behave when the user has multiple displays?
- Should SwiftData persist timer history for optional review, or is this out of scope?