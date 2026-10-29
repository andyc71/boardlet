import SwiftUI
import XCTest
@testable import BoardScanner

@MainActor
final class ArtworkImageTests: XCTestCase {
    func testOriginalWhiteArtworkKeepsTransparencyWithoutBacking() throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = false
        let original = UIGraphicsImageRenderer(size: CGSize(width: 64, height: 64), format: format).image { context in
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(x: 16, y: 16, width: 32, height: 32))
        }
        let renderer = ImageRenderer(content: ArtworkImage(image: original).frame(width: 64, height: 64))
        renderer.scale = 1
        let rendered = try XCTUnwrap(renderer.cgImage)
        let context = try XCTUnwrap(CGContext(data: nil, width: 64, height: 64,
            bitsPerComponent: 8, bytesPerRow: 256, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue))
        context.draw(rendered, in: CGRect(x: 0, y: 0, width: 64, height: 64))
        let pixels = try XCTUnwrap(context.data?.assumingMemoryBound(to: UInt8.self))
        XCTAssertEqual(pixels[(8 * 64 + 8) * 4 + 3], 0, "No black plate in transparent area")
        XCTAssertEqual(pixels[(32 * 64 + 32) * 4], 255, "White symbol is preserved")
        XCTAssertEqual(pixels[(32 * 64 + 32) * 4 + 3], 255)
    }
}
