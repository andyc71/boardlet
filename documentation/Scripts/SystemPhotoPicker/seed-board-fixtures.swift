import Foundation
import ImageIO
import UniformTypeIdentifiers

let source = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
let files = try FileManager.default.contentsOfDirectory(at: source, includingPropertiesForKeys: nil)
    .filter { $0.pathExtension == "png" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
for (index, file) in files.enumerated() {
    let input = CGImageSourceCreateWithURL(file as CFURL, nil)!
    let image = CGImageSourceCreateImageAtIndex(input, 0, nil)!
    let target = output.appendingPathComponent(file.deletingPathExtension().lastPathComponent + ".jpg")
    let destination = CGImageDestinationCreateWithURL(target as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    let date = String(format: "2020:02:%02d 12:00:00", index + 1)
    CGImageDestinationAddImage(destination, image, [
        kCGImageDestinationLossyCompressionQuality: 1.0,
        kCGImagePropertyExifDictionary: [kCGImagePropertyExifDateTimeOriginal: date,
                                        kCGImagePropertyExifDateTimeDigitized: date],
        kCGImagePropertyTIFFDictionary: [kCGImagePropertyTIFFDateTime: date]
    ] as CFDictionary)
    precondition(CGImageDestinationFinalize(destination))
}
