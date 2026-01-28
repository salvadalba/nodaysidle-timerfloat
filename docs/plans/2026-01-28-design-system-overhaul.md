# Design System Overhaul Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Transform TimerFloat from generic SwiftUI defaults to a distinctive, memorable design with the "Time as Resource" theme.

**Design Philosophy:**
- Time is valuable - treat it like currency (golden coin aesthetic)
- Distinct visual identity through custom typography and color palette
- Micro-interactions that make the app feel alive and rewarding
- Clear visual distinction between countdown timer and stopwatch modes

**Tech Stack:** Swift 6, SwiftUI, AppKit, AVFoundation (sounds), Custom Fonts

---

## Task 1: Add IBM Plex Mono Font

**Files:**
- Create: `TimerFloat/Resources/Fonts/IBMPlexMono-Regular.ttf`
- Create: `TimerFloat/Resources/Fonts/IBMPlexMono-Medium.ttf`
- Create: `TimerFloat/Resources/Fonts/IBMPlexMono-SemiBold.ttf`
- Modify: `TimerFloat/Info.plist`

**Step 1: Download fonts**

Download IBM Plex Mono fonts from Google Fonts repository.

**Step 2: Update Info.plist**

Add `ATSApplicationFontsPath` key pointing to `Resources/Fonts`.

**Step 3: Add to Xcode project**

Add the Fonts folder to the Xcode project with "Copy items if needed" and target membership.

**Step 4: Verify**

Build project and verify no font loading errors.

---

## Task 2: Create Design System

**Files:**
- Create: `TimerFloat/Design/DesignSystem.swift`

**Step 1: Create color palette**

```swift
extension Color {
    enum TimerFloat {
        static let primary = Color(red: 0.39, green: 0.40, blue: 0.95)       // Indigo #6366F1
        static let warning = Color(red: 0.96, green: 0.62, blue: 0.04)      // Amber #F59E0B
        static let urgent = Color(red: 0.94, green: 0.27, blue: 0.27)       // Red #EF4444
        static let complete = Color(red: 0.06, green: 0.73, blue: 0.51)     // Emerald #10B981
        static let stopwatch = Color(red: 0.08, green: 0.65, blue: 0.65)    // Teal #14A3A3
    }
}
```

**Step 2: Create typography helpers**

```swift
enum TimerTypography {
    static func timeDisplay(size: CGFloat = 24) -> Font {
        .custom("IBMPlexMono-SemiBold", size: size, relativeTo: .title)
    }
}
```

**Step 3: Create animation constants**

```swift
enum TimerAnimations {
    static let hover = Animation.easeInOut(duration: 0.2)
    static let press = Animation.easeOut(duration: 0.1)
}
```

**Step 4: Create design constants**

```swift
enum TimerDesign {
    static let overlaySize: CGFloat = 120
    static let hoverScale: CGFloat = 1.02
    static let pressScale: CGFloat = 0.96
}
```

**Step 5: Add to Xcode project**

Add Design folder to Xcode project.

---

## Task 3: Create Sound Service

**Files:**
- Create: `TimerFloat/Services/SoundService.swift`

**Step 1: Create SoundService**

```swift
@MainActor
final class SoundService {
    static let shared = SoundService()
    var soundEnabled: Bool = true

    func playCompletionSound() {
        // Casino "cha-ching" using Glass + Hero system sounds
    }
}
```

**Step 2: Add to Xcode project**

Add SoundService.swift to Xcode project.

---

## Task 4: Update Timer Overlay View

**Files:**
- Modify: `TimerFloat/Views/TimerOverlayView.swift`

**Step 1: Apply new design system**

- Use `Color.TimerFloat` colors
- Use `TimerTypography` fonts
- Use `TimerDesign` constants

**Step 2: Add tapered progress ring**

Replace simple circle stroke with `TaperedProgressRing` component.

**Step 3: Add tick marks**

Add subtle 60-tick marks around the progress ring.

**Step 4: Add hover scale effect**

Apply `hoverScale(isHovered)` modifier.

**Step 5: Update completion animation**

Add warm golden glow effect and sound trigger.

---

## Task 5: Update Stopwatch Overlay View

**Files:**
- Modify: `TimerFloat/Views/StopwatchOverlayView.swift`

**Step 1: Change to pill shape**

Update frame from 120x120 square to 140x100 pill shape.

**Step 2: Apply teal color scheme**

Use `Color.TimerFloat.stopwatch` for accents and tint.

**Step 3: Update layout**

Change to horizontal layout with icon + time side-by-side.

**Step 4: Add pulsing glow effect**

Add subtle pulse animation when running.

---

## Task 6: Update Menu Popover

**Files:**
- Modify: `TimerFloat/TimerFloatApp.swift`

**Step 1: Increase width**

Change popover width from 200px to 240px.

**Step 2: Add section backgrounds**

Wrap preset buttons and custom input in rounded rectangles.

**Step 3: Add Pomodoro badge**

Add "Pomodoro" label to 25m preset button.

**Step 4: Update button styling**

Add press scale effects to all buttons.

---

## Task 7: Update Window Picker

**Files:**
- Modify: `TimerFloat/Views/WindowPickerView.swift`

**Step 1: Add keyboard navigation**

Implement ↑↓ arrow key navigation and ⏎ selection.

**Step 2: Add keyboard hints footer**

Show keyboard shortcuts at bottom of picker.

**Step 3: Improve row styling**

Add selection highlight and better app icon badges.

---

## Task 8: Update Settings View

**Files:**
- Modify: `TimerFloat/TimerFloatApp.swift`

**Step 1: Add section icons**

Add SF Symbol icons to each settings section header.

**Step 2: Increase dimensions**

Change from 220x420 to 260x480 for better spacing.

**Step 3: Improve toggle styling**

Add subtitles to toggles explaining their function.

---

## Task 9: Create New App Icon

**Files:**
- Modify: `TimerFloat/Assets.xcassets/AppIcon.appiconset/`

**Step 1: Design "Time as Resource" icon**

Create golden coin with clock hands and emerald progress ring on indigo background.

**Step 2: Generate all sizes**

Generate 16, 32, 128, 256, 512, and 1024px versions plus @2x variants.

**Step 3: Update Contents.json**

Update asset catalog manifest.

---

## Task 10: Integrate and Build

**Step 1: Add all new files to Xcode project**

- Design/DesignSystem.swift
- Services/SoundService.swift
- Resources/Fonts/ folder

**Step 2: Build project**

Run: `xcodebuild -scheme TimerFloat -configuration Release build`
Expected: BUILD SUCCEEDED

**Step 3: Run tests**

Run: `swift test`
Expected: All tests pass

**Step 4: Commit all changes**

```bash
git add -A
git commit -m "feat: implement design system overhaul

- Add IBM Plex Mono typography
- Create color palette (indigo, amber, red, emerald, teal)
- Implement tapered progress ring with tick marks
- Add distinct pill shape for stopwatch
- Add hover/press micro-interactions
- Implement completion celebration with sound
- Improve menu popover spacing and hierarchy
- Enhance window picker with keyboard navigation
- Create new app icon with Time as Resource theme

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
"
```

---

## Summary

This plan transforms TimerFloat's visual identity:

| Component | Before | After |
|-----------|--------|-------|
| Typography | System monospace | IBM Plex Mono |
| Colors | System accent | Indigo/Amber/Emerald palette |
| Progress ring | Simple stroke | Tapered with tick marks |
| Stopwatch | Same as timer | Distinct pill shape, teal |
| Hover effect | Opacity only | Scale + opacity |
| Completion | Green pulse | Golden glow + sound |
| App icon | Blue square | Golden coin timer |

### Key Design Decisions

1. **IBM Plex Mono**: Distinctive, legible, characterful alternative to system fonts
2. **Color palette**: Semantic colors that convey timer state (urgent red, warning amber)
3. **Stopwatch distinction**: Different shape and color makes mode instantly recognizable
4. **Micro-interactions**: Press/hover feedback makes UI feel responsive and alive
5. **Completion celebration**: Rewarding feedback for finishing a timer (time well spent!)
