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
    
    func setColorPicker(id: String, colorName: String, timeout: TimeInterval = 2, retryCount: Int = 5, isSpanish: Bool) {
        
        let app = self

        if XCUIDevice.shared.iosVersion >= 16.0 {
            app.tapButton(id: id)
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
        if let colorButton = app.selectOther(colorName, assertType: .noAssert) {
            colorButton.tap()
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
    }
    
    func closeColorPicker(id: String, isSpanish: Bool) {
        
        let app = self

        //Close the picker
        if UIDevice.current.userInterfaceIdiom == .pad {
            //This should work, but if we have 2 popovers displayed it will fail
            //because there are multiple matching elements.
            //app.otherElements["PopoverDismissRegion"].tap()

            //So the workaround is to iterate through all the popovers and find the
            //one with a tappable background.
            let popovers = app.otherElements.matching(identifier: "PopoverDismissRegion")
            let popoverCount = popovers.count
            for i in 0..<popoverCount {
                let popover = popovers.element(boundBy: i)
                if popover.isHittable {
                    popover.tap()
                    return
                }
            }
            XCTFail("Unable to dismiss popover \(id) because none of the \(popoverCount) dismiss region were tappable")
        }
        else {
            //XCUIApplication().children(matching: .window).element(boundBy: 0).tap()
            let elementsQuery = XCUIApplication().scrollViews.otherElements
            let closeButtonName = isSpanish ? "cerrar" : "close"
            elementsQuery.buttons[closeButtonName].tap()
        }
    }
}

