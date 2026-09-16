//
//  XCUIElement+clearText.swift
//  PECS MakerUITests
//
//  Created by Andy on 29/05/2023.
//

import Foundation
import XCTest

extension XCUIElement {
    
    func clearText() {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non string value")
            return
        }

        // Callers focus the field and wait for the keyboard before clearing it.
        // Tapping again can open the system edit menu and leave XCTest waiting
        // indefinitely for UI quiescence before it sends the delete keys.
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)

    }
}
