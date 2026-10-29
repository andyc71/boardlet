import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct RasterImage {
    let image: CGImage

    init(data: Data, maximumDimension: Int = 2560) throws {
        guard data.count <= 80_000_000 else { throw ScanError.oversizedFile }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maximumDimension,
                kCGImageSourceShouldCacheImmediately: true
              ] as CFDictionary), image.width >= 2, image.height >= 2 else {
            throw ScanError.invalidImage
        }
        self.image = image
    }

    func png(crop: CGRect? = nil) throws -> Data {
        let output: CGImage
        if let crop {
            let pixels = CGRect(x: crop.minX * Double(image.width), y: crop.minY * Double(image.height),
                                width: crop.width * Double(image.width), height: crop.height * Double(image.height))
                .integral.intersection(CGRect(x: 0, y: 0, width: image.width, height: image.height))
            guard pixels.width >= 2, pixels.height >= 2, let cropped = image.cropping(to: pixels) else {
                throw ScanError.invalidImage
            }
            output = cropped
        } else { output = image }
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil) else {
            throw ScanError.invalidImage
        }
        CGImageDestinationAddImage(destination, output, nil)
        guard CGImageDestinationFinalize(destination) else { throw ScanError.invalidImage }
        return data as Data
    }

    /// A small luminance buffer for line projections. Rows start at the image's top edge.
    func grayscale(maximumDimension: Int = 900) throws -> (pixels: [UInt8], width: Int, height: Int) {
        let scale = min(1, Double(maximumDimension) / Double(max(image.width, image.height)))
        let width = max(1, Int(Double(image.width) * scale))
        let height = max(1, Int(Double(image.height) * scale))
        var pixels = [UInt8](repeating: 255, count: width * height)
        let rendered = pixels.withUnsafeMutableBytes { bytes -> Bool in
            guard let context = CGContext(data: bytes.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: width,
                                          space: CGColorSpaceCreateDeviceGray(), bitmapInfo: 0) else { return false }
            context.setFillColor(gray: 1, alpha: 1)
            context.fill(CGRect(x: 0, y: 0, width: width, height: height))
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard rendered else { throw ScanError.invalidImage }
        return (pixels, width, height)
    }
}
