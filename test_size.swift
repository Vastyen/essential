import AppKit

let size: CGFloat = 16
let image = NSImage(size: NSSize(width: size, height: size))

image.lockFocus()
NSGraphicsContext.current?.imageInterpolation = .high

// Draw red background to see the actual size
NSColor.red.setFill()
NSRect(origin: .zero, size: NSSize(width: size, height: size)).fill()

image.unlockFocus()

let tiff = image.tiffRepresentation!
let bitmap = NSBitmapImageRep(data: tiff)!
let png = bitmap.representation(using: .png, properties: [:])!
try! png.write(to: URL(fileURLWithPath: "/tmp/test_size_16.png"))
print("Test icon saved. Checking size...")
