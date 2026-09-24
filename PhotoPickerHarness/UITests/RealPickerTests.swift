import XCTest
import UIKit

@MainActor
class RealPickerTests: XCTestCase {
    var orientation: UIDeviceOrientation { .portrait }

    private var app: XCUIApplication!
    private var picker: SystemPhotoPickerDriver { SystemPhotoPickerDriver(app: app) }

    override func setUp() async throws {
        try await super.setUp()
        await MainActor.run {
            continueAfterFailure = false
            app = XCUIApplication()
            app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
            XCUIDevice.shared.orientation = orientation
            app.launch()
            XCUIDevice.shared.orientation = orientation
            XCTAssertEqual(XCUIDevice.shared.orientation, orientation)
            if orientation.isLandscape {
                XCTAssertGreaterThan(app.frame.width, app.frame.height, "App must actually render in landscape")
            } else {
                XCTAssertGreaterThan(app.frame.height, app.frame.width, "App must actually render in portrait")
            }
        }
    }

    private func open() {
        app.buttons["choosePhotos"].tap()
        picker.assertOpen()
    }

    private func selectPhoto(day: Int) {
        picker.selectPhoto(matching: NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@",
                                                "January 0\(day), 2020", "January \(day), 2020"))
    }

    private func assertImported(_ content: [String], file: StaticString = #filePath, line: UInt = #line) {
        let status = app.staticTexts["importStatus"]
        let complete = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == 'Import complete'"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [complete], timeout: 20), .completed, app.debugDescription, file: file, line: line)
        picker.assertDismissed(file: file, line: line)
        assertContent(content, file: file, line: line)
        picker.captureEvidence(named: "Imported content")
    }

    private func assertContent(_ content: [String], file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(app.staticTexts["importedCount"].label, "Imported: \(content.count)", file: file, line: line)
        for (index, expected) in content.enumerated() {
            let thumbnail = app.images["thumbnail-\(index)"]
            let evidence = app.staticTexts["content-\(index)"]
            let scroll = app.scrollViews["importedPhotos"]
            for _ in 0..<12 where !evidence.isHittable {
                let above = evidence.exists && evidence.frame.midY < scroll.frame.midY
                let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: above ? 0.35 : 0.65))
                let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: above ? 0.65 : 0.35))
                // Pause before release so momentum cannot skip a short landscape viewport.
                start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.3)
            }
            XCTAssertTrue(thumbnail.exists, file: file, line: line)
            XCTAssertTrue(evidence.isHittable, "Imported content must be visible\n\(app.debugDescription)", file: file, line: line)
            XCTAssertEqual(app.staticTexts["content-\(index)"].label, expected, file: file, line: line)
        }
    }

    // Keep these first two tests as the viability gate for a newly installed runtime.
    func testOpenCancel() {
        open()
        picker.cancel()
        picker.assertDismissed()
        assertContent([])
        XCTAssertEqual(app.staticTexts["importStatus"].label, "Cancelled; imported photos unchanged")
    }

    func testSelectAndImport() {
        open()
        selectPhoto(day: 1)
        picker.confirm()
        assertImported(["120×80 • red"])
    }

    func testMultipleSelectionOrderCancelPreservesContentAndReopen() {
        open()
        // Assert tap order explicitly; chronological/grid order differs across runtimes.
        selectPhoto(day: 1)
        selectPhoto(day: 3)
        picker.confirm()
        let previous = ["120×80 • red", "96×96 • blue"]
        assertImported(previous)

        open()
        selectPhoto(day: 2)
        picker.cancel()
        picker.assertDismissed()
        assertContent(previous)
        XCTAssertEqual(app.staticTexts["importStatus"].label, "Cancelled; imported photos unchanged")

        open()
        selectPhoto(day: 2)
        picker.confirm()
        assertImported(["80×120 • green"])
    }

    func testSingleSelectionAndRepeatedPresentation() {
        app.buttons["Single"].tap()
        open()
        selectPhoto(day: 2)
        picker.confirmSingleSelectionIfNeeded()
        assertImported(["80×120 • green"])
        open()
        selectPhoto(day: 1)
        picker.confirmSingleSelectionIfNeeded()
        assertImported(["120×80 • red"])
    }
}

/// Inherit every real-picker journey so portrait and landscape cannot drift apart.
@MainActor
final class LandscapePickerTests: RealPickerTests {
    override var orientation: UIDeviceOrientation { .landscapeLeft }
}
