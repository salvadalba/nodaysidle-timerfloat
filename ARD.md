# Architecture Requirements Document

## 🧱 System Overview
TimerFloat is a minimalist macOS menu bar application that displays a floating countdown timer overlay visible across all applications including fullscreen apps. Built with SwiftUI 6 and AppKit hybrid architecture, it provides zero-latency timer creation and ambient time awareness through a persistent, draggable overlay window using NSWindow.level customization.

## 🏗 Architecture Style
Local-first single-process macOS application using MVVM pattern with Observation framework. Menu bar app with floating overlay window and optional Settings scene. No server dependency.

## 🎨 Frontend Architecture
- **Framework:** SwiftUI 6 with AppKit integration for NSWindow.level control and menu bar hosting
- **State Management:** Observation framework with @Observable models for timer state, preferences, and window position
- **Routing:** Menu bar popover for controls, floating NSWindow for timer display, Settings scene for preferences
- **Build Tooling:** Xcode 16, Swift Package Manager for dependencies, Metal shaders for visual effects

## 🧠 Backend Architecture
- **Approach:** Local-only Swift 6 application layer using Structured Concurrency (async/await) for timer operations and hotkey handling
- **API Style:** No external API. Internal service communication via async/await and Observation bindings
- **Services:**
- TimerService: Core countdown logic using TimelineView scheduling
- HotkeyService: Global keyboard shortcut registration and handling
- WindowService: NSWindow.level management and position persistence
- NotificationService: Completion alerts with optional sound

## 🗄 Data Layer
- **Primary Store:** SwiftData for persisting user preferences, timer presets, and window position
- **Relationships:** Simple flat models: TimerPreset, UserPreferences, WindowPosition. No complex relationships required
- **Migrations:** SwiftData automatic lightweight migrations for preference schema evolution

## ☁️ Infrastructure
- **Hosting:** Local macOS application distributed via Mac App Store or direct download. No server infrastructure
- **Scaling Strategy:** Not applicable - single-user local application
- **CI/CD:** Xcode Cloud or GitHub Actions for build, test, and notarization

## ⚖️ Key Trade-offs
- Single timer simplicity over multi-timer complexity - reduces cognitive load and implementation scope
- SwiftUI 6 + AppKit hybrid over pure SwiftUI - required for NSWindow.level control and fullscreen overlay
- Local-first over cloud sync - eliminates network dependency and latency for core timer function
- TimelineView over manual Timer - provides precise frame-aligned updates with minimal CPU overhead
- Observation framework over Combine - simpler reactive patterns with Swift 6 concurrency integration

## 📐 Non-Functional Requirements
- macOS 15+ (Sequoia) minimum deployment target
- Sub-16ms frame time for animations using Metal acceleration
- Less than 1% CPU usage during idle countdown
- Memory footprint under 50MB
- Launch to visible timer in under 500ms
- Full Accessibility API compliance for VoiceOver users
- Timer overlay visible over fullscreen apps 100% of the time