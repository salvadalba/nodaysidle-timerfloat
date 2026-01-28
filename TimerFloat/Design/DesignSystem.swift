import SwiftUI

// MARK: - TimerFloat Design System
// A curated design system for consistent, distinctive aesthetics

// MARK: - Color Palette

extension Color {
    /// TimerFloat brand colors - "Time as Resource" theme
    enum TimerFloat {
        // Primary accent - Indigo (productive, focused, valuable)
        static let primary = Color(red: 0.39, green: 0.40, blue: 0.95)       // #6366F1
        static let primaryLight = Color(red: 0.51, green: 0.52, blue: 0.98) // #818CF8
        static let primaryDark = Color(red: 0.31, green: 0.32, blue: 0.85)  // #4F46E5

        // Warning - Amber (time running low, attention needed)
        static let warning = Color(red: 0.96, green: 0.62, blue: 0.04)      // #F59E0B
        static let warningLight = Color(red: 0.99, green: 0.75, blue: 0.28) // #FCD34D

        // Urgent - Red (time critical, running out)
        static let urgent = Color(red: 0.94, green: 0.27, blue: 0.27)       // #EF4444
        static let urgentLight = Color(red: 0.99, green: 0.45, blue: 0.45)  // #F87171

        // Complete - Emerald (time well spent, success)
        static let complete = Color(red: 0.06, green: 0.73, blue: 0.51)     // #10B981
        static let completeLight = Color(red: 0.20, green: 0.83, blue: 0.60) // #34D399

        // Stopwatch - Teal (distinct from countdown, flowing time)
        static let stopwatch = Color(red: 0.08, green: 0.65, blue: 0.65)    // #14A3A3
        static let stopwatchLight = Color(red: 0.17, green: 0.75, blue: 0.75) // #2DD4D4

        // Neutrals
        static let backgroundOverlay = Color.black.opacity(0.05)
        static let ringBackground = Color.primary.opacity(0.1)

        // Celebration glow colors
        static let celebrationGlow = Color(red: 1.0, green: 0.84, blue: 0.0) // Golden
        static let celebrationWarm = Color(red: 1.0, green: 0.6, blue: 0.2)  // Warm orange
    }
}

// MARK: - Typography

/// Custom font management for IBM Plex Mono
enum TimerTypography {
    /// Font names as registered in the system
    private static let plexMonoRegular = "IBMPlexMono-Regular"
    private static let plexMonoMedium = "IBMPlexMono-Medium"
    private static let plexMonoSemiBold = "IBMPlexMono-SemiBold"

    /// Large time display (main overlay)
    static func timeDisplay(size: CGFloat = 24) -> Font {
        .custom(plexMonoSemiBold, size: size, relativeTo: .title)
    }

    /// Medium time display (popover)
    static func timeMedium(size: CGFloat = 28) -> Font {
        .custom(plexMonoSemiBold, size: size, relativeTo: .title2)
    }

    /// Large time display for active timer view
    static func timeLarge(size: CGFloat = 32) -> Font {
        .custom(plexMonoSemiBold, size: size, relativeTo: .largeTitle)
    }

    /// Stopwatch time with milliseconds
    static func stopwatchDisplay(size: CGFloat = 22) -> Font {
        .custom(plexMonoMedium, size: size, relativeTo: .title2)
    }

    /// Small labels
    static func label(size: CGFloat = 12) -> Font {
        .custom(plexMonoRegular, size: size, relativeTo: .caption)
    }

    /// Fallback to system monospaced if custom font fails
    static func timeDisplayFallback(size: CGFloat = 24) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

// MARK: - Shape Styles

/// Custom shapes for timer and stopwatch
struct TimerRingShape: Shape {
    var progress: CGFloat
    var lineWidth: CGFloat
    var taperFactor: CGFloat = 0.5 // How much the tail tapers (0 = no taper, 1 = full taper)

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2

        // Start angle at top (-90 degrees)
        let startAngle = Angle(degrees: -90)
        let endAngle = Angle(degrees: -90 + 360 * Double(progress))

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path
    }
}

/// Progress ring view with variable thickness (thicker at head, tapers at tail)
struct TaperedProgressRing: View {
    let progress: CGFloat
    let baseWidth: CGFloat
    let color: Color
    let size: CGFloat

    private let segmentCount = 60

    var body: some View {
        ZStack {
            ForEach(0..<segmentCount, id: \.self) { index in
                let segmentProgress = CGFloat(index) / CGFloat(segmentCount)
                if segmentProgress <= progress {
                    let distanceFromHead = progress - segmentProgress
                    let widthMultiplier = max(0.5, 1.0 - (distanceFromHead * 0.8))
                    let segmentWidth = baseWidth * widthMultiplier

                    Circle()
                        .trim(
                            from: segmentProgress,
                            to: segmentProgress + (1.0 / CGFloat(segmentCount)) + 0.002
                        )
                        .stroke(
                            color.opacity(0.8 + (0.2 * (1.0 - distanceFromHead / max(progress, 0.01)))),
                            style: StrokeStyle(lineWidth: segmentWidth, lineCap: .round)
                        )
                        .frame(width: size, height: size)
                        .rotationEffect(.degrees(-90))
                }
            }
        }
    }
}

// MARK: - Gradient Definitions

extension LinearGradient {
    /// Progress ring gradient based on time state
    static func timerProgress(progress: CGFloat) -> LinearGradient {
        let colors: [Color]

        switch progress {
        case 0.9...:
            // Critical - red gradient
            colors = [Color.TimerFloat.urgent, Color.TimerFloat.urgentLight]
        case 0.75..<0.9:
            // Warning - amber gradient
            colors = [Color.TimerFloat.warning, Color.TimerFloat.warningLight]
        default:
            // Normal - indigo gradient
            colors = [Color.TimerFloat.primary, Color.TimerFloat.primaryLight]
        }

        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Stopwatch gradient
    static var stopwatchProgress: LinearGradient {
        LinearGradient(
            colors: [Color.TimerFloat.stopwatch, Color.TimerFloat.stopwatchLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Completion celebration gradient
    static var celebration: LinearGradient {
        LinearGradient(
            colors: [Color.TimerFloat.complete, Color.TimerFloat.completeLight],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

extension AngularGradient {
    /// Circular gradient for progress ring
    static func timerRing(progress: CGFloat) -> AngularGradient {
        let baseColor: Color
        let lightColor: Color

        switch progress {
        case 0.9...:
            baseColor = Color.TimerFloat.urgent
            lightColor = Color.TimerFloat.urgentLight
        case 0.75..<0.9:
            baseColor = Color.TimerFloat.warning
            lightColor = Color.TimerFloat.warningLight
        default:
            baseColor = Color.TimerFloat.primary
            lightColor = Color.TimerFloat.primaryLight
        }

        return AngularGradient(
            gradient: Gradient(colors: [
                lightColor.opacity(0.3),
                baseColor,
                lightColor
            ]),
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(-90 + 360 * Double(progress))
        )
    }
}

// MARK: - Animation Constants

enum TimerAnimations {
    /// Standard hover transition
    static let hover = Animation.easeInOut(duration: 0.2)

    /// Button press feedback
    static let press = Animation.easeOut(duration: 0.1)

    /// Progress ring update
    static let progress = Animation.linear(duration: 0.1)

    /// Completion celebration
    static let celebration = Animation.spring(response: 0.4, dampingFraction: 0.6)

    /// Glow pulse
    static let glowPulse = Animation.easeInOut(duration: 0.6).repeatForever(autoreverses: true)
}

// MARK: - Design Constants

enum TimerDesign {
    /// Overlay dimensions
    static let overlaySize: CGFloat = 120
    static let progressSize: CGFloat = 100
    static let progressLineWidth: CGFloat = 6
    static let progressLineWidthThick: CGFloat = 8
    static let progressLineWidthThin: CGFloat = 4

    /// Stopwatch dimensions (pill shape)
    static let stopwatchWidth: CGFloat = 140
    static let stopwatchHeight: CGFloat = 100
    static let stopwatchCornerRadius: CGFloat = 24

    /// Corner radii
    static let overlayCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 8

    /// Shadows
    static let overlayShadowRadius: CGFloat = 8
    static let overlayShadowY: CGFloat = 4
    static let overlayShadowOpacity: Double = 0.2

    /// Hover effects
    static let hoverScale: CGFloat = 1.02
    static let pressScale: CGFloat = 0.96

    /// Glow effects
    static let glowRadius: CGFloat = 15
    static let celebrationGlowRadius: CGFloat = 25
}

// MARK: - Reusable View Components

/// Glowing endpoint indicator for progress ring
struct ProgressEndpoint: View {
    let progress: CGFloat
    let radius: CGFloat
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
            .shadow(color: color.opacity(0.6), radius: 4)
            .offset(endpointOffset)
    }

    private var endpointOffset: CGSize {
        let angle = Angle(degrees: -90 + 360 * Double(progress))
        let x = cos(angle.radians) * radius
        let y = sin(angle.radians) * radius
        return CGSize(width: x, height: y)
    }
}

/// Subtle tick marks around progress ring
struct TickMarks: View {
    let count: Int
    let radius: CGFloat
    let color: Color

    var body: some View {
        ForEach(0..<count, id: \.self) { index in
            let angle = Angle(degrees: Double(index) * (360.0 / Double(count)) - 90)
            let isMajor = index % (count / 4) == 0

            Rectangle()
                .fill(color.opacity(isMajor ? 0.4 : 0.2))
                .frame(width: isMajor ? 2 : 1, height: isMajor ? 8 : 4)
                .offset(y: -radius + (isMajor ? 4 : 2))
                .rotationEffect(angle)
        }
    }
}

// MARK: - Button Styles

/// Animated button style with press feedback
struct TimerButtonStyle: ButtonStyle {
    let isPrimary: Bool

    init(isPrimary: Bool = true) {
        self.isPrimary = isPrimary
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? TimerDesign.pressScale : 1.0)
            .animation(TimerAnimations.press, value: configuration.isPressed)
    }
}

/// Preset button with custom styling
struct PresetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, design: .rounded, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: TimerDesign.buttonCornerRadius)
                    .fill(Color.TimerFloat.primary)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? TimerDesign.pressScale : 1.0)
            .animation(TimerAnimations.press, value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply standard overlay shadow
    func overlayShadow() -> some View {
        self.shadow(
            color: .black.opacity(TimerDesign.overlayShadowOpacity),
            radius: TimerDesign.overlayShadowRadius,
            x: 0,
            y: TimerDesign.overlayShadowY
        )
    }

    /// Apply hover scale effect
    func hoverScale(_ isHovered: Bool) -> some View {
        self.scaleEffect(isHovered ? TimerDesign.hoverScale : 1.0)
            .animation(TimerAnimations.hover, value: isHovered)
    }

    /// Apply press scale effect
    func pressScale(_ isPressed: Bool) -> some View {
        self.scaleEffect(isPressed ? TimerDesign.pressScale : 1.0)
            .animation(TimerAnimations.press, value: isPressed)
    }
}
