# Agent Prompts — TimerFloat

## 🧭 Global Rules

### ✅ Do
- Use Swift 6 with strict concurrency checking enabled
- Target macOS 15+ (Sequoia) exclusively
- Apply @Observable macro for all ViewModels
- Use os.Logger for all logging with subsystem 'com.timerfloat'
- Make all shared state Sendable for concurrency safety

### ❌ Don't
- Do not use Combine - use Observation framework and AsyncStream instead
- Do not create server backends - this is local-first only
- Do not use third-party dependencies - stick to Apple frameworks
- Do not support macOS versions below 15
- Do not use AppKit unless NSWindow customization requires it

## 🧩 Task Prompts
## Project Foundation & Menu Bar Setup

**Context**
Create the base macOS menu bar app with SwiftUI App lifecycle, proper Info.plist configuration, and folder structure

### Universal Agent Prompt
```
_No prompt generated_
```