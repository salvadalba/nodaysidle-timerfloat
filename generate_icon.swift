#!/usr/bin/env swift

import AppKit
import Foundation

// Generate app icon from SF Symbol with explicit pixel dimensions
func generateIcon(pixelSize: Int, outputPath: String) {
    // Create a bitmap context with exact pixel size (no scaling)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: pixelSize,
        height: pixelSize,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        print("Failed to create context for \(outputPath)")
        return
    }

    let rect = CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize)
    let cornerRadius = CGFloat(pixelSize) * 0.2

    // Background - rounded rectangle with gradient
    let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    context.addPath(path)
    context.clip()

    // Gradient background (blue to purple)
    let colors: [CGColor] = [
        CGColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0),
        CGColor(red: 0.4, green: 0.3, blue: 0.8, alpha: 1.0)
    ]

    guard let gradient = CGGradient(
        colorsSpace: colorSpace,
        colors: colors as CFArray,
        locations: [0, 1]
    ) else { return }

    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: CGFloat(pixelSize)),
        end: CGPoint(x: CGFloat(pixelSize), y: 0),
        options: []
    )

    // Draw timer symbol (white)
    context.resetClip()

    let symbolConfig = NSImage.SymbolConfiguration(pointSize: CGFloat(pixelSize) * 0.5, weight: .medium)
    if let timerSymbol = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)?
        .withSymbolConfiguration(symbolConfig) {

        // Get the symbol's CGImage
        var symbolRect = NSRect(origin: .zero, size: timerSymbol.size)
        guard let cgSymbol = timerSymbol.cgImage(forProposedRect: &symbolRect, context: nil, hints: nil) else { return }

        // Scale symbol to fit
        let symbolSize = CGFloat(pixelSize) * 0.55
        let symbolX = (CGFloat(pixelSize) - symbolSize) / 2
        let symbolY = (CGFloat(pixelSize) - symbolSize) / 2
        let drawRect = CGRect(x: symbolX, y: symbolY, width: symbolSize, height: symbolSize)

        // Set white color for symbol
        context.setBlendMode(.normal)
        context.draw(cgSymbol, in: drawRect)

        // Tint to white using overlay
        context.setBlendMode(.sourceAtop)
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(drawRect)
    }

    // Create image and save
    guard let cgImage = context.makeImage() else {
        print("Failed to create image for \(outputPath)")
        return
    }

    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(outputPath)")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("Generated: \(outputPath) (\(pixelSize)x\(pixelSize))")
    } catch {
        print("Failed to write \(outputPath): \(error)")
    }
}

let basePath = "/Users/archuser/Downloads/ndi/nodaysidle-timerfloat/TimerFloat/Assets.xcassets/AppIcon.appiconset"

// macOS app icon sizes (actual pixel dimensions)
let sizes: [(pixelSize: Int, name: String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

// Remove old icons first
let fileManager = FileManager.default
for item in sizes {
    let path = "\(basePath)/\(item.name)"
    try? fileManager.removeItem(atPath: path)
}

for item in sizes {
    generateIcon(pixelSize: item.pixelSize, outputPath: "\(basePath)/\(item.name)")
}

print("Icon generation complete!")
