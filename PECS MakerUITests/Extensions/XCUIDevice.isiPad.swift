//
//  XCUIDevice.isiPad.swift
//  PECS MakerUITests
//
//  Created by Andy on 05/01/2023.
//

import XCTest

extension XCUIDevice {
    
    static var isiPad : Bool {
        let deviceName = XCUIDevice.deviceName
        guard deviceName != "" else { return false }
        if deviceName.starts(with: "iPad") {
            return true
        }
        else {
            return false
        }
    }
}
