//
//  XCUIDevice.isiPad.swift
//  PECS MakerUITests
//
//  Created by Andy on 05/01/2023.
//

import XCTest

extension XCUIDevice {
    
    static var isiPad : Bool {
        // Simulator names are user-defined, including our disposable UUID names.
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
