//
//  XCUITest+tapButton.swift
//  PECS MakerUITests
//
//  Created by Andy on 22/12/2022.
//

import XCTest

extension XCUIApplication {

    func tapButton(id: String, context: String = "") {
        let menuButton = self.buttons[id]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 2), "\(context): Button named \(menuButton) does not exist")
        menuButton.tap()
    }

}
