// Renders the app icon: the KEXP four-bar mark in orange on black.
// Usage: swift scripts/make-icon.swift App/Assets.xcassets/AppIcon.appiconset
import AppKit

let outDir = URL(fileURLWithPath: CommandLine.arguments[1])
let orange = NSColor(srgbRed: 0xF2/255.0, green: 0xA9/255.0, blue: 0x3B/255.0, alpha: 1)

func render(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(px)
    NSColor.black.setFill()
    NSRect(x: 0, y: 0, width: s, height: s).fill()

    // Mark is 130×112 units; fit it to 56% of the icon width, centered.
    let markW = s * 0.56, unit = markW / 130, markH = 112 * unit
    let ox = (s - markW) / 2, oy = (s - markH) / 2
    orange.setFill()
    for (x, y, h) in [(0.0, 12.0, 100.0), (35, 39, 73), (69, 0, 112), (104, 22, 90)] {
        // SVG y is top-down; flip into AppKit's bottom-up space.
        let top = oy + markH - CGFloat(y) * unit
        NSRect(x: ox + CGFloat(x) * unit, y: top - CGFloat(h) * unit,
               width: 25 * unit, height: CGFloat(h) * unit).fill()
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

var images: [[String: String]] = []
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(size)x\(size)\(scale == 2 ? "@2x" : "").png"
        try! render(size * scale).write(to: outDir.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try! JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: outDir.appendingPathComponent("Contents.json"))
print("Wrote \(images.count) icons to \(outDir.path)")
