// Regenerate the committed JPEGs with: swift Scripts/generate-fixtures.swift Fixtures
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
for (name, width, height, red, green, blue, day) in [
    ("01-red", 120, 80, 1.0, 0.0, 0.0, 1),
    ("02-green", 80, 120, 0.0, 1.0, 0.0, 2),
    ("03-blue", 96, 96, 0.0, 0.0, 1.0, 3)
] {
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                            bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    let destination = CGImageDestinationCreateWithURL(folder.appendingPathComponent("\(name).jpg") as CFURL,
                                                     UTType.jpeg.identifier as CFString, 1, nil)!
    let date = "2020:01:0\(day) 12:00:00"
    let properties: [CFString: Any] = [
        kCGImageDestinationLossyCompressionQuality: 1.0,
        kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: date,
                                       kCGImagePropertyExifDateTimeDigitized: date],
        kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFDateTime: date]
    ]
    CGImageDestinationAddImage(destination, context.makeImage()!, properties as CFDictionary)
    precondition(CGImageDestinationFinalize(destination))
}
