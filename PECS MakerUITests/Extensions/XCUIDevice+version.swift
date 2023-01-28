//
//  XCUIDevice+version.swift
//  PECS MakerUITests
//
//  Created by Andy on 04/01/2023.
//

import XCTest

extension XCUIDevice {
    
    var iosVersion : Double {
        
        guard let str = ProcessInfo().environment["SIMULATOR_RUNTIME_VERSION"] else {
            XCTFail("Unable to get IOS version")
            return 0.0 }
        
        guard let version = Double(str) else {
            XCTFail("Unable to parse IOS version from \(str)")
            return 0.0
        }
        
        return version

        
    }
    
    
}
