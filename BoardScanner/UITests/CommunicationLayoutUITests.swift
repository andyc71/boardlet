import XCTest

final class CommunicationLayoutUITests: XCTestCase {
    @MainActor
    func testMotorPlanLandscapeFitsWidthAndScrollsToBottom() throws {
        let env = ProcessInfo.processInfo.environment
        guard let input = env["TD_SNAP_FIXTURE"], !input.isEmpty else {
            throw XCTSkip("Supply Motor Plan fixture")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
                               "--import-test-document", input]
        if let library = env["TD_SYMBOL_LIBRARY"], !library.isEmpty {
            app.launchArguments += ["--symbol-library", library]
        }
        app.launch()
        defer { XCUIDevice.shared.orientation = .portrait }
        let grid = app.descendants(matching: .any).matching(identifier: "snapGrid").firstMatch
        XCTAssertTrue(grid.waitForExistence(timeout: 120))
        app.setWindowOrientation(.landscapeLeft)
        let cells = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'snapButton_'"))
        XCTAssertEqual(cells.count, 66)
        let first = app.buttons["snapButton_2804"]
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            grid.frame.width > app.windows.firstMatch.frame.width * 0.75
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 5), .completed)
        // Tap physical slot centres, not accessibility activation points: this
        // catches rendering/hit-region disagreements that element.tap misses.
        let pitch = first.frame.width + 8
        let left = app.buttons["speakMessage"].frame.minX
        let origin = app.coordinate(withNormalizedOffset: .zero)
        origin.withOffset(CGVector(dx: left + pitch * 1.5 - 4,
                                   dy: first.frame.midY)).tap()
        let message = app.descendants(matching: .any).matching(identifier: "communicationMessage").firstMatch
        XCTAssertEqual(message.value as? String, "I")
        app.buttons["clearMessage"].tap()
        origin.withOffset(CGVector(dx: left + pitch * 2.5 - 4,
                                   dy: first.frame.midY)).tap()
        XCTAssertEqual(message.value as? String, "you")
        app.buttons["clearMessage"].tap()
        let before = first.frame
        for cell in cells.allElementsBoundByIndex {
            XCTAssertGreaterThanOrEqual(cell.frame.minX, grid.frame.minX - 1, cell.label)
            XCTAssertLessThanOrEqual(cell.frame.maxX, grid.frame.maxX + 1, cell.label)
        }
        let last = cells.allElementsBoundByIndex.max { $0.frame.maxY < $1.frame.maxY }!
        XCTAssertGreaterThan(last.frame.maxY, grid.frame.maxY)
        grid.swipeUp()
        grid.swipeUp()
        XCTAssertLessThan(first.frame.minY, before.minY - 20)
        XCTAssertLessThanOrEqual(last.frame.maxY, grid.frame.maxY + 1)
        XCTAssertTrue(last.isHittable)
        XCTAssertEqual(first.frame.minX, before.minX, accuracy: 1)
        for cell in cells.allElementsBoundByIndex {
            XCTAssertGreaterThanOrEqual(cell.frame.minX, grid.frame.minX - 1, cell.label)
            XCTAssertLessThanOrEqual(cell.frame.maxX, grid.frame.maxX + 1, cell.label)
        }
        origin.withOffset(CGVector(dx: left + pitch * 3.5 - 4, dy: last.frame.midY)).tap()
        XCTAssertEqual(message.value as? String, "make")
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Motor Plan bottom row reachable in landscape"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testLandscapeOptionsOpensEditor() throws {
        let input = try SnapTestFixture.make()
        defer { try? FileManager.default.removeItem(at: input) }
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
                               "--import-test-document", input.path]
        app.launch()
        XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 20))
        app.setWindowOrientation(.landscapeLeft)
        app.tapBoardControl("toggleEditing")
        let save = app.buttons["Save"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: save)
        let result = XCTWaiter.wait(for: [ready], timeout: 5)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "Landscape editor toolbar"
        shot.lifetime = .keepAlways
        add(shot)
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTAssertEqual(result, .completed)
        save.tap()
        XCTAssertTrue(app.staticTexts["Saved on this device"].waitForExistence(timeout: 10))
        app.setWindowOrientation(.portrait)
    }

    @MainActor
    func testMotorPlanUsesCommunicationSpaceAndSourceGrid() throws {
        let env = ProcessInfo.processInfo.environment
        guard let input = env["TD_SNAP_FIXTURE"], !input.isEmpty,
              let library = env["TD_SYMBOL_LIBRARY"], !library.isEmpty else {
            throw XCTSkip("Supply the Motor Plan page set and symbol library")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
                               "--import-test-document", input, "--symbol-library", library]
        app.launch()
        // A fully fitting grid may be exposed as a container rather than a scroll view.
        let grid = app.descendants(matching: .any).matching(identifier: "snapGrid").firstMatch
        let importStart = Date()
        let loaded = grid.waitForExistence(timeout: 90)
        let timing = XCTAttachment(string: "Imported grid ready: \(loaded); wait: \(Date().timeIntervalSince(importStart)) seconds")
        timing.lifetime = .keepAlways
        add(timing)
        if !loaded {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.lifetime = .keepAlways
            add(shot)
        }
        XCTAssertTrue(loaded)
        for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
            app.setWindowOrientation(orientation)
            let window = app.windows.firstMatch.frame
            let geometry = XCTAttachment(string: "Window: \(window); grid: \(grid.frame); grid height fraction: \(grid.frame.height / window.height)")
            geometry.name = "Communication space \(orientation.rawValue)"
            geometry.lifetime = .keepAlways
            add(geometry)
            XCTAssertGreaterThan(grid.frame.height / window.height, 0.60,
                                 "Communication choices must occupy most of the screen")
            XCTAssertFalse(app.buttons["createMenu"].exists)
            XCTAssertFalse(app.buttons["boardLibrary"].exists)
            XCTAssertFalse(app.staticTexts["boardStatus"].exists)
            XCTAssertTrue(app.buttons["boardOptions"].isHittable)
            XCTAssertTrue(app.buttons["speakMessage"].isHittable)
            XCTAssertTrue(app.buttons["clearMessage"].isHittable)
            let quickFires = app.buttons["snapButton_2804"]
            XCTAssertTrue(quickFires.isHittable)
            let cells = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'snapButton_'"))
            if window.width > 1000 && orientation.isLandscape {
                XCTAssertEqual(cells.count, 66)
                for cell in cells.allElementsBoundByIndex {
                    XCTAssertTrue(grid.frame.contains(cell.frame), cell.identifier)
                    XCTAssertGreaterThanOrEqual(cell.frame.width, 44)
                    XCTAssertGreaterThanOrEqual(cell.frame.height, 44)
                }
            }
            let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            shot.name = "Compact Motor Plan \(orientation.rawValue)"
            shot.lifetime = .keepAlways
            add(shot)
        }
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND label == 'I'")).firstMatch.tap()
        let message = app.descendants(matching: .any).matching(identifier: "communicationMessage").firstMatch
        XCTAssertEqual(message.value as? String, "I")
        app.buttons["clearMessage"].tap()
        XCTAssertEqual(message.value as? String, "Empty")
        app.tapBoardControl("toggleEditing")
        let saveReady = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: app.buttons["Save"])
        XCTAssertEqual(XCTWaiter.wait(for: [saveReady], timeout: 5), .completed)
        XCTAssertEqual(app.buttons["snapImportWarning"].label, "1 unavailable image")
        app.buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Saved on this device"].waitForExistence(timeout: 15))
        app.tapBoardControl("toggleEditing")
        app.setWindowOrientation(.portrait)
    }
}
