//
//  XCUIElement+colorPicker.swift
//  PECS MakerUITests
//
//  Created by Andy on 01/11/2022.
//

import XCTest

/*
extension XCUIElement{
    
    func setColorPicker(colorName: String, timeout: TimeInterval = 2) {
        //Tap the button to display the picker. The button is a child of the label
        self.children(matching: .other).element.children(matching: .button).element.tap()
        
        let elementsQuery = XCUIApplication().scrollViews.otherElements
        
        sleep(1)
        
        //print(XCUIApplication().debugDescription)
        
        //Tap the required color
        let colorButton = elementsQuery.otherElements[colorName]
        XCTAssertTrue(colorButton.waitForExistence(timeout: timeout), "Colour button named \(colorName) does not exist")
        colorButton.tap()
        
        //elementsQuery.otherElements["dark gray 20"].tap()
        
        //Close the picker
        let app = XCUIApplication()
        if UIDevice.current.userInterfaceIdiom == .pad {
            app/*@START_MENU_TOKEN@*/.otherElements["PopoverDismissRegion"]/*[[".otherElements[\"dismiss popup\"]",".otherElements[\"PopoverDismissRegion\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        }
        else {
            //XCUIApplication().children(matching: .window).element(boundBy: 0).tap()
            let closeButtonName = app.isSpanish ? "cerrar" : "close"
            elementsQuery.buttons[closeButtonName].tap()
        }
    }
}
*/

extension XCUIApplication {

    private func formattingColorControl(id: String) -> XCUIElement {
        // SwiftUI exposes ColorPicker as a ColorWell on iOS 18 and a Button
        // on newer runtimes. Its identifier and selected-colour value are stable.
        descendants(matching: .any).matching(identifier: id).firstMatch
    }

    func scrollFormatting(towardTop: Bool) {
        let scroll = scrollViews.containing(.button, identifier: "PopupHeader.closeButton").firstMatch
        // The middle of this sheet contains sliders that consume drag gestures.
        // Drag along its content margin to scroll without changing a setting.
        let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: towardTop ? 0.2 : 0.8))
        let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.02, dy: towardTop ? 0.8 : 0.2))
        start.press(forDuration: 0.01, thenDragTo: end)
    }
    
    func setColorPicker(id: String, colorName: String, timeout: TimeInterval = 2, retryCount: Int = 5, isSpanish: Bool) {
        
        let app = self

        if XCUIDevice.shared.iosVersion >= 16.0 {
            let pickerControl = app.formattingColorControl(id: id)
            let scroll = app.scrollViews.containing(.button, identifier: "PopupHeader.closeButton").firstMatch
            for _ in 0..<8 {
                if pickerControl.exists && pickerControl.isHittable { break }
                if pickerControl.exists && pickerControl.frame.midY < scroll.frame.midY {
                    app.scrollFormatting(towardTop: true)
                } else {
                    app.scrollFormatting(towardTop: false)
                }
            }
            guard pickerControl.exists && pickerControl.isHittable else {
                XCTFail("Colour control \(id) must be visible")
                return
            }
            // On iPad the accessibility frame includes the inert text label;
            // the colour well at the trailing edge opens the system picker.
            let systemPicker = app.otherElements["UIColorPickerView"]
            for _ in 0..<3 {
                pickerControl.coordinate(withNormalizedOffset: CGVector(dx: 0.97, dy: 0.5)).tap()
                if systemPicker.waitForExistence(timeout: 3) { break }
            }
            guard systemPicker.exists else {
                XCTFail("System colour picker did not open for \(id)")
                return
            }
        }
        else {
            //Get the control that needs to be tapped in order to display the
            //picker. It's not as simple as saying this is a button!
            let pickerControl = app.selectElement(.other, id: id)
            
            //Get the actual button to be tapped. The button is a child of the label
            if XCUIDevice.shared.iosVersion >= 15.0 {
                let pickerButton = pickerControl.children(matching: .other).element.children(matching: .button).element
                pickerButton.tap()
            }
            else {
                //Needed for IOS 14.5 iPhone. Not verified on iPad.
                let pickerButton = pickerControl.children(matching: .button).element
                pickerButton.tap()
            }
        }
        
        sleep(1)
        
        //print(XCUIApplication().debugDescription)
        
        //Tap the required color
        
        //let colorButton = elementsQuery.otherElements[colorName]
        //XCTAssertTrue(colorButton.waitForExistence(timeout: timeout), "Colour button named \(colorName) does not exist")
        //colorButton.tap()
        if let colorButton = app.selectOther(labelEndingIn: colorName, assertType: .noAssert) {
            colorButton.tap()
            // A delivered tap can precede the ColorPicker binding update. Verify
            // the named palette colors used by these tests before dismissing it.
            if !isSpanish, let expected = [" 0": "black", " 30": "green", " 93": "yellow"][colorName] {
                let control = app.formattingColorControl(id: id)
                let applied = NSPredicate { _, _ in
                    (control.value as? String)?.localizedCaseInsensitiveContains(expected) == true
                }
                if XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: applied, object: nil)], timeout: 5) != .completed {
                    // Selecting an explicit color is idempotent; retry only if
                    // the underlying control still reports the previous color.
                    colorButton.tap()
                    XCTAssertEqual(XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: applied, object: nil)], timeout: 10), .completed,
                                   "Color selection must apply to \(id): \(control.debugDescription)")
                }
            }
        }
        else if retryCount > 0 {
            //On IOS 15.5 we might fail to find it because not every colour
            //always gets an accessibility identifier
            //Close the picker and go back in so we get a refreshed screen
            //with the original color name.
            closeColorPicker(id: id, isSpanish: isSpanish)
            
            //Try the original color
            setColorPicker(id: id, colorName: colorName, retryCount: retryCount - 1, isSpanish: isSpanish)
            
            return
        }
        else {
            XCTFail("Unable to find colour button with name \(colorName)")
        }
        
        closeColorPicker(id: id, isSpanish: isSpanish)
        if !isSpanish, let expected = [" 0": "black", " 30": "green", " 93": "yellow"][colorName] {
            XCTAssertTrue((app.formattingColorControl(id: id).value as? String)?.localizedCaseInsensitiveContains(expected) == true,
                          "Dismissing the colour picker must preserve the selected colour for \(id)")
        }
    }

    private func waitForColorPickerDismissal(id: String, timeout: TimeInterval) -> Bool {
        let picker = otherElements["UIColorPickerView"]
        let control = formattingColorControl(id: id)
        var readySince: TimeInterval?
        let ready = NSPredicate { _, _ in
            // The native popover can briefly disappear from accessibility
            // during dismissal while still covering the formatting sheet.
            guard !picker.exists, control.exists, control.isHittable else {
                readySince = nil
                return false
            }
            let now = ProcessInfo.processInfo.systemUptime
            if let readySince { return now - readySince >= 1 }
            readySince = now
            return false
        }
        return XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: ready, object: nil)], timeout: timeout) == .completed
    }
    
    func closeColorPicker(id: String, isSpanish: Bool) {
        // The formatting sheet has its own Close button. Only choose the
        // system color picker's hittable close control, not the covered host.
        let names = isSpanish ? ["Cerrar", "cerrar"] : ["Close", "close"]
        for name in names {
            for button in buttons.matching(NSPredicate(format: "label == %@", name)).allElementsBoundByIndex {
                if button.identifier != "PopupHeader.closeButton" && button.isHittable {
                    button.tap()
                    if waitForColorPickerDismissal(id: id, timeout: 5) { return }
                }
            }
        }
        let picker = otherElements["UIColorPickerView"]
        if UIDevice.current.userInterfaceIdiom == .pad && picker.exists {
            let host = scrollViews.containing(.button, identifier: "PopupHeader.closeButton").firstMatch.frame
            let popover = picker.descendants(matching: .popover).firstMatch
            guard popover.exists else {
                XCTFail("System colour picker must expose its popover bounds")
                return
            }
            let bounds = popover.frame.insetBy(dx: -8, dy: -8)
            let candidates = [
                CGPoint(x: host.minX + 4, y: host.midY),
                CGPoint(x: host.maxX - 4, y: host.midY),
                CGPoint(x: host.midX, y: host.minY + 26)
            ]
            // A dismiss region's accessibility frame spans the entire screen;
            // its default tap point can land inside the palette and change color.
            for point in candidates where !bounds.contains(point) && windows.firstMatch.frame.contains(point) {
                coordinate(withNormalizedOffset: .zero)
                    .withOffset(CGVector(dx: point.x, dy: point.y)).tap()
                if waitForColorPickerDismissal(id: id, timeout: 5) { return }
            }
        }
        XCTFail("Unable to dismiss system colour picker \(id). \(debugDescription)")
    }
}
