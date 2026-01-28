# TimerFloat User Guide

A minimalist floating timer for macOS that stays on top of all your windows.

---

## Getting Started

### First Launch

1. Open **TimerFloat** from your Applications folder
2. The app runs in your **menu bar** (look for the timer icon in the top-right of your screen)
3. Click the menu bar icon to open the timer controls

### Granting Permissions

TimerFloat may request two permissions:

- **Notifications**: To alert you when timers complete
- **Accessibility**: Required for global hotkeys (optional)

---

## Using the Timer

### Starting a Timer

**From the Menu Bar:**
1. Click the TimerFloat icon in the menu bar
2. Choose a preset duration: **5**, **10**, **15**, **25**, or **30** minutes
3. Or enter a custom duration in the input field and press Enter

**With Hotkeys (if accessibility permission granted):**
- Press **Cmd + Shift + T** to start a timer with default duration (25 min)

### The Floating Overlay

Once a timer starts, a circular overlay appears showing:
- **Remaining time** in the center
- **Progress ring** that depletes as time passes
- **Color indicators**:
  - Blue = Running
  - Orange = Paused
  - Red = Less than 1 minute remaining
  - Green = Completed

### Controlling the Timer

**Pause/Resume:**
- Click the overlay to pause
- Click again to resume
- Or press **Cmd + Shift + P**

**Cancel:**
- Right-click the overlay
- Or press **Cmd + Shift + C**

### Moving the Overlay

- **Drag** the overlay anywhere on screen
- Position is saved and remembered between sessions
- If you disconnect a monitor, the overlay automatically repositions to a visible screen

---

## Settings

Click the **gear icon** in the menu bar popover to access settings:

### General
- **Default Duration**: Set your preferred timer length (1-120 minutes)
- **Launch at Login**: Start TimerFloat automatically when you log in

### Notifications
- **Show Alerts**: Enable/disable completion notifications
- **Play Sound**: Enable/disable the notification sound

### Appearance
- **Idle Opacity**: How transparent the overlay is when not hovered (10%-100%)
- **Enable Animations**: Toggle the celebration animation when timer completes

---

## Keyboard Shortcuts

| Action | Shortcut |
|--------|----------|
| Start/Cancel Timer | Cmd + Shift + T |
| Pause/Resume | Cmd + Shift + P |
| Cancel Timer | Cmd + Shift + C |

**Note**: Hotkeys require Accessibility permission. Go to **System Settings > Privacy & Security > Accessibility** and enable TimerFloat.

---

## Tips & Tricks

1. **Quick Pomodoro**: Use the 25-minute preset for focused work sessions
2. **Hover for clarity**: The overlay becomes fully opaque when you hover over it
3. **Corner positioning**: Drag the overlay to a screen corner to keep it visible but unobtrusive
4. **Multiple monitors**: The overlay works across all connected displays

---

## Troubleshooting

### Hotkeys not working
1. Open **System Settings > Privacy & Security > Accessibility**
2. Find TimerFloat in the list
3. Toggle it off and on again
4. Restart the app

### Overlay not visible
- Check if it moved to another monitor
- Quit and relaunch the app (position resets to top-right corner)

### Notifications not appearing
1. Open **System Settings > Notifications**
2. Find TimerFloat
3. Ensure notifications are enabled

---

## Quitting TimerFloat

1. Click the menu bar icon
2. Click **Quit** at the bottom of the popover

Or right-click the menu bar icon and select Quit.

---

## Privacy

TimerFloat collects **no personal data**. All usage metrics (timer counts, durations) are stored locally on your Mac and never transmitted anywhere.

---

**Version 1.0** | Built with Swift & SwiftUI | macOS 15.0+
