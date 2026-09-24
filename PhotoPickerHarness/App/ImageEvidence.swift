import UIKit

/// Evidence derived from decoded pixels, never from a provider name or selection flag.
/// The tiny solid-color seed files make this stable across image re-encoding.
enum ImageEvidence {
    static func describe(_ image: UIImage) -> String {
        guard let cgImage = image.cgImage else { return "No decoded pixels" }
        var pixel = [UInt8](repeating: 0, count: 4)
        let rendered = pixel.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: 1, height: 1,
                                          bitsPerComponent: 8, bytesPerRow: 4,
                                          space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
            return true
        }
        guard rendered else { return "Pixel inspection failed" }
        let color: String
        switch (pixel[0], pixel[1], pixel[2]) {
        case (230...255, 0...64, 0...64): color = "red"
        case (0...64, 230...255, 0...64): color = "green"
        case (0...64, 0...64, 230...255): color = "blue"
        default: color = "RGB \(pixel[0]),\(pixel[1]),\(pixel[2])"
        }
        return "\(cgImage.width)×\(cgImage.height) • \(color)"
    }
}
