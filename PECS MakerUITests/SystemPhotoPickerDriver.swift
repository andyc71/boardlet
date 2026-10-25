import XCTest

/// Include this same source in every UI-test target that exercises Apple's picker.
/// Supports the English and Spanish screenshot locales; callers supply predicates for seeded photos.
@MainActor
struct SystemPhotoPickerDriver {
    let app: XCUIApplication

    private var cancelButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label IN %@ OR identifier IN %@",
                                         ["Cancel", "Cancelar"], ["Cancel", "Cancelar"])).firstMatch
    }
    // Observed in iOS 18 (Add) and iOS 26/27 (Done).
    private var confirmButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Add' OR label BEGINSWITH 'Añadir' OR label == 'Done' OR label == 'Listo' OR identifier == 'Add' OR identifier == 'OK'")).firstMatch
    }
    private var photos: XCUIElementQuery {
        app.images.matching(NSPredicate(format: "label BEGINSWITH 'Photo,' OR label BEGINSWITH 'Foto,'"))
    }
    private var gridScrollView: XCUIElement {
        app.scrollViews.matching(NSPredicate(format: "identifier == 'content_scroll_view' OR identifier == 'photosView_content_scroll_view'")).firstMatch
    }

    func assertOpen(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 15), app.debugDescription, file: file, line: line)
        XCTAssertTrue(photos.firstMatch.waitForExistence(timeout: 30), app.debugDescription, file: file, line: line)
        XCTAssertTrue(app.buttons["Photos"].exists || app.buttons["Fotos"].exists
                      || app.collectionViews["PhotosSidebarScrollView"].cells["Photos"].exists
                      || app.collectionViews["PhotosSidebarScrollView"].cells["Fotos"].exists,
                      app.debugDescription, file: file, line: line)
        // Verify actual Search UI, without relying on semantic-search indexing/results.
        XCTAssertTrue(app.buttons["Search"].exists || app.buttons["Buscar"].exists
                      || app.searchFields.firstMatch.exists
                      || app.textViews.matching(NSPredicate(format: "value == 'Search your library…'")).firstMatch.exists
                      || app.otherElements["photosSearchBar"].textViews.firstMatch.exists,
                      app.debugDescription, file: file, line: line)
        // The privacy explainer can consume most of the grid in compact landscape.
        if app.staticTexts["Private Access to Photos"].exists {
            let close = app.buttons["Close"].firstMatch
            if close.exists && close.isHittable { close.tap() }
        }
        captureEvidence(named: "System picker open")
    }

    func selectPhoto(matching predicate: NSPredicate, file: StaticString = #filePath, line: UInt = #line) {
        let candidates = photos.matching(predicate)
        let target = candidates.firstMatch
        // Larger libraries virtualize offscreen cells, so a matching photo may not
        // enter the accessibility tree until the actual grid has been scrolled.
        // Scan in both directions; selection still requires a unique label match.
        for upward in [true, false] {
            for _ in 0..<16 {
                if target.exists { break }
                let scroll = gridScrollView
                XCTAssertTrue(scroll.exists, app.debugDescription, file: file, line: line)
                if upward { scroll.swipeUp(velocity: .slow) }
                else { scroll.swipeDown(velocity: .slow) }
            }
            if target.exists { break }
        }
        XCTAssertTrue(target.waitForExistence(timeout: 10), app.debugDescription, file: file, line: line)
        // Repeated screenshot runs can import the same dated fixture again.
        let scroll = gridScrollView
        for _ in 0..<8 {
            let visible = gridViewport
            if photoCenterIsVisible(target.frame, in: visible) { break }
            XCTAssertTrue(scroll.exists, app.debugDescription, file: file, line: line)
            let above = target.frame.midY < visible.midY
            // A slow press-and-drag can activate Photos' long-press preview
            // instead of scrolling (observed on iOS 26.5). Use a swipe gesture.
            if above { scroll.swipeDown(velocity: .slow) }
            else { scroll.swipeUp(velocity: .slow) }
        }
        // Remote Photos cells can report hittable while their default hit point
        // misses the image, especially after reopening on iOS 27. Use the
        // observed cell center and require the native Selected trait to change.
        for _ in 0..<2 {
            if !cancelButton.exists || target.isSelected { return }
            let frame = target.frame
            XCTAssertTrue(photoCenterIsVisible(frame, in: gridViewport), app.debugDescription, file: file, line: line)
            XCTAssertGreaterThan(frame.width, 0, file: file, line: line)
            XCTAssertGreaterThan(frame.height, 0, file: file, line: line)
            // Duo's compact picker floats controls over the right edge and
            // centre of the grid. Tap inside the left side of each photo.
            let tapX: CGFloat = app.windows.firstMatch.frame.height < 700 ? 0.1 : 0.5
            target.coordinate(withNormalizedOffset: CGVector(dx: tapX, dy: 0.5)).tap()
            // XCUIElement queries inside an XCTWaiter predicate can lose their
            // remote Photos snapshot while the picker updates its selection.
            for _ in 0..<10 {
                if !cancelButton.exists || (target.exists && target.isSelected) { return }
                Thread.sleep(forTimeInterval: 0.5)
            }
            // Retry only a selection the picker has not acknowledged. Tapping
            // an already-selected cell would deselect it and change the order.
        }
        XCTFail("The native picker did not acknowledge the requested photo selection. \(app.debugDescription)", file: file, line: line)

    }

    private func photoCenterIsVisible(_ frame: CGRect, in viewport: CGRect) -> Bool {
        // Only the observed centre is tapped. Requiring every pixel of the cell
        // to be visible can oscillate between scroll positions when a cell edge
        // sits just under the navigation bar (observed on iOS 18.4).
        viewport.insetBy(dx: 8, dy: 8).contains(CGPoint(x: frame.midX, y: frame.midY))
    }

    private var gridViewport: CGRect {
        let scroll = gridScrollView
        // XCUIApplication.frame can retain the portrait bounds after Duo unfolds.
        // The active window tracks the picker’s actual landscape geometry.
        let window = app.windows.firstMatch.frame
        let screen = scroll.exists ? scroll.frame.intersection(window) : window
        let navigation = app.navigationBars.matching(NSPredicate(format: "identifier IN %@",
                                                                 ["Photos", "Fotos"])).firstMatch
        let top = navigation.exists ? navigation.frame.maxY : screen.minY
        // iPadOS 27 exposes entire container-sized Toolbar elements; those are not
        // bottom bars. Only subtract a compact bar that overlaps the photo pane.
        let sidebar = app.collectionViews["PhotosSidebarScrollView"].firstMatch
        let left = sidebar.exists ? max(screen.minX, sidebar.frame.maxX) : screen.minX
        let toolbar = app.toolbars["Toolbar"].firstMatch
        var bottom = screen.maxY
        if toolbar.exists {
            let frame = toolbar.frame
            if frame.height < screen.height / 2 && frame.minY >= top && frame.maxX > left {
                bottom = frame.minY
            }
        }
        // On iPhone Duo the toolbar reports the entire picker frame. Its
        // controls still cover the bottom photo row, so use their actual top.
        for label in ["Sort and Filter", "Search", "Ordenar y filtrar", "Buscar"] {
            let button = app.buttons[label].firstMatch
            if button.exists, button.frame.minY > screen.midY {
                bottom = min(bottom, button.frame.minY)
            }
        }
        return CGRect(x: left, y: top, width: max(0, screen.maxX - left), height: max(0, bottom - top))
    }

    func confirm(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5), app.debugDescription, file: file, line: line)
        XCTAssertTrue(confirmButton.isEnabled, file: file, line: line)
        confirmButton.tap()
    }

    func confirmSingleSelectionIfNeeded() {
        // Single-selection configurations may return immediately or reveal a
        // confirmation button after the remote picker updates its selection.
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !cancelButton.exists || (confirmButton.exists && confirmButton.isEnabled)
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed,
                       "Single selection must dismiss or offer confirmation")
        if cancelButton.exists { confirmButton.tap() }
    }

    func cancel() { cancelButton.tap() }

    func assertDismissed(file: StaticString = #filePath, line: UInt = #line) {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: cancelButton)
        let result = XCTWaiter.wait(for: [gone], timeout: 10)
        if result != .completed {
            captureEvidence(named: "System picker failed to dismiss")
        }
        XCTAssertEqual(result, .completed, file: file, line: line)
    }

    func captureEvidence(named name: String) {
        XCTContext.runActivity(named: name) { activity in
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "\(name) hierarchy"
            hierarchy.lifetime = .keepAlways
            activity.add(hierarchy)
            // App-only captures can be cropped/offset after simulator rotation.
            let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            screenshot.name = name
            screenshot.lifetime = .keepAlways
            activity.add(screenshot)
        }
    }
}
