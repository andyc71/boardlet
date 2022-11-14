//
//  XCUIElement+colorPicker.swift
//  PECS MakerUITests
//
//  Created by Andy on 01/11/2022.
//

import XCTest

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

