//
//  XCUITest+tapButton.swift
//  PECS MakerUITests
//
//  Created by Andy on 22/12/2022.
//

import XCTest

extension XCUIApplication {

    func tapButton(id: String, canForce: Bool = true, context: String = "") {
        let menuButton = self.buttons[id]
        guard menuButton.waitForExistence(timeout: 2) else {
            XCTFail("\(context): Button named \(menuButton) does not exist")
            return
        }
        menuButton.tap(canForce: canForce)
    }
    
    func forceTapButton(id: String, context: String = "") {
        let menuButton = self.buttons[id]
        guard menuButton.waitForExistence(timeout: 2) else {
            XCTFail("\(context): Button named \(menuButton) does not exist")
            return
        }
        menuButton.forceTap()
    }


}
