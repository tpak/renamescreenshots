#!/usr/bin/env swift
//
// generate-icon.swift
// Generates AppIcon.icns from SF Symbol camera.fill
//

import Cocoa

let sizes: [(Int, String)] = [
    (16, "icon_16x16"),
    (32, "icon_16x16@2x"),
    (32, "icon_32x32"),
    (64, "icon_32x32@2x"),
    (128, "icon_128x128"),
    (256, "icon_128x128@2x"),
    (256, "icon_256x256"),
    (512, "icon_256x256@2x"),
    (512, "icon_512x512"),
    (1024, "icon_512x512@2x"),
]

// Create iconset directory
let iconsetPath = "AppIcon.iconset"
let fm = FileManager.default

if fm.fileExists(atPath: iconsetPath) {
    try? fm.removeItem(atPath: iconsetPath)
}
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Generate each size
for (size, name) in sizes {
    let cgSize = CGFloat(size)

    // Create image with SF Symbol
    guard let symbol = NSImage(systemSymbolName: "camera.fill", accessibilityDescription: nil) else {
        print("Failed to load SF Symbol")
        exit(1)
    }

    // Configure symbol
    let config = NSImage.SymbolConfiguration(pointSize: cgSize * 0.6, weight: .regular)
    guard let configuredSymbol = symbol.withSymbolConfiguration(config) else {
        print("Failed to configure symbol")
        exit(1)
    }

    // Create the final image with padding and background
    let image = NSImage(size: NSSize(width: cgSize, height: cgSize))
    image.lockFocus()

    // Draw rounded rect background
    let bgRect = NSRect(x: 0, y: 0, width: cgSize, height: cgSize)
    let cornerRadius = cgSize * 0.2
    let path = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient background (blue to purple like many macOS apps)
    let gradient = NSGradient(colors: [
        NSColor(red: 0.2, green: 0.5, blue: 0.9, alpha: 1.0),
        NSColor(red: 0.4, green: 0.3, blue: 0.8, alpha: 1.0),
    ])!
    gradient.draw(in: path, angle: -45)

    // Draw the symbol centered in white
    let symbolSize = configuredSymbol.size
    let symbolX = (cgSize - symbolSize.width) / 2
    let symbolY = (cgSize - symbolSize.height) / 2

    // Tint to white
    let tintedSymbol = configuredSymbol.copy() as! NSImage
    tintedSymbol.lockFocus()
    NSColor.white.set()
    NSRect(origin: .zero, size: tintedSymbol.size).fill(using: .sourceAtop)
    tintedSymbol.unlockFocus()

    tintedSymbol.draw(
        in: NSRect(x: symbolX, y: symbolY, width: symbolSize.width, height: symbolSize.height),
        from: .zero,
        operation: .sourceOver,
        fraction: 1.0
    )

    image.unlockFocus()

    // Save as PNG
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(name)")
        exit(1)
    }

    let pngPath = "\(iconsetPath)/\(name).png"
    try! pngData.write(to: URL(fileURLWithPath: pngPath))
    print("Created \(pngPath)")
}

print("\nConverting to icns...")

// Use iconutil to create icns
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetPath]

try! process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    // Move to Resources
    let destPath = "Sources/ScreenshotRenamer/Resources/AppIcon.icns"
    if fm.fileExists(atPath: destPath) {
        try? fm.removeItem(atPath: destPath)
    }
    try! fm.moveItem(atPath: "AppIcon.icns", toPath: destPath)

    // Cleanup
    try? fm.removeItem(atPath: iconsetPath)

    print("✅ Created \(destPath)")
} else {
    print("❌ iconutil failed with exit code \(process.terminationStatus)")
    exit(1)
}
