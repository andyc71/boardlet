import SystemPhotoPicker
import Combine
import UniformTypeIdentifiers
import XCTest
@testable import PhotoPickerHarness

@MainActor
final class PhotoImportTests: XCTestCase {
    private func png(_ color: UIColor, width: Int = 10) -> Data {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: width, height: 10), format: format).pngData { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: width, height: 10))
        }
    }

    private func source(_ data: Data) -> ImageImportSource {
        ImageImportSource { completion in
            completion(.success(data))
            return Progress(totalUnitCount: 1)
        }
    }

    private func finish(_ model: PhotoImportModel) async {
        let finished = expectation(description: "Import leaves loading state")
        let subscription = model.$state.sink { state in
            if case .loading = state { return }
            finished.fulfill()
        }
        await fulfillment(of: [finished], timeout: 5)
        subscription.cancel()
    }

    func testConcurrentImportPreservesOrderAndCommitsOnlyWhenComplete() async {
        let model = PhotoImportModel(maximumConcurrentLoads: 2)
        var firstCompletion: ImageImportSource.Completion?
        var secondCompletion: ImageImportSource.Completion?
        var thirdCompletion: ImageImportSource.Completion?
        let firstStarted = expectation(description: "First provider starts")
        let secondStarted = expectation(description: "Second provider starts")
        let thirdStarted = expectation(description: "Third provider starts after a slot is available")
        let first = ImageImportSource { completion in
            firstCompletion = completion
            firstStarted.fulfill()
            return Progress(totalUnitCount: 1)
        }
        let second = ImageImportSource { completion in
            secondCompletion = completion
            secondStarted.fulfill()
            return Progress(totalUnitCount: 1)
        }
        let third = ImageImportSource { completion in
            thirdCompletion = completion
            thirdStarted.fulfill()
            return Progress(totalUnitCount: 1)
        }
        model.importPhotos(from: [first, second, third])
        XCTAssertEqual(model.state, .loading(completed: 0, total: 3))
        await fulfillment(of: [firstStarted, secondStarted], timeout: 5)
        XCTAssertNil(thirdCompletion, "The concurrency limit should leave the third provider queued")

        secondCompletion?(.success(png(.blue, width: 24)))
        await fulfillment(of: [thirdStarted], timeout: 5)
        XCTAssertEqual(model.state, .loading(completed: 1, total: 3))
        XCTAssertTrue(model.photos.isEmpty, "Do not publish a partial batch")

        thirdCompletion?(.success(png(.green, width: 36)))
        firstCompletion?(.success(png(.red, width: 12)))
        await finish(model)
        XCTAssertEqual(model.photos.map { Int($0.image.size.width) }, [12, 24, 36])
    }

    func testProviderErrorAndCorruptDataKeepPreviousImagesAndAllowRetry() async {
        let model = PhotoImportModel()
        model.importPhotos(from: [source(png(.red))])
        await finish(model)
        let originalID = model.photos.first?.id
        let failure = ImageImportSource { completion in
            completion(.failure(NSError(domain: "ProviderTest", code: 42,
                                        userInfo: [NSLocalizedDescriptionKey: "Download unavailable"])))
            return Progress(totalUnitCount: 1)
        }
        for badSource in [failure, source(Data([0, 1, 2]))] {
            model.importPhotos(from: [source(png(.blue)), badSource])
            await finish(model)
            guard case let .failed(message) = model.state else { return XCTFail("Expected a visible failure") }
            XCTAssertTrue(message.hasPrefix("Photo 2 of 2:"))
            XCTAssertEqual(model.photos.map(\.id), [originalID].compactMap { $0 })
        }
        model.importPhotos(from: [source(png(.green, width: 20))])
        await finish(model)
        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.photos.first?.image.size.width, 20)
    }

    func testCancelAndLateCallbackCannotOverwriteNewImport() async {
        let model = PhotoImportModel()
        model.importPhotos(from: [source(png(.red))])
        await finish(model)
        let originalID = model.photos.first?.id
        let progress = Progress(totalUnitCount: 1)
        var lateCompletion: ImageImportSource.Completion?
        let delayed = ImageImportSource { completion in
            lateCompletion = completion
            return progress
        }
        model.importPhotos(from: [delayed])
        model.cancel()
        XCTAssertTrue(progress.isCancelled)
        XCTAssertEqual(model.state, .cancelled)
        XCTAssertEqual(model.photos.first?.id, originalID)
        model.importPhotos(from: [source(png(.green, width: 20))])
        // Deliver stale data before the newer batch finishes.
        lateCompletion?(.success(png(.blue, width: 30)))
        await finish(model)
        XCTAssertEqual(model.photos.map { Int($0.image.size.width) }, [20])
    }

    func testNewImportInvalidatesAnInFlightBatch() async {
        let model = PhotoImportModel()
        let progress = Progress(totalUnitCount: 1)
        var oldCompletion: ImageImportSource.Completion?
        model.importPhotos(from: [ImageImportSource { completion in
            oldCompletion = completion
            return progress
        }])
        model.importPhotos(from: [source(png(.red, width: 40))])
        oldCompletion?(.failure(ImageImportError.empty))
        await finish(model)
        XCTAssertTrue(progress.isCancelled)
        XCTAssertEqual(model.state, .loaded)
        XCTAssertEqual(model.photos.first?.image.size.width, 40)
    }

    func testEmptySelectionKeepsExistingImages() async {
        let model = PhotoImportModel()
        model.importPhotos(from: [source(png(.red))])
        await finish(model)
        let originalID = model.photos.first?.id
        model.importPhotos(from: [ImageImportSource]())
        XCTAssertEqual(model.state, .cancelled)
        XCTAssertEqual(model.photos.first?.id, originalID)
    }

    func testRealItemProviderWithoutAssetAccessAndUnsupportedProvider() async {
        let model = PhotoImportModel()
        let data = png(.red, width: 32)
        let provider = NSItemProvider()
        provider.registerDataRepresentation(forTypeIdentifier: UTType.png.identifier, visibility: .all) { completion in
            completion(data, nil)
            return nil
        }
        model.importPhotos(from: [provider])
        await finish(model)
        XCTAssertEqual(model.photos.first?.image.size.width, 32)

        let oversizedData = png(.blue, width: ImageImportSource.maximumPixelDimension + 500)
        let oversizedProvider = NSItemProvider()
        oversizedProvider.registerDataRepresentation(
            forTypeIdentifier: UTType.png.identifier,
            visibility: .all
        ) { completion in
            completion(oversizedData, nil)
            return nil
        }
        model.importPhotos(from: [oversizedProvider])
        await finish(model)
        XCTAssertEqual(
            Int(model.photos.first?.image.size.width ?? 0),
            ImageImportSource.maximumPixelDimension
        )

        model.importPhotos(from: [NSItemProvider(object: "Text is not an image" as NSString)])
        await finish(model)
        guard case .failed = model.state else { return XCTFail("Expected unsupported provider error") }
        XCTAssertEqual(
            Int(model.photos.first?.image.size.width ?? 0),
            ImageImportSource.maximumPixelDimension
        )
    }
}
