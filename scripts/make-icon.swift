// Draws Lane's 1024px app icon: a soft gradient tile with a branching path.
// Usage: swift scripts/make-icon.swift <output.png>
import AppKit

let size: CGFloat = 1024
let output = CommandLine.arguments.dropFirst().first ?? "icon.png"

let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { _ in
    let inset: CGFloat = 100
    let tile = NSRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let shape = NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185)

    NSGraphicsContext.current?.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.25)
    shadow.shadowOffset = NSSize(width: 0, height: -12)
    shadow.shadowBlurRadius = 28
    shadow.set()
    NSColor.white.setFill()
    shape.fill()
    NSGraphicsContext.current?.restoreGraphicsState()

    NSGradient(colors: [
        NSColor(calibratedRed: 0.13, green: 0.55, blue: 0.47, alpha: 1),
        NSColor(calibratedRed: 0.07, green: 0.29, blue: 0.36, alpha: 1),
    ])!.draw(in: shape, angle: -90)

    let config = NSImage.SymbolConfiguration(pointSize: 440, weight: .semibold)
        .applying(.init(paletteColors: [.white]))
    if let symbol = NSImage(systemSymbolName: "arrow.triangle.branch", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let s = symbol.size
        symbol.draw(in: NSRect(x: (size - s.width) / 2, y: (size - s.height) / 2, width: s.width, height: s.height))
    }
    return true
}

guard let tiff = image.tiffRepresentation,
      let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:])
else { fatalError("could not render icon") }
try png.write(to: URL(fileURLWithPath: output))
