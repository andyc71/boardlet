import CoreGraphics
import ImageIO
import XCTest
@testable import BoardScanner

final class MetafileRendererTests: XCTestCase {
    func testWMFColorBoundsAndTransparency() throws {
        let pixels = try raster(MetafileFixture.redRectangle)
        XCTAssertEqual(pixels(50, 50), [255, 0, 0, 255])
        XCTAssertEqual(pixels(5, 50), [0, 0, 0, 0])
        XCTAssertEqual(pixels(50, 5), [0, 0, 0, 0])
    }

    func testWMFSignedOriginReversedAxisAndRestoreState() throws {
        let f = MetafileFixture.self
        let data = f.wmf([f.redBrush, f.wmRecord(0x12d, [0]), f.noPen, f.wmRecord(0x12d, [1]),
                          f.wmRecord(0x20b, [-50, -100]), f.wmRecord(0x20c, [100, 100]),
                          f.wmRecord(0x1e), f.wmRecord(0x20c, [-100, 100]),
                          f.wmRecord(0x127, [-1]), f.wmRecord(0x41b, [0, -50, -40, -90])])
        let pixels = try raster(data)
        XCTAssertEqual(pixels(30, 30), [255, 0, 0, 255])
        XCTAssertEqual(pixels(70, 70), [0, 0, 0, 0])
        let reversed = f.wmf([f.redBrush, f.wmRecord(0x12d, [0]), f.noPen, f.wmRecord(0x12d, [1]),
                              f.wmRecord(0x20b, [100, 0]), f.wmRecord(0x20c, [-100, 100]),
                              f.wmRecord(0x41b, [30, 40, 10, 10])])
        let flip = try raster(reversed)
        XCTAssertEqual(flip(20, 80), [255, 0, 0, 255])
        XCTAssertEqual(flip(20, 20), [0, 0, 0, 0])
    }

    func testWMFEvenOddHolesAndClipRestoration() throws {
        let f = MetafileFixture.self
        let rings = [2, 4, 4, 10, 10, 90, 10, 90, 90, 10, 90, 30, 30, 70, 30, 70, 70, 30, 70]
        let data = f.wmf([f.redBrush, f.wmRecord(0x12d, [0]), f.noPen, f.wmRecord(0x12d, [1]),
                          f.wmRecord(0x106, [1]), f.wmRecord(0x538, rings)])
        let pixels = try raster(data)
        XCTAssertEqual(pixels(20, 50), [255, 0, 0, 255])
        XCTAssertEqual(pixels(50, 50), [0, 0, 0, 0])
        let clipped = f.wmf([f.redBrush, f.wmRecord(0x12d, [0]), f.noPen, f.wmRecord(0x12d, [1]),
                             f.wmRecord(0x416, [100, 50, 0, 0]), f.rectangle])
        let c = try raster(clipped)
        XCTAssertEqual(c(30, 50), [255, 0, 0, 255])
        XCTAssertEqual(c(70, 50), [0, 0, 0, 0])
    }

    func testEMFBezierPathAndWorldTransform() throws {
        let curve = try raster(MetafileFixture.bezier)
        XCTAssertEqual(curve(50, 60), [255, 0, 0, 255])
        XCTAssertEqual(curve(50, 10), [0, 0, 0, 0])
        let f = MetafileFixture.self
        let floats: [Float] = [1, 0, 0, 1, 40, 30]
        let transform = f.longs(floats.map { Int($0.bitPattern) })
        let shifted = f.emf(f.emfRedBrush + [f.emRecord(35, transform), f.emRecord(43, f.longs([0, 0, 20, 20]))])
        let p = try raster(shifted)
        XCTAssertEqual(p(50, 40), [255, 0, 0, 255])
        XCTAssertEqual(p(10, 10), [0, 0, 0, 0])
    }

    func testDIBRowsColorsPaddingAndSourceCopy() throws {
        let f = MetafileFixture.self
        // Bottom-up 2x2 BGR rows padded to DWORD boundaries: blue/white then red/green.
        let bitmap = f.longs([40, 2, 2]) + f.words([1, 24]) + f.longs([0, 16, 0, 0, 0, 0])
            + Data([255, 0, 0, 255, 255, 255, 0, 0, 0, 0, 255, 0, 255, 0, 0, 0])
        let payload = f.longs([0x00cc0020]) + f.words([0, 2, 2, 0, 0, 100, 100, 0, 0]) + bitmap
        let record = f.longs([(6 + payload.count) / 2]) + f.words([0xf43]) + payload
        let p = try raster(f.wmf([record]))
        XCTAssertEqual(p(10, 10), [255, 0, 0, 255])
        XCTAssertEqual(p(90, 10), [0, 255, 0, 255])
        XCTAssertEqual(p(10, 90), [0, 0, 255, 255])
        XCTAssertEqual(p(90, 90), [255, 255, 255, 255])
    }

    func testEMFObjectReusePenCapsAndSavedClip() throws {
        let f = MetafileFixture.self
        let pen = f.emRecord(95, f.longs([2, 0, 0, 0, 0, 0x12200, 10, 0, 0, 0, 0]))
        let line = f.emRecord(90, f.longs([0, 0, 100, 100, 1, 2, 2]) + f.words([20, 50, 80, 50]))
        let p = try raster(f.emf([pen, f.emRecord(37, f.longs([2])), f.emRecord(58, f.longs([4])), line]))
        XCTAssertEqual(p(50, 50), [0, 0, 0, 255])
        XCTAssertEqual(p(17, 50), [0, 0, 0, 0]) // flat cap, not a rounded extension
        let records = f.emfRedBrush + [f.emRecord(33), f.emRecord(30, f.longs([0, 0, 40, 100])),
                                       f.emRecord(43, f.longs([10, 10, 90, 40])),
                                       f.emRecord(34, f.longs([-1])), f.emRecord(40, f.longs([1])),
                                       f.emRecord(39, f.longs([1, 0, 0xff00, 0])), f.emRecord(37, f.longs([1])),
                                       f.emRecord(43, f.longs([60, 60, 90, 90]))]
        let c = try raster(f.emf(records))
        XCTAssertEqual(c(20, 20), [255, 0, 0, 255])
        XCTAssertEqual(c(70, 20), [0, 0, 0, 0])
        XCTAssertEqual(c(70, 70), [0, 255, 0, 255])
    }

    func testMalformedCountsHandlesChecksumsAndWorkLimits() throws {
        let f = MetafileFixture.self
        // Valid outer lengths cannot hide a truncated fixed-size object payload.
        XCTAssertThrowsError(try MetafileRenderer.png(f.wmf([f.wmRecord(0x2fc, [0, 255, 0]) ])))
        XCTAssertThrowsError(try MetafileRenderer.png(f.emf([f.emRecord(39, f.longs([1, 0, 255]))])))
        var checksum = f.redRectangle; checksum[20] ^= 1
        XCTAssertThrowsError(try MetafileRenderer.png(checksum))
        XCTAssertThrowsError(try MetafileRenderer.png(f.wmf([f.wmRecord(0x538, [2, 65535, 65535])])))
        XCTAssertThrowsError(try MetafileRenderer.png(f.emf([f.emRecord(88, f.longs([0, 0, 100, 100, 0x7fffffff]))])))
        XCTAssertThrowsError(try MetafileRenderer.png(f.emf([f.emRecord(39, f.longs([0x7fffffff, 0, 0, 0]))])))
        XCTAssertThrowsError(try MetafileRenderer.png(f.wmf(Array(repeating: f.wmRecord(0x1e), count: 65))))
        var recordSize = f.redRectangle
        recordSize.replaceSubrange(40..<44, with: f.longs([0x7fffffff]))
        XCTAssertThrowsError(try MetafileRenderer.png(recordSize))
        let nan: Float = .nan
        XCTAssertThrowsError(try MetafileRenderer.png(f.emf([f.emRecord(35, f.longs([Int(nan.bitPattern), 0, 0, 0, 0, 0]))])))
    }

    func testCurrentPositionRemainsLogicalWhenMappingChanges() throws {
        let f = MetafileFixture.self
        let shifted = f.emf([f.emRecord(38, f.longs([1, 0, 8, 0, 0])), f.emRecord(37, f.longs([1])),
                             f.emRecord(27, f.longs([10, 10])),
                             f.emRecord(12, f.longs([40, 30])), f.emRecord(54, f.longs([20, 10]))])
        let pixels = try raster(shifted)
        XCTAssertEqual(pixels(55, 40), [0, 0, 0, 255])
        XCTAssertEqual(pixels(20, 16), [0, 0, 0, 0])
    }

    func testMalformedTruncatedUnknownAndUnpaintedAreRejected() throws {
        for data in [MetafileFixture.redRectangle, MetafileFixture.bezier] {
            for end in 0..<data.count {
                XCTAssertThrowsError(try MetafileRenderer.png(data.prefix(end)), "Truncation at \(end)")
            }
        }
        let f = MetafileFixture.self
        XCTAssertThrowsError(try MetafileRenderer.png(f.wmf([f.wmRecord(0x12d, [99])])))
        XCTAssertThrowsError(try MetafileRenderer.png(f.wmf([f.wmRecord(0x127, [-1])])))
        XCTAssertThrowsError(try MetafileRenderer.png(f.wmf([f.wmRecord(0x20c, [0, 100])])))
        XCTAssertThrowsError(try MetafileRenderer.png(f.wmf([f.redBrush, f.wmRecord(0x12d, [0]), f.rectangle, f.wmRecord(0x626, [0, 0])])))
        XCTAssertThrowsError(try MetafileRenderer.png(f.emf([f.emRecord(84, Data(repeating: 0, count: 80))])))
        XCTAssertThrowsError(try MetafileRenderer.png(f.emf([f.emRecord(59)])))
        XCTAssertThrowsError(try MetafileRenderer.png(f.wmf([])))
        XCTAssertThrowsError(try MetafileRenderer.png(f.bezier, maximumDimension: 100_000))
    }

    func testCancellationAndOldArchivePreviewRegeneration() async throws {
        let task = Task {
            while !Task.isCancelled { await Task.yield() }
            return try MetafileRenderer.png(MetafileFixture.bezier)
        }
        task.cancel()
        do { _ = try await task.value; XCTFail("Expected cancellation") } catch is CancellationError { }
        let url = try SnapTestFixture.make()
        defer { try? FileManager.default.removeItem(at: url) }
        var set = try await TDSnapImporter.load(url)
        set.assets["1"] = SnapAsset(data: MetafileFixture.redRectangle, previewPNG: nil)
        let saved = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".boardscan")
        defer { try? FileManager.default.removeItem(at: saved) }
        try JSONEncoder().encode(ScannerArchive(pageSet: set)).write(to: saved)
        let document = try await BoardStorage.openDocument(saved)
        let decoded = try XCTUnwrap(document.pageSet)
        XCTAssertNotNil(decoded.assets["1"]?.previewPNG)
        XCTAssertEqual(decoded.assets["1"]?.data, MetafileFixture.redRectangle)
    }

    private func raster(_ data: Data) throws -> (Int, Int) -> [UInt8] {
        let png = try MetafileRenderer.png(data, maximumDimension: 100)
        let source = try XCTUnwrap(CGImageSourceCreateWithData(png as CFData, nil))
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let context = try XCTUnwrap(CGContext(data: nil, width: 100, height: 100, bitsPerComponent: 8,
                                            bytesPerRow: 400, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: 100, height: 100))
        let bytes = Array(UnsafeBufferPointer(start: context.data!.assumingMemoryBound(to: UInt8.self), count: 40000))
        return { x, y in Array(bytes[(y * 100 + x) * 4..<(y * 100 + x) * 4 + 4]) }
    }
}
