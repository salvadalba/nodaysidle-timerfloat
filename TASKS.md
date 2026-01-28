# Tasks Plan — TimerFloat

## 📌 Global Assumptions
- Developer has access to macOS 15+ (Sequoia) for development and testing
- Xcode 16+ with Swift 6 support is installed
- Apple Developer account available for notarization (release builds)
- User testing will occur on Macs with accessibility permissions grantable
- SwiftData stable on macOS 15 for production use
- Single developer building incrementally with weekly releases

## ⚠️ Risks
- [object Object]
- [object Object]
- [object Object]
- [object Object]
- [object Object]

## 🧩 Epics
## Project Foundation
**Goal:** Establish the base macOS app structure with menu bar integration and SwiftUI/AppKit hybrid architecture

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Create Xcode project with SwiftUI App lifecycle (XS)

Initialize a new macOS app targeting macOS 15+ with SwiftUI 6 App lifecycle. Configure Info.plist for menu bar app (LSUIElement = YES). Set up Swift 6 language mode and strict concurrency checking.

**Acceptance Criteria**
- Xcode project builds without warnings
- App runs as menu bar only (no dock icon)
- Swift 6 strict concurrency enabled
- macOS 15 deployment target set

**Dependencies**
_None_

### ✅ Implement MenuBarExtra with basic popover (S)

Create the menu bar icon using SF Symbols (timer icon). Implement MenuBarExtra with a SwiftUI popover showing placeholder content. Use .ultraThinMaterial for popover background.

**Acceptance Criteria**
- Timer icon appears in menu bar
- Clicking icon shows popover with material background
- Popover dismisses on outside click
- Icon uses SF Symbol timer.circle

**Dependencies**
- Create Xcode project with SwiftUI App lifecycle

### ✅ Set up os.Logger infrastructure (XS)

Create logging infrastructure using os.Logger with subsystem 'com.timerfloat'. Create separate loggers for categories: timer, window, hotkey, notification. Configure debug vs release log levels.

**Acceptance Criteria**
- Logger instances created for each category
- Debug builds log all state transitions
- Release builds log errors and significant events only
- Logs visible in Console.app with correct subsystem filter

**Dependencies**
- Create Xcode project with SwiftUI App lifecycle

### ✅ Create MVVM folder structure and base protocols (XS)

Organize project into Models, Views, ViewModels, Services folders. Create base protocols for services. Set up Observation framework imports.

**Acceptance Criteria**
- Folder structure matches MVVM pattern
- Service protocols defined
- Observation framework properly imported
- Project compiles with new structure

**Dependencies**
- Create Xcode project with SwiftUI App lifecycle

## Timer Core
**Goal:** Build the core timer logic with accurate countdown, pause/resume, and completion handling

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Define TimerState model (XS)

Create TimerState enum with cases: idle, running(remaining: TimeInterval, total: TimeInterval), paused(remaining: TimeInterval, total: TimeInterval), completed. Make it Sendable for concurrency safety.

**Acceptance Criteria**
- TimerState enum defined with all cases
- Computed properties for remaining time and progress
- Sendable conformance for Swift 6
- Equatable conformance for state comparison

**Dependencies**
- Create MVVM folder structure and base protocols

### ✅ Implement TimerService with structured concurrency (M)

Create TimerService actor using Swift structured concurrency. Use AsyncStream for timer ticks. Implement startTimer(duration:), pauseTimer(), resumeTimer(), cancelTimer() methods. Use typed throws for error handling.

**Acceptance Criteria**
- TimerService is an actor for thread safety
- Timer ticks at 1-second intervals via AsyncStream
- Pause preserves exact remaining time
- Cancel cleans up resources properly
- Typed errors for invalid state transitions

**Dependencies**
- Define TimerState model

### ✅ Create TimerViewModel with Observation (S)

Create TimerViewModel using @Observable macro. Subscribe to TimerService state changes. Expose formatted time string, progress percentage, and action methods. Handle state-to-UI mapping.

**Acceptance Criteria**
- @Observable macro applied correctly
- Formatted time shows MM:SS format
- Progress is 0.0 to 1.0 range
- UI updates on state changes
- MainActor isolation for UI properties

**Dependencies**
- Implement TimerService with structured concurrency

### ✅ Write TimerService unit tests (S)

Create TimerServiceTests using Swift Testing. Test countdown accuracy with simulated time. Verify pause/resume preserves remaining time. Test completion callback fires at zero. Test error cases for invalid transitions.

**Acceptance Criteria**
- Test countdown calculation accuracy
- Test pause/resume preserves time
- Test completion fires at exactly zero
- Test invalid state transition errors
- All tests pass in CI environment

**Dependencies**
- Implement TimerService with structured concurrency

### ✅ Add os_signpost instrumentation to timer (XS)

Add Signposts for performance tracking on timer tick updates. Create signpost intervals for timer start-to-completion. Enable Instruments integration for CPU profiling.

**Acceptance Criteria**
- Signposts appear in Instruments Time Profiler
- Timer tick performance measurable
- Start-to-completion intervals tracked
- No performance regression from instrumentation

**Dependencies**
- Implement TimerService with structured concurrency

## Floating Overlay Window
**Goal:** Create the floating timer overlay that stays visible across all apps including fullscreen

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Create custom NSWindow subclass for overlay (M)

Create FloatingOverlayWindow NSWindow subclass. Set window level to .statusBar + 1 to float above all apps. Configure as non-activating (canBecomeKey = false initially). Set backgroundColor to clear. Enable ignoresMouseEvents when not interacting.

**Acceptance Criteria**
- Window floats above regular windows
- Window floats above fullscreen apps
- Window does not steal focus from active app
- Transparent background works correctly

**Dependencies**
- Create MVVM folder structure and base protocols

### ✅ Implement WindowService for overlay management (S)

Create WindowService to manage FloatingOverlayWindow lifecycle. Implement showOverlay(), hideOverlay(), updatePosition(to:). Handle window creation lazily. Manage window visibility state.

**Acceptance Criteria**
- showOverlay creates and displays window
- hideOverlay hides without destroying window
- updatePosition moves window smoothly
- Service handles repeated show/hide calls

**Dependencies**
- Create custom NSWindow subclass for overlay

### ✅ Create TimerOverlayView with countdown display (M)

Create SwiftUI view for overlay content. Display countdown using TimelineView for smooth updates. Use .regularMaterial background with rounded corners. Show time in large, readable format. Add subtle circular progress indicator.

**Acceptance Criteria**
- TimelineView updates every second
- Material background is visible but subtle
- Time format is easily readable
- Progress ring shows completion percentage
- View adapts to timer state (running/paused)

**Dependencies**
- Create TimerViewModel with Observation

### ✅ Integrate SwiftUI view into NSWindow (S)

Use NSHostingView to embed TimerOverlayView in FloatingOverlayWindow. Ensure proper sizing based on content. Handle dark/light mode correctly. Set up proper view hierarchy.

**Acceptance Criteria**
- SwiftUI view renders correctly in NSWindow
- Window sizes to content automatically
- Dark mode appearance works
- No rendering artifacts or clipping

**Dependencies**
- Implement WindowService for overlay management
- Create TimerOverlayView with countdown display

### ✅ Implement overlay dragging to reposition (S)

Add drag gesture to overlay view. Calculate new screen position during drag. Clamp position to screen bounds. Update window frame smoothly during drag. Use matchedGeometryEffect for smooth animations if needed.

**Acceptance Criteria**
- Overlay can be dragged to any screen position
- Position stays within visible screen bounds
- Drag feels smooth and responsive
- Overlay snaps to final position on release

**Dependencies**
- Integrate SwiftUI view into NSWindow

### ✅ Write WindowService integration tests (S)

Create WindowServiceTests to verify NSWindow.level configuration. Test position updates. Verify window visibility state management. Test fullscreen visibility behavior.

**Acceptance Criteria**
- Test verifies correct window level
- Test verifies position persistence
- Test verifies show/hide state transitions
- Tests run in UI test environment

**Dependencies**
- Implement WindowService for overlay management

## Menu Bar Interface
**Goal:** Build the complete menu bar popover with quick start options and controls

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Design popover layout with quick start buttons (S)

Create MenuPopoverView with preset timer buttons (5m, 15m, 25m, 45m). Use VStack with proper spacing. Apply .ultraThinMaterial background. Add visual feedback on button press.

**Acceptance Criteria**
- Four preset duration buttons visible
- Buttons have clear labels
- Material background applied
- Buttons show press state feedback

**Dependencies**
- Implement MenuBarExtra with basic popover

### ✅ Add custom duration input field (S)

Add TextField for custom duration entry. Parse input as minutes. Validate input is positive number. Add 'Start' button next to field. Handle keyboard submit.

**Acceptance Criteria**
- TextField accepts numeric input
- Invalid input shows error state
- Start button triggers timer
- Enter key submits custom duration

**Dependencies**
- Design popover layout with quick start buttons

### ✅ Implement active timer controls in popover (M)

Show pause/resume button when timer active. Add cancel button. Display current remaining time. Use PhaseAnimator for smooth state transitions between idle and active views.

**Acceptance Criteria**
- Pause button shows when timer running
- Resume button shows when paused
- Cancel stops timer and resets
- Transitions between states are smooth

**Dependencies**
- Create TimerViewModel with Observation
- Design popover layout with quick start buttons

### ✅ Add settings gear button and navigation (S)

Add gear icon button to popover. Use NavigationStack or sheet to show settings view. Include Settings.app-style sections layout.

**Acceptance Criteria**
- Gear button visible in popover
- Tapping opens settings view
- Back navigation works correctly
- Settings view matches macOS style

**Dependencies**
- Design popover layout with quick start buttons

### ✅ Update menu bar icon to reflect timer state (S)

Change menu bar icon based on timer state. Use filled icon when timer running. Add badge or visual indicator of remaining time. Use SF Symbol variants appropriately.

**Acceptance Criteria**
- Icon changes when timer starts
- Icon differs between running and paused
- Icon returns to default when idle
- Changes are visually noticeable

**Dependencies**
- Create TimerViewModel with Observation

## Persistence & Settings
**Goal:** Persist user preferences and timer settings using SwiftData

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Create SwiftData UserPreferences model (S)

Define UserPreferences SwiftData model with: defaultDuration, overlayPosition (CGPoint), overlayOpacity, soundEnabled, showInMenuBar. Configure as singleton pattern.

**Acceptance Criteria**
- @Model macro applied correctly
- All preference fields defined
- Default values set appropriately
- Model compiles with SwiftData

**Dependencies**
- Create MVVM folder structure and base protocols

### ✅ Implement PreferencesService for data access (S)

Create PreferencesService to read/write UserPreferences via SwiftData. Use ModelContainer in App. Provide async methods for preference updates. Handle first-launch defaults.

**Acceptance Criteria**
- Service reads preferences correctly
- Service writes preferences correctly
- First launch creates default preferences
- Changes persist across app restarts

**Dependencies**
- Create SwiftData UserPreferences model

### ✅ Build settings view for preferences (M)

Create SettingsView with Form sections. Include default duration picker, overlay opacity slider, sound toggle. Use macOS Settings scene style. Bind to UserPreferences.

**Acceptance Criteria**
- All preferences editable in UI
- Changes save immediately
- Form uses proper macOS styling
- Sliders and toggles work correctly

**Dependencies**
- Implement PreferencesService for data access
- Add settings gear button and navigation

### ✅ Persist overlay position on drag end (S)

Save overlay position to UserPreferences when drag ends. Restore position on app launch. Handle screen resolution changes gracefully.

**Acceptance Criteria**
- Position saves after drag completes
- Position restores on app relaunch
- Invalid positions fallback to default
- Multi-display position works correctly

**Dependencies**
- Implement overlay dragging to reposition
- Implement PreferencesService for data access

### ✅ Write UserPreferences round-trip tests (S)

Create tests verifying SwiftData persistence. Test all preference fields save and load correctly. Test default value initialization. Test edge cases.

**Acceptance Criteria**
- All fields persist correctly
- Default values initialize properly
- Round-trip preserves exact values
- Tests use in-memory store

**Dependencies**
- Implement PreferencesService for data access

## Global Hotkeys
**Goal:** Enable keyboard shortcuts to control timer from anywhere in the system

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Create KeyCombo model for hotkey storage (S)

Define KeyCombo struct with keyCode, modifiers. Implement Codable for persistence. Add display string computed property (e.g., '⌘⇧T'). Make Sendable and Hashable.

**Acceptance Criteria**
- KeyCombo stores key and modifiers
- Codable encodes/decodes correctly
- Display string shows proper symbols
- Sendable for concurrency safety

**Dependencies**
- Create SwiftData UserPreferences model

### ✅ Implement HotkeyService using Carbon API (M)

Create HotkeyService using CGEventTap or Carbon RegisterEventHotKey. Implement registerHotkey(combo:action:) method. Handle accessibility permission requirement. Support multiple hotkeys.

**Acceptance Criteria**
- Hotkey registers with system
- Callback fires when hotkey pressed
- Multiple hotkeys supported
- Unregister cleans up properly

**Dependencies**
- Create KeyCombo model for hotkey storage

### ✅ Add hotkey configuration UI in settings (M)

Create hotkey recording field in settings. Show current hotkey combo. Allow clicking to record new combo. Validate no conflicts with system hotkeys.

**Acceptance Criteria**
- Current hotkey displayed
- Click-to-record workflow works
- New combo saves to preferences
- Conflict detection shows warning

**Dependencies**
- Build settings view for preferences
- Implement HotkeyService using Carbon API

### ✅ Connect hotkeys to timer actions (S)

Register default hotkey for start/pause toggle. Register hotkey for cancel. Update registrations when preferences change. Handle service unavailable gracefully.

**Acceptance Criteria**
- Toggle hotkey starts or pauses timer
- Cancel hotkey stops timer
- Changing preferences updates hotkeys
- Works when any app is focused

**Dependencies**
- Implement HotkeyService using Carbon API
- Implement TimerService with structured concurrency

### ✅ Handle accessibility permission flow (S)

Check accessibility permission on launch. Show explanatory sheet if not granted. Provide button to open System Settings > Privacy > Accessibility. Re-check permission after returning.

**Acceptance Criteria**
- Permission status detected correctly
- Explanatory UI is clear
- Deep link to Settings works
- Permission grant enables hotkeys

**Dependencies**
- Implement HotkeyService using Carbon API

### ✅ Write KeyCombo encoding tests (XS)

Test Codable round-trip for various key combinations. Test edge cases like function keys, special keys. Verify display string formatting.

**Acceptance Criteria**
- All modifier combinations encode correctly
- Special keys handled properly
- Display string matches expected format
- Empty combo handled gracefully

**Dependencies**
- Create KeyCombo model for hotkey storage

## Notifications
**Goal:** Notify users when timers complete with system notifications and optional sounds

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Implement NotificationService for completion alerts (S)

Create NotificationService using UNUserNotificationCenter. Implement scheduleCompletion(at:) method. Include timer name in notification. Handle notification permission request.

**Acceptance Criteria**
- Notification schedules for completion time
- Notification shows timer completed message
- Cancelling timer removes notification
- Permission request flow works

**Dependencies**
- Create MVVM folder structure and base protocols

### ✅ Add notification permission request flow (S)

Request notification permission on first timer start. Show explanatory UI if denied. Provide deep link to notification settings. Handle provisional authorization.

**Acceptance Criteria**
- Permission requested appropriately
- Denial shows helpful message
- Settings deep link works
- App works without notifications

**Dependencies**
- Implement NotificationService for completion alerts

### ✅ Connect timer completion to notification (S)

Trigger notification when timer reaches zero. Schedule notification when timer starts. Cancel notification on timer cancel or pause. Update notification if timer restarted.

**Acceptance Criteria**
- Notification fires at timer completion
- Cancel removes pending notification
- Restart updates notification time
- No duplicate notifications

**Dependencies**
- Implement NotificationService for completion alerts
- Implement TimerService with structured concurrency

### ✅ Add completion sound option (S)

Play system sound on timer completion. Add preference toggle for sound. Use AudioServicesPlaySystemSound for native feel. Respect system Do Not Disturb.

**Acceptance Criteria**
- Sound plays on completion
- Sound can be disabled in settings
- Uses appropriate system sound
- Respects system sound settings

**Dependencies**
- Build settings view for preferences
- Connect timer completion to notification

### ✅ Write NotificationService tests (S)

Test notification scheduling logic. Test cancellation removes notification. Test permission denied handling. Mock UNUserNotificationCenter.

**Acceptance Criteria**
- Schedule timing is correct
- Cancellation works properly
- Permission states handled
- Tests work without system access

**Dependencies**
- Implement NotificationService for completion alerts

## Polish & Quality
**Goal:** Refine the user experience with animations, accessibility, and edge case handling

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ Add completion animation to overlay (S)

Create completion animation using PhaseAnimator. Show celebratory pulse or glow effect. Transition overlay to completed state gracefully. Auto-hide after animation completes.

**Acceptance Criteria**
- Animation plays on timer completion
- Animation is visually pleasing
- Overlay dismisses after animation
- Animation can be disabled in preferences

**Dependencies**
- Create TimerOverlayView with countdown display

### ✅ Implement overlay opacity based on hover (S)

Reduce overlay opacity when not hovering. Increase opacity on mouse hover. Use smooth animation for transitions. Respect user opacity preference as base.

**Acceptance Criteria**
- Overlay dims when not hovered
- Hover brightens overlay smoothly
- Transition animation is smooth
- User preference is respected

**Dependencies**
- Integrate SwiftUI view into NSWindow

### ✅ Add VoiceOver accessibility labels (S)

Add accessibility labels to all controls. Announce timer state changes. Make overlay content accessible. Test with VoiceOver enabled.

**Acceptance Criteria**
- All buttons have accessibility labels
- Timer state announced on change
- Overlay readable by VoiceOver
- Navigation works with keyboard

**Dependencies**
- Create TimerOverlayView with countdown display
- Implement active timer controls in popover

### ✅ Handle screen configuration changes (M)

Detect display configuration changes. Reposition overlay if current position invalid. Handle display disconnect/reconnect. Support dynamic resolution changes.

**Acceptance Criteria**
- Overlay moves if display removed
- Position adjusts to new resolution
- No crash on display changes
- Overlay stays visible

**Dependencies**
- Persist overlay position on drag end

### ✅ Add launch at login option (S)

Add preference to launch app at login. Use SMAppService for modern login item API. Show current status in settings. Handle removal correctly.

**Acceptance Criteria**
- Toggle enables launch at login
- App starts on user login
- Disabling removes login item
- Status reflects actual state

**Dependencies**
- Build settings view for preferences

### ✅ Implement app metrics collection (S)

Track timer start count per session. Calculate completion vs cancellation ratio. Measure average timer duration. Track overlay drag frequency. Store locally only.

**Acceptance Criteria**
- Metrics collected during use
- Data stored locally only
- Accessible for debugging
- No performance impact

**Dependencies**
- Implement TimerService with structured concurrency
- Implement overlay dragging to reposition

## End-to-End Testing
**Goal:** Verify complete user flows work correctly from start to finish

### User Stories
_None_

### Acceptance Criteria
_None_

### ✅ E2E: Full timer flow test (M)

Create UI test for complete timer flow. Start 5-second timer from menu bar. Verify overlay appears with countdown. Wait for completion. Verify notification fires.

**Acceptance Criteria**
- Test starts timer from menu bar
- Overlay appears and counts down
- Completion triggers notification
- Test passes reliably

**Dependencies**
- Implement active timer controls in popover
- Connect timer completion to notification

### ✅ E2E: Position persistence test (S)

Create test that drags overlay to new position. Quit and relaunch app. Verify position restored correctly. Test multiple positions.

**Acceptance Criteria**
- Drag to new position works
- Quit and relaunch preserves position
- Multiple positions tested
- Test handles timing correctly

**Dependencies**
- Persist overlay position on drag end

### ✅ E2E: Fullscreen visibility test (M)

Create test that starts timer. Enter a fullscreen app. Verify overlay remains visible above fullscreen. Exit fullscreen and verify still visible.

**Acceptance Criteria**
- Overlay visible in fullscreen
- Overlay above fullscreen window
- Works after exiting fullscreen
- No z-order issues

**Dependencies**
- Create custom NSWindow subclass for overlay

### ✅ E2E: Hotkey configuration test (M)

Create test that configures custom hotkey in settings. Use hotkey to start timer. Verify timer starts via global hotkey. Test hotkey when other app focused.

**Acceptance Criteria**
- Hotkey configurable in settings
- Hotkey starts timer globally
- Works from any application
- Test runs with accessibility permission

**Dependencies**
- Add hotkey configuration UI in settings
- Connect hotkeys to timer actions

## ❓ Open Questions
- Should overlay be visible during screen recording/sharing?
- Multi-display support: should overlay appear on all displays or follow mouse?
- Should cancelled timers be logged for productivity analytics in future version?
- Preferred default overlay position: top-right corner or user's last position?
- Should there be a Pomodoro mode with automatic break timers?
- Should overlay have different visual themes or stay minimal?