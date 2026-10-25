import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

let sourceDirectory = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let outputDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

for day in 1...8 {
    let prefix = String(format: "%03d-", day)
    let sourceURL = try FileManager.default.contentsOfDirectory(at: sourceDirectory,
                                                                includingPropertiesForKeys: nil)
        .first { $0.lastPathComponent.hasPrefix(prefix) }!
    let source = CGImageSourceCreateWithURL(sourceURL as CFURL, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    let context = CGContext(data: nil, width: image.width, height: image.height,
                            bitsPerComponent: 8, bytesPerRow: image.width * 4,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.setFillColor(CGColor.white)
    context.fill(CGRect(x: 0, y: 0, width: image.width, height: image.height))
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

    let outputURL = outputDirectory.appendingPathComponent(String(format: "%02d.jpg", day))
    let destination = CGImageDestinationCreateWithURL(outputURL as CFURL,
                                                      UTType.jpeg.identifier as CFString, 1, nil)!
    let date = String(format: "2020:02:%02d 12:00:00", day)
    let properties: [CFString: Any] = [
        kCGImageDestinationLossyCompressionQuality: 0.9,
        kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: date,
                                         kCGImagePropertyExifDateTimeDigitized: date],
        kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFDateTime: date]
    ]
    CGImageDestinationAddImage(destination, context.makeImage()!, properties as CFDictionary)
    precondition(CGImageDestinationFinalize(destination))
}
