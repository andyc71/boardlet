import AppKit
import Foundation

/// A contact sheet of the actual extracted PNGs and strings; not an app screenshot.
@main
struct RenderValidation {
    @MainActor static func main() throws {
        let input = URL(fileURLWithPath: CommandLine.arguments[1])
        let output = URL(fileURLWithPath: CommandLine.arguments[2])
        let board = try JSONDecoder().decode(ScannedBoard.self, from: Data(contentsOf: input))
        let width = board.columns * 110, height = board.rows * 135 + 40
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height,
                                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                             isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0),
              let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        NSColor(calibratedWhite: 0.15, alpha: 1).setFill()
        NSBezierPath(rect: NSRect(x: 0, y: 0, width: width, height: height)).fill()
        ("Extracted crops · \(board.cards.filter(\.included).count) cards · \(board.method)" as NSString)
            .draw(at: NSPoint(x: 10, y: height - 30), withAttributes: [.font: NSFont.systemFont(ofSize: 16), .foregroundColor: NSColor.white])
        for card in board.cards where card.included {
            let x = CGFloat(card.column * 110 + 4), y = CGFloat(height - 40 - (card.row + 1) * 135)
            let tile = NSRect(x: x, y: y, width: 102, height: 129)
            NSColor.white.setFill()
            NSBezierPath(roundedRect: tile, xRadius: 6, yRadius: 6).fill()
            if let image = NSImage(data: card.imagePNG) {
                let factor = min(94 / image.size.width, 84 / image.size.height)
                let size = NSSize(width: image.size.width * factor, height: image.size.height * factor)
                image.draw(in: NSRect(x: x + (102 - size.width) / 2, y: y + 42 + (84 - size.height) / 2,
                                     width: size.width, height: size.height))
            }
            let style = NSMutableParagraphStyle()
            style.alignment = .center
            (card.label as NSString).draw(in: NSRect(x: x + 3, y: y + 3, width: 96, height: 38), withAttributes: [
                .font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.black, .paragraphStyle: style
            ])
        }
        NSGraphicsContext.restoreGraphicsState()
        try bitmap.representation(using: .png, properties: [:])?.write(to: output)
    }
}
