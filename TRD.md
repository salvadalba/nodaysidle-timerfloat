# Technical Requirements Document

## 🧭 System Context
TimerFloat is a minimalist macOS menu bar application that displays a floating countdown timer overlay visible across all applications including fullscreen apps. Built with SwiftUI 6 and AppKit hybrid architecture using MVVM pattern with Observation framework. Local-first single-process application with no server dependency. Targets macOS 15+ (Sequoia).

## 🔌 API Contracts
### TimerService.startTimer
- **Method:** INTERNAL
- **Description:** _Not specified_

### TimerService.pauseTimer
- **Method:** INTERNAL
- **Description:** _Not specified_

### TimerService.resumeTimer
- **Method:** INTERNAL
- **Description:** _Not specified_

### TimerService.cancelTimer
- **Method:** INTERNAL
- **Description:** _Not specified_

### HotkeyService.registerHotkey
- **Method:** INTERNAL
- **Description:** _Not specified_

### WindowService.showOverlay
- **Method:** INTERNAL
- **Description:** _Not specified_

### WindowService.hideOverlay
- **Method:** INTERNAL
- **Description:** _Not specified_

### WindowService.updatePosition
- **Method:** INTERNAL
- **Description:** _Not specified_

### NotificationService.scheduleCompletion
- **Method:** INTERNAL
- **Description:** _Not specified_

## 🧱 Modules
### TimerFloat (App)
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### TimerService
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### WindowService
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### HotkeyService
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### NotificationService
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### Views
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

### Models
- **Responsibility:** _Not specified_
- **Dependencies:**
_None_

## 🗃 Data Model Notes
### Unknown Entity
_None_

### Unknown Entity
_None_

### Unknown Entity
_None_

### Unknown Entity
_None_

### Unknown Entity
_None_

### Unknown Entity
_None_

## 🔐 Validation & Security
- **Rule:** _Not specified_
- **Rule:** _Not specified_
- **Rule:** _Not specified_
- **Rule:** _Not specified_
- **Rule:** _Not specified_
- **Rule:** _Not specified_

## 🧯 Error Handling Strategy
Swift 6 typed throws for service methods. Errors bubble up to UI layer where they display as transient alerts in menu bar popover. Timer errors (already running, not running) handled gracefully by updating UI state. Permission errors (accessibility, notifications) trigger explanatory sheets with Settings.app deep links. No crash on error - always recover to valid state.

## 🔭 Observability
- **Logging:** os.Logger with subsystem 'com.timerfloat' and categories per service (timer, window, hotkey, notification). Debug builds log all state transitions. Release builds log errors and significant events only.
- **Tracing:** Signposts via os_signpost for performance-critical paths: timer tick updates, window level changes, hotkey registration. Instruments integration for CPU profiling during idle countdown.
- **Metrics:**
- Timer start count per session
- Timer completion vs cancellation ratio
- Average timer duration
- Overlay drag frequency

## ⚡ Performance Notes
- **Metric:** _Not specified_
- **Metric:** _Not specified_
- **Metric:** _Not specified_
- **Metric:** _Not specified_
- **Metric:** _Not specified_
- **Metric:** _Not specified_
- **Metric:** _Not specified_

## 🧪 Testing Strategy
### Unit
- TimerServiceTests: verify countdown calculation accuracy over simulated time
- TimerServiceTests: verify pause/resume preserves correct remaining time
- TimerServiceTests: verify completion callback fires at exactly zero
- UserPreferencesTests: verify SwiftData round-trip for all preference fields
- KeyComboTests: verify encoding/decoding of hotkey combinations
### Integration
- WindowServiceTests: verify NSWindow.level set correctly for fullscreen visibility
- WindowServiceTests: verify position persistence across app restarts
- HotkeyServiceTests: verify hotkey triggers timer action (requires accessibility permission in test environment)
- NotificationServiceTests: verify notification scheduled and cancelled correctly
### E2E
- Full timer flow: start 5-second timer from menu bar, verify overlay appears, countdown completes, notification fires
- Drag overlay to new position, quit and relaunch, verify position restored
- Start timer, enter fullscreen app, verify overlay remains visible
- Configure custom hotkey in settings, use hotkey to start timer

## 🚀 Rollout Plan
### Phase
_Not specified_

### Phase
_Not specified_

### Phase
_Not specified_

### Phase
_Not specified_

### Phase
_Not specified_

## ❓ Open Questions
- Should overlay be visible during screen recording/sharing? May need NSWindow.sharingType configuration
- Multi-display support: should overlay appear on all displays or follow mouse?
- Should cancelled timers be logged for productivity analytics in future version?
- Preferred default position: top-right corner or user's last position from previous session?