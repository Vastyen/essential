import AppKit
import CoreGraphics

let size: CGFloat = 512
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high

// Draw gradient background
let gradient = NSGradient(colors: [
    NSColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1.0),
    NSColor(red: 0.5, green: 0.3, blue: 0.8, alpha: 1.0)
])

let rect = NSRect(origin: .zero, size: NSSize(width: size, height: size))
gradient?.draw(in: rect, angle: 135)

// Draw text
let text = "</>"
let font = NSFont.monospacedSystemFont(ofSize: size * 0.5, weight: .bold)
let attributes: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white
]
let attrString = NSAttributedString(string: text, attributes: attributes)
let textSize = attrString.size()
let textRect = NSRect(
    x: (size - textSize.width) / 2,
    y: (size - textSize.height) / 2,
    width: textSize.width,
    height: textSize.height
)
attrString.draw(in: textRect)

image.unlockFocus()

// Save
let tiff = image.tiffRepresentation!
let bitmap = NSBitmapImageRep(data: tiff)!
let png = bitmap.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "/tmp/test_icon.png"))
print("✅ Test icon saved to /tmp/test_icon.png")
