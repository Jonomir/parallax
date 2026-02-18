import AppKit

struct IconSlot {
    let filename: String
    let pixels: Int
}

let slots: [IconSlot] = [
    .init(filename: "icon_16x16.png", pixels: 16),
    .init(filename: "icon_16x16@2x.png", pixels: 32),
    .init(filename: "icon_32x32.png", pixels: 32),
    .init(filename: "icon_32x32@2x.png", pixels: 64),
    .init(filename: "icon_128x128.png", pixels: 128),
    .init(filename: "icon_128x128@2x.png", pixels: 256),
    .init(filename: "icon_256x256.png", pixels: 256),
    .init(filename: "icon_256x256@2x.png", pixels: 512),
    .init(filename: "icon_512x512.png", pixels: 512),
    .init(filename: "icon_512x512@2x.png", pixels: 1024)
]

func drawBackground(size: CGFloat) {
    let outerInset = size * 0.04
    let rect = CGRect(x: outerInset, y: outerInset, width: size - (outerInset * 2), height: size - (outerInset * 2))
    let rounded = NSBezierPath(roundedRect: rect, xRadius: size * 0.22, yRadius: size * 0.22)
    NSColor(calibratedRed: 0.82, green: 0.86, blue: 0.89, alpha: 1.0).setFill()
    rounded.fill()

    let gridColor = NSColor(calibratedRed: 1.0, green: 1.0, blue: 1.0, alpha: 0.22)
    gridColor.setStroke()
    let grid = NSBezierPath()
    grid.lineWidth = max(1.0, size * 0.006)

    let inset = size * 0.11
    let gridRect = CGRect(x: inset, y: inset, width: size - (inset * 2), height: size - (inset * 2))
    let step = size * 0.09

    var x = gridRect.minX
    while x <= gridRect.maxX {
        grid.move(to: CGPoint(x: x, y: gridRect.minY))
        grid.line(to: CGPoint(x: x, y: gridRect.maxY))
        x += step
    }

    var y = gridRect.minY
    while y <= gridRect.maxY {
        grid.move(to: CGPoint(x: gridRect.minX, y: y))
        grid.line(to: CGPoint(x: gridRect.maxX, y: y))
        y += step
    }

    grid.stroke()
}

func drawParallaxGlyph(size: CGFloat) {
    let symbolPointSize = size * 0.44
    let symbolConfig = NSImage.SymbolConfiguration(pointSize: symbolPointSize, weight: .regular)
    guard
        let symbolBase = NSImage(systemSymbolName: "square.on.square.intersection.dashed", accessibilityDescription: nil),
        let symbol = symbolBase.withSymbolConfiguration(symbolConfig)
    else {
        return
    }

    let tinted = NSImage(size: symbol.size)
    tinted.lockFocus()
    symbol.draw(
        in: NSRect(origin: .zero, size: symbol.size),
        from: NSRect(origin: .zero, size: symbol.size),
        operation: .sourceOver,
        fraction: 1.0
    )
    if let context = NSGraphicsContext.current?.cgContext {
        context.setBlendMode(.sourceAtop)
        context.setFillColor(NSColor(calibratedRed: 0.08, green: 0.63, blue: 0.97, alpha: 1.0).cgColor)
        context.fill(CGRect(origin: .zero, size: symbol.size))
    }
    tinted.unlockFocus()

    let glyphSize = size * 0.62
    let glyphRect = CGRect(
        x: (size - glyphSize) / 2,
        y: (size - glyphSize) / 2,
        width: glyphSize,
        height: glyphSize
    )

    tinted.draw(
        in: glyphRect,
        from: NSRect(origin: .zero, size: tinted.size),
        operation: NSCompositingOperation.sourceOver,
        fraction: 1.0,
        respectFlipped: false,
        hints: [NSImageRep.HintKey.interpolation: NSImageInterpolation.high]
    )
}

func masterImage(size: CGFloat = 1024) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()
    drawBackground(size: size)
    drawParallaxGlyph(size: size)
    image.unlockFocus()
    return image
}

func renderPNG(master: NSImage, pixels: Int, to url: URL) throws {
    guard let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixels,
        pixelsHigh: pixels,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        throw NSError(domain: "IconGen", code: 2)
    }

    bitmap.size = NSSize(width: pixels, height: pixels)

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
        NSGraphicsContext.restoreGraphicsState()
        throw NSError(domain: "IconGen", code: 3)
    }

    NSGraphicsContext.current = context
    NSColor.clear.setFill()
    NSRect(x: 0, y: 0, width: pixels, height: pixels).fill()
    master.draw(
        in: NSRect(x: 0, y: 0, width: pixels, height: pixels),
        from: NSRect(origin: .zero, size: master.size),
        operation: NSCompositingOperation.sourceOver,
        fraction: 1.0,
        respectFlipped: false,
        hints: [NSImageRep.HintKey.interpolation: NSImageInterpolation.high]
    )
    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    guard let png = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "IconGen", code: 4)
    }
    try png.write(to: url)
}

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: swift scripts/generate_app_icon.swift <AppIcon.appiconset path>\n", stderr)
    exit(1)
}

let iconset = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fileManager = FileManager.default
var isDirectory: ObjCBool = false
guard fileManager.fileExists(atPath: iconset.path, isDirectory: &isDirectory), isDirectory.boolValue else {
    fputs("Invalid app icon set path: \(iconset.path)\n", stderr)
    exit(1)
}

let master = masterImage()
for slot in slots {
    let target = iconset.appendingPathComponent(slot.filename)
    try renderPNG(master: master, pixels: slot.pixels, to: target)
    print("Generated \(slot.filename)")
}
