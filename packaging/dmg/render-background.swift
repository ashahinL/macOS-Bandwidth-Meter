// Draws the disk image window background. The PNGs it writes are committed,
// so a release build does not run this. Run `make dmg-background` after
// changing the text or the layout in packaging/dmg/settings.py.
//
//   swift packaging/dmg/render-background.swift <output-dir>
//
// Writes background.png (640 x 400) and background@2x.png (1280 x 800).
// The icon centres in settings.py are (190, 200) and (450, 200).

import AppKit

let width: CGFloat = 640
let height: CGFloat = 400
let accent = NSColor(srgbRed: 0x1f / 255.0, green: 0x6f / 255.0, blue: 0xeb / 255.0, alpha: 1)
let ink = NSColor(srgbRed: 0.11, green: 0.12, blue: 0.14, alpha: 1)
let muted = NSColor(srgbRed: 0.40, green: 0.43, blue: 0.47, alpha: 1)

func draw(_ text: String, size: CGFloat, weight: NSFont.Weight, color: NSColor, centreX: CGFloat, top: CGFloat, maxWidth: CGFloat) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    paragraph.lineSpacing = 2
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]
    let string = NSAttributedString(string: text, attributes: attributes)
    let bounds = string.boundingRect(with: NSSize(width: maxWidth, height: 200), options: [.usesLineFragmentOrigin])
    string.draw(with: NSRect(x: centreX - maxWidth / 2, y: top, width: maxWidth, height: ceil(bounds.height)), options: [.usesLineFragmentOrigin])
}

func render(scale: CGFloat) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(width * scale), pixelsHigh: Int(height * scale),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: width, height: height)

    NSGraphicsContext.saveGraphicsState()
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    // Top-left origin, the same as Finder's icon positions.
    let cg = context.cgContext
    cg.translateBy(x: 0, y: height)
    cg.scaleBy(x: 1, y: -1)
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: true)

    NSColor(srgbRed: 0.965, green: 0.972, blue: 0.98, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: width, height: height).fill()

    accent.setFill()
    NSRect(x: 0, y: 0, width: width, height: 4).fill()

    draw("Bandwidth Meter", size: 24, weight: .semibold, color: ink, centreX: width / 2, top: 30, maxWidth: 560)
    draw("Double-click Install to add the menu bar app and the bandwidth-meter command.",
         size: 13, weight: .regular, color: muted, centreX: width / 2, top: 66, maxWidth: 600)

    // Soft tile behind the installer so it reads as the main action.
    let tile = NSBezierPath(roundedRect: NSRect(x: 190 - 85, y: 200 - 75, width: 170, height: 170), xRadius: 18, yRadius: 18)
    accent.withAlphaComponent(0.08).setFill()
    tile.fill()
    accent.withAlphaComponent(0.25).setStroke()
    tile.lineWidth = 1
    tile.stroke()

    NSColor(srgbRed: 0.85, green: 0.87, blue: 0.9, alpha: 1).setFill()
    NSRect(x: 40, y: 318, width: width - 80, height: 1).fill()

    draw("macOS says it can't verify the installer? Open System Settings › Privacy & Security,\nscroll down to Security, and click Open Anyway.",
         size: 11.5, weight: .regular, color: muted, centreX: width / 2, top: 332, maxWidth: 580)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let args = CommandLine.arguments
guard args.count == 2 else {
    FileHandle.standardError.write("usage: render-background.swift <output-dir>\n".data(using: .utf8)!)
    exit(2)
}
let dir = URL(fileURLWithPath: args[1], isDirectory: true)
try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
try render(scale: 1).write(to: dir.appendingPathComponent("background.png"))
try render(scale: 2).write(to: dir.appendingPathComponent("background@2x.png"))
print("wrote \(dir.path)/background.png and background@2x.png")
