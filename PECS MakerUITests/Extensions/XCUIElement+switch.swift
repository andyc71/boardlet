//
//  XCUIElement+switch.swift
//  PECS MakerUITests
//
//  Created by Andy on 01/11/2022.
//

import XCTest

extension XCUIElement{
    
    func setSwitch(on newValue: Bool) {
        guard let switchValue = self.value as? String else {
            XCTFail("Unable to set switch value")
            return
        }
        let currentValue = switchValue == "1"
        if newValue == currentValue {
            return
        }
        self.tap()
    }
}
