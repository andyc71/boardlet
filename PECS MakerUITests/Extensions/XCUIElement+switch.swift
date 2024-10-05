//
//  XCUIElement+switch.swift
//  PECS MakerUITests
//
//  Created by Andy on 01/11/2022.
//

import XCTest

extension XCUIElement{
    
    func setSwitch(on newValue: Bool) {
        if newValue == isSwitchOn() {
            return
        }
        if newValue != isSwitchOn() {
            self.tap()
            if newValue != isSwitchOn() {
                //According to Stack Overflow, this sometimes works.
                //https://stackoverflow.com/questions/76062670/swiftui-toggle-not-being-toggled-in-ui-test
                self.switches.firstMatch.tap()
            }
        }
    }
    
    func isSwitchOn() -> Bool {
        guard let switchValue = self.value as? String else {
            XCTFail("Unable to set switch value")
            return false
        }
        let isOn = switchValue == "1"
        return isOn
    }
}
