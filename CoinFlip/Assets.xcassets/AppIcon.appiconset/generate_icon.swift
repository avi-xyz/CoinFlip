import AppKit
import CoreGraphics

let size: CGFloat = 1024
let rect = CGRect(x: 0, y: 0, width: size, height: size)

// Create image context
guard let context = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    print("Failed to create context")
    exit(1)
}

// Rich black background with subtle gradient
let bgColors = [
    CGColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 1.0),
    CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
]
let bgGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: bgColors as CFArray,
    locations: [0.0, 1.0]
)!
context.drawRadialGradient(
    bgGradient,
    startCenter: CGPoint(x: size/2, y: size/2),
    startRadius: 0,
    endCenter: CGPoint(x: size/2, y: size/2),
    endRadius: size * 0.7,
    options: []
)

let center = CGPoint(x: size/2, y: size/2)
let coinRadius: CGFloat = size * 0.36

// Add dramatic glow/rays behind coin
context.saveGState()
let rayColors = [
    CGColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 0.3),
    CGColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 0.0)
]
let rayGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: rayColors as CFArray,
    locations: [0.0, 1.0]
)!
context.drawRadialGradient(
    rayGradient,
    startCenter: center,
    startRadius: coinRadius * 0.8,
    endCenter: center,
    endRadius: size * 0.6,
    options: []
)
context.restoreGState()

// Outer shadow/glow for depth
context.setFillColor(CGColor(red: 0.5, green: 0.35, blue: 0.1, alpha: 0.4))
context.fillEllipse(in: CGRect(
    x: center.x - coinRadius * 1.08 + 15,
    y: center.y - coinRadius * 1.08 + 15,
    width: coinRadius * 2.16,
    height: coinRadius * 2.16
))

// Coin base - dark gold for 3D effect
context.setFillColor(CGColor(red: 0.65, green: 0.45, blue: 0.15, alpha: 1.0))
context.fillEllipse(in: CGRect(
    x: center.x - coinRadius * 1.04,
    y: center.y - coinRadius * 1.04,
    width: coinRadius * 2.08,
    height: coinRadius * 2.08
))

// Main coin body - true metallic gold gradient
context.saveGState()
let goldColors = [
    CGColor(red: 1.0, green: 0.84, blue: 0.4, alpha: 1.0),    // Bright gold top
    CGColor(red: 0.85, green: 0.65, blue: 0.25, alpha: 1.0),  // Rich gold middle
    CGColor(red: 0.72, green: 0.52, blue: 0.18, alpha: 1.0),  // Dark gold bottom
]
let goldGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: goldColors as CFArray,
    locations: [0.0, 0.5, 1.0]
)!

context.saveGState()
context.addEllipse(in: CGRect(
    x: center.x - coinRadius,
    y: center.y - coinRadius,
    width: coinRadius * 2,
    height: coinRadius * 2
))
context.clip()
context.drawLinearGradient(
    goldGradient,
    start: CGPoint(x: center.x, y: center.y - coinRadius),
    end: CGPoint(x: center.x, y: center.y + coinRadius),
    options: []
)
context.restoreGState()

// Outer ring - bright highlight
context.setStrokeColor(CGColor(red: 1.0, green: 0.92, blue: 0.6, alpha: 1.0))
context.setLineWidth(8)
context.strokeEllipse(in: CGRect(
    x: center.x - coinRadius * 0.96,
    y: center.y - coinRadius * 0.96,
    width: coinRadius * 1.92,
    height: coinRadius * 1.92
))

// Inner decorative ring
context.setStrokeColor(CGColor(red: 0.7, green: 0.5, blue: 0.15, alpha: 1.0))
context.setLineWidth(3)
context.strokeEllipse(in: CGRect(
    x: center.x - coinRadius * 0.88,
    y: center.y - coinRadius * 0.88,
    width: coinRadius * 1.76,
    height: coinRadius * 1.76
))

// Center circle background for symbol
let symbolRadius = coinRadius * 0.75
context.setFillColor(CGColor(red: 0.92, green: 0.75, blue: 0.35, alpha: 1.0))
context.fillEllipse(in: CGRect(
    x: center.x - symbolRadius,
    y: center.y - symbolRadius,
    width: symbolRadius * 2,
    height: symbolRadius * 2
))

// Inner gradient for center
context.saveGState()
context.addEllipse(in: CGRect(
    x: center.x - symbolRadius * 0.92,
    y: center.y - symbolRadius * 0.92,
    width: symbolRadius * 1.84,
    height: symbolRadius * 1.84
))
context.clip()

let innerColors = [
    CGColor(red: 1.0, green: 0.88, blue: 0.5, alpha: 1.0),
    CGColor(red: 0.88, green: 0.68, blue: 0.3, alpha: 1.0),
]
let innerGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: innerColors as CFArray,
    locations: [0.0, 1.0]
)!
context.drawLinearGradient(
    innerGradient,
    start: CGPoint(x: center.x, y: center.y - symbolRadius * 0.92),
    end: CGPoint(x: center.x, y: center.y + symbolRadius * 0.92),
    options: []
)
context.restoreGState()

// Draw bold $ symbol
context.setFillColor(CGColor(red: 0.5, green: 0.35, blue: 0.1, alpha: 1.0))

// Vertical bar of $
let dollarWidth: CGFloat = symbolRadius * 0.18
let dollarHeight: CGFloat = symbolRadius * 1.3
context.fill(CGRect(
    x: center.x - dollarWidth/2,
    y: center.y - dollarHeight/2,
    width: dollarWidth,
    height: dollarHeight
))

// S curves - make them bold
context.setLineWidth(symbolRadius * 0.18)
context.setStrokeColor(CGColor(red: 0.5, green: 0.35, blue: 0.1, alpha: 1.0))

// Top S
context.addArc(
    center: CGPoint(x: center.x, y: center.y - symbolRadius * 0.25),
    radius: symbolRadius * 0.4,
    startAngle: .pi * 0.3,
    endAngle: .pi * 1.7,
    clockwise: false
)
context.strokePath()

// Bottom S
context.addArc(
    center: CGPoint(x: center.x, y: center.y + symbolRadius * 0.25),
    radius: symbolRadius * 0.4,
    startAngle: .pi * 1.3,
    endAngle: .pi * 2.7,
    clockwise: false
)
context.strokePath()

// Dramatic highlight on top-left for metallic look
context.saveGState()
let highlightColors = [
    CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7),
    CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
]
let highlightGradient = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: highlightColors as CFArray,
    locations: [0.0, 1.0]
)!

context.addArc(
    center: center,
    radius: coinRadius,
    startAngle: .pi * 1.2,
    endAngle: .pi * 1.8,
    clockwise: false
)
context.addLine(to: center)
context.closePath()
context.clip()

context.drawRadialGradient(
    highlightGradient,
    startCenter: CGPoint(x: center.x - coinRadius * 0.4, y: center.y - coinRadius * 0.4),
    startRadius: 0,
    endCenter: CGPoint(x: center.x - coinRadius * 0.4, y: center.y - coinRadius * 0.4),
    endRadius: coinRadius * 0.8,
    options: []
)
context.restoreGState()

// Bright sparkle highlights
context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9))
// Top sparkle
context.fill(CGRect(
    x: center.x - coinRadius * 0.5 - 3,
    y: center.y - coinRadius * 0.6 - 20,
    width: 6,
    height: 40
))
context.fill(CGRect(
    x: center.x - coinRadius * 0.5 - 20,
    y: center.y - coinRadius * 0.6 - 3,
    width: 40,
    height: 6
))

// Second sparkle
context.setFillColor(CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.7))
context.fill(CGRect(
    x: center.x + coinRadius * 0.35 - 2,
    y: center.y - coinRadius * 0.5 - 15,
    width: 4,
    height: 30
))
context.fill(CGRect(
    x: center.x + coinRadius * 0.35 - 15,
    y: center.y - coinRadius * 0.5 - 2,
    width: 30,
    height: 4
))

// Bottom right shine
context.fillEllipse(in: CGRect(
    x: center.x + coinRadius * 0.3,
    y: center.y + coinRadius * 0.35,
    width: 35,
    height: 35
))

context.restoreGState()

// Create image from context
guard let cgImage = context.makeImage() else {
    print("Failed to create image")
    exit(1)
}

let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))

// Save as PNG
guard let tiffData = nsImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    print("Failed to create PNG data")
    exit(1)
}

try! pngData.write(to: URL(fileURLWithPath: "/tmp/app_icon_1024.png"))
print("✅ Metallic gold coin icon created: /tmp/app_icon_1024.png")
