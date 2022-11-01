//
//  XCUIElement+colorPicker.swift
//  PECS MakerUITests
//
//  Created by Andy on 01/11/2022.
//

import XCTest

extension XCUIElement{
    
    func setColorPicker(colorName: String) {
        //Tap the button to display the picker. The button is a child of the label
        self.children(matching: .other).element.children(matching: .button).element.tap()
        
        let elementsQuery = XCUIApplication().scrollViews.otherElements
        
        //Tap the required color
        elementsQuery.otherElements[colorName].tap()
        
        //elementsQuery.otherElements["dark gray 20"].tap()
        
        //Close the picker
        elementsQuery.buttons["close"].tap()
    }
}

