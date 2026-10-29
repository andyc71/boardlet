import XCTest
import Vision
import UIKit
import ImageIO
import UniformTypeIdentifiers
@testable import BoardScanner

final class BoardAnalyzerTests: XCTestCase {
    @MainActor
    func testScreenshotToBoardSeparatesLabelsFromPictures() async throws {
        let data = try XCTUnwrap(SampleBoard.image().pngData())
        let board = try await BoardAnalyzer.analyze(data: data)
        XCTAssertEqual(board.rows, 2)
        XCTAssertEqual(board.columns, 3)
        XCTAssertEqual(board.method, "Repeated edges")
        XCTAssertEqual(board.cards.map(\.label), SampleBoard.labels)
        for card in board.cards {
            XCTAssertFalse(card.needsReview, card.label)
            XCTAssertLessThan(card.pictureBounds.maxY, card.bounds.maxY - card.bounds.height * 0.14)
            let raster = try RasterImage(data: card.imagePNG)
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            try VNImageRequestHandler(cgImage: raster.image).perform([request])
            XCTAssertFalse((request.results ?? []).contains { $0.topCandidates(1).first?.string == card.label },
                           "The source label must not remain baked into the picture")
        }
        // Asymmetric colors verify that top-left crop coordinates are not vertically flipped.
        let water = try RasterImage(data: board.cards[0].imagePNG).image
        let help = try RasterImage(data: board.cards[5].imagePNG).image
        XCTAssertNotEqual(try RasterImage(data: board.cards[0].imagePNG).png(),
                          try RasterImage(data: board.cards[5].imagePNG).png())
        XCTAssertGreaterThan(water.width, 100)
        XCTAssertGreaterThan(help.height, 100)
    }

    @MainActor
    func testTopLabelsAndGutters() async throws {
        let board = try await BoardAnalyzer.analyze(data: XCTUnwrap(SampleBoard.image(topLabels: true, gaps: true).pngData()))
        XCTAssertEqual(board.rows, 2)
        XCTAssertEqual(board.columns, 3)
        XCTAssertEqual(board.cards.map(\.label), SampleBoard.labels)
        for card in board.cards {
            XCTAssertGreaterThan(card.pictureBounds.minY, card.bounds.minY + card.bounds.height * 0.13)
            XCTAssertLessThan(card.pictureBounds.maxY, card.bounds.maxY)
        }
    }

    @MainActor
    func testManualGridUsesSpecifiedArea() async throws {
        let data = try XCTUnwrap(SampleBoard.image().pngData())
        let grid = GridOverride(rows: 2, columns: 3, left: 45.0 / 900, top: 100.0 / 760,
                                right: 45.0 / 900, bottom: 60.0 / 760, inset: 0.01)
        let board = try await BoardAnalyzer.analyze(data: data, grid: grid)
        XCTAssertEqual(board.method, "Manual grid")
        XCTAssertEqual(board.cards.map(\.label), SampleBoard.labels)
        XCTAssertEqual(board.cards.map(\.bounds), grid.cells)
    }

    func testMultilineLabelsAndUncertainCenterText() {
        let cell = CGRect(x: 0, y: 0, width: 0.5, height: 0.5)
        let text = [TextRegion(text: "More", confidence: 0.99, bounds: CGRect(x: 0.1, y: 0.34, width: 0.2, height: 0.04)),
                    TextRegion(text: "water", confidence: 0.95, bounds: CGRect(x: 0.1, y: 0.40, width: 0.2, height: 0.04)),
                    TextRegion(text: "Other card", confidence: 1, bounds: CGRect(x: 0.6, y: 0.4, width: 0.2, height: 0.04))]
        let result = LabelExtractor.extract(in: cell, text: text)
        XCTAssertEqual(result.label, "More water")
        XCTAssertLessThan(result.picture.maxY, 0.34)
        XCTAssertFalse(result.needsReview)
        let center = LabelExtractor.extract(in: cell, text: [
            TextRegion(text: "Uncertain", confidence: 0.5, bounds: CGRect(x: 0.1, y: 0.22, width: 0.2, height: 0.04))
        ])
        XCTAssertTrue(center.needsReview)
        XCTAssertTrue(LabelExtractor.extract(in: cell, text: []).needsReview)
    }

    func testGridPreservesMissingCellAndIgnoresNestedArtwork() throws {
        let cells = (0..<6).map { index in
            CGRect(x: 0.05 + Double(index % 3) * 0.3, y: 0.1 + Double(index / 3) * 0.4, width: 0.27, height: 0.36)
        }
        let nested = cells.map { $0.insetBy(dx: 0.09, dy: 0.12) }
        let grid = try XCTUnwrap(GridDetector.infer(Array(cells.dropLast()) + nested, method: "test"))
        XCTAssertEqual(grid.columns, 3)
        XCTAssertEqual(grid.rows, 2)
        XCTAssertEqual(grid.cells.count, 6)
        XCTAssertEqual(grid.cells[5].midX, cells[5].midX, accuracy: 0.001)
        XCTAssertEqual(grid.cells[5].midY, cells[5].midY, accuracy: 0.001)
    }

    @MainActor
    func testSparseColoredGridExcludesToolbarAndPreservesEmptySlots() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 800, height: 700), format: format).image { renderer in
            UIColor(white: 0.15, alpha: 1).setFill()
            renderer.fill(CGRect(x: 0, y: 0, width: 800, height: 700))
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(x: 20, y: 20, width: 580, height: 85), cornerRadius: 12).fill()
            ("Speak Clear" as NSString).draw(at: CGPoint(x: 40, y: 45), withAttributes: [
                .font: UIFont.systemFont(ofSize: 28), .foregroundColor: UIColor.black
            ])
            for row in 0..<4 {
                for column in 0..<5 where row == 1 || column == 4 || (row == 0 && column == 0) {
                    let rect = CGRect(x: 20 + column * 155, y: 140 + row * 135, width: 140, height: 120)
                    UIColor(red: 0.7, green: 0.8, blue: 1, alpha: 1).setFill()
                    UIBezierPath(roundedRect: rect, cornerRadius: 10).fill()
                    UIColor.systemBlue.setFill()
                    UIBezierPath(ovalIn: CGRect(x: rect.midX - 22, y: rect.minY + 10, width: 44, height: 44)).fill()
                    ("Water" as NSString).draw(at: CGPoint(x: rect.minX + 30, y: rect.maxY - 37), withAttributes: [
                        .font: UIFont.systemFont(ofSize: 24), .foregroundColor: UIColor.black
                    ])
                }
            }
        }
        let board = try await BoardAnalyzer.analyze(data: XCTUnwrap(image.pngData()))
        XCTAssertEqual(board.method, "Card surfaces")
        XCTAssertEqual(board.rows, 4)
        XCTAssertEqual(board.columns, 5)
        XCTAssertEqual(board.cards.filter(\.included).count, 9)
        XCTAssertEqual(board.cards.filter { $0.isEmpty == true }.count, 11)
        XCTAssertTrue(board.cards.filter(\.included).allSatisfy { $0.label == "Water" })
        XCTAssertTrue(board.cards.filter { $0.isEmpty == true }.allSatisfy { !$0.needsReview && $0.label.isEmpty })
        XCTAssertTrue(board.cards.allSatisfy { $0.bounds.minY > 0.19 })
        let restored = try BoardStorage.decode(JSONEncoder().encode(board))
        XCTAssertEqual(restored.cards.map(\.isEmpty), board.cards.map(\.isEmpty))
    }

    @MainActor
    func testSmallBoardUsesVisionFallback() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let sample = SampleBoard.image()
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2400, height: 2400), format: format).image { renderer in
            UIColor.white.setFill()
            renderer.fill(CGRect(x: 0, y: 0, width: 2400, height: 2400))
            sample.draw(in: CGRect(x: 750, y: 800, width: 540, height: 456))
        }
        let board = try await BoardAnalyzer.analyze(data: XCTUnwrap(image.pngData()))
        XCTAssertTrue(board.method.hasPrefix("Vision"), board.method)
        XCTAssertEqual(board.rows, 2)
        XCTAssertEqual(board.columns, 3)
        XCTAssertEqual(board.cards.map(\.label), SampleBoard.labels)
    }

    @MainActor
    func testImageOrientationIsNormalizedBeforeDetection() async throws {
        let cgImage = try XCTUnwrap(SampleBoard.image().cgImage)
        let jpeg = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(jpeg, UTType.jpeg.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, cgImage, [kCGImagePropertyOrientation: 6] as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        let raster = try RasterImage(data: jpeg as Data)
        XCTAssertEqual(raster.image.width, cgImage.height)
        XCTAssertEqual(raster.image.height, cgImage.width)
        // A round trip has upright pixels with no additional EXIF rotation to apply.
        let roundTrip = try RasterImage(data: raster.png())
        XCTAssertEqual(roundTrip.image.width, raster.image.width)
        XCTAssertEqual(roundTrip.image.height, raster.image.height)
    }

    @MainActor
    func testNoGridIsReportedForBlankImage() async throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 600, height: 600)).image { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 600, height: 600))
        }
        do {
            _ = try await BoardAnalyzer.analyze(data: XCTUnwrap(image.pngData()))
            XCTFail("A blank screenshot is not a grid")
        } catch ScanError.noGrid { }
    }

    func testArtworkTextIsRetainedWhenThereIsABottomCaption() {
        let cell = CGRect(x: 0, y: 0, width: 1, height: 1)
        let result = LabelExtractor.extract(in: cell, text: [
            TextRegion(text: "Drink", confidence: 1, bounds: CGRect(x: 0.2, y: 0.05, width: 0.3, height: 0.1)),
            TextRegion(text: "Water", confidence: 1, bounds: CGRect(x: 0.2, y: 0.8, width: 0.3, height: 0.1))
        ])
        XCTAssertEqual(result.label, "Water")
        XCTAssertTrue(result.needsReview)
        XCTAssertLessThan(result.picture.minY, 0.05)
        XCTAssertLessThan(result.picture.maxY, 0.8)
    }

    func testStrayPictogramStrokeDoesNotBecomeCaptionText() {
        let cell = CGRect(x: 0, y: 0, width: 1, height: 1)
        let slash = TextRegion(text: "/", confidence: 1, bounds: CGRect(x: 0.4, y: 0.66, width: 0.03, height: 0.04))
        let word = TextRegion(text: "Feelings", confidence: 1, bounds: CGRect(x: 0.2, y: 0.8, width: 0.6, height: 0.1))
        let caption = LabelExtractor.extract(in: cell, text: [slash, word])
        XCTAssertEqual(caption.label, "Feelings")
        XCTAssertTrue(caption.needsReview)
        XCTAssertEqual(LabelExtractor.extract(in: cell, text: [slash]).label, "/")
        let combined = LabelExtractor.extract(in: cell, text: [
            TextRegion(text: "/ Feelings", confidence: 1, bounds: CGRect(x: 0.2, y: 0.7, width: 0.6, height: 0.2))
        ])
        XCTAssertEqual(combined.label, "Feelings")
        XCTAssertTrue(combined.needsReview)
    }

    func testVisionCoordinatesFlipExactlyOnce() {
        let rect = CGRect.fromVision(CGRect(x: 0.1, y: 0.7, width: 0.2, height: 0.1))
        XCTAssertEqual(rect.minY, 0.2, accuracy: 0.00001)
        XCTAssertEqual(rect.minX, 0.1)
    }

    @MainActor
    func testSaveRoundTripAndInvalidArchiveRejection() async throws {
        var board = try await BoardAnalyzer.analyze(data: XCTUnwrap(SampleBoard.image().pngData()))
        board.cards[0].label = "A drink, please"
        let data = try JSONEncoder().encode(board)
        let restored = try BoardStorage.decode(data)
        XCTAssertEqual(restored.cards[0].label, "A drink, please")
        XCTAssertEqual(restored.cards[0].imagePNG, board.cards[0].imagePNG)
        XCTAssertEqual(restored.sourcePNG, board.sourcePNG)
        board.cards[0].column = 99
        XCTAssertThrowsError(try BoardStorage.decode(JSONEncoder().encode(board)))
        board.cards[0].column = 0
        board.version = 999
        XCTAssertThrowsError(try BoardStorage.decode(JSONEncoder().encode(board)))
    }

    @MainActor
    func testInvalidImageAndCancellation() async throws {
        do {
            _ = try await BoardAnalyzer.analyze(data: Data("not an image".utf8))
            XCTFail("Expected an invalid image error")
        } catch ScanError.invalidImage { }
        let task = Task { try await BoardAnalyzer.analyze(data: Data()) }
        task.cancel()
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError { }
    }
}
