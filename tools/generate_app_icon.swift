import AppKit

let destination = CommandLine.arguments.dropFirst().first ?? "FutureEcho/Assets.xcassets/AppIcon.appiconset/FutureEchoIcon.png"
let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else {
    fatalError("Unable to create icon graphics context")
}

let bounds = CGRect(origin: .zero, size: size)
let colors = [
    NSColor(calibratedRed: 16 / 255, green: 24 / 255, blue: 39 / 255, alpha: 1).cgColor,
    NSColor(calibratedRed: 28 / 255, green: 42 / 255, blue: 61 / 255, alpha: 1).cgColor
] as CFArray
let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
context.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 1024, y: 1024), options: [])

context.setLineCap(.round)
let coral = NSColor(calibratedRed: 242 / 255, green: 125 / 255, blue: 106 / 255, alpha: 1).cgColor
let mist = NSColor(calibratedRed: 123 / 255, green: 199 / 255, blue: 196 / 255, alpha: 1).cgColor

for (index, diameter) in [620.0, 460.0, 300.0].enumerated() {
    let rect = CGRect(x: (1024 - diameter) / 2, y: (1024 - diameter) / 2 + 26, width: diameter, height: diameter)
    context.setStrokeColor(index == 1 ? mist : coral)
    context.setAlpha(index == 0 ? 0.48 : 0.78)
    context.setLineWidth(index == 2 ? 28 : 18)
    context.strokeEllipse(in: rect)
}

context.setAlpha(1)
context.setStrokeColor(mist)
context.setLineWidth(24)
context.move(to: CGPoint(x: 188, y: 330))
context.addCurve(to: CGPoint(x: 836, y: 330), control1: CGPoint(x: 382, y: 404), control2: CGPoint(x: 642, y: 256))
context.strokePath()

context.setFillColor(coral)
context.fillEllipse(in: CGRect(x: 459, y: 459, width: 106, height: 106))
image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Unable to encode icon PNG")
}
try png.write(to: URL(fileURLWithPath: destination), options: .atomic)
