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
        
        //We can't just parse the string as a double because we might have a majorVersion.minorVersion.pointRelease
        
        let versionComponents = str.split(separator: ".")
        guard versionComponents.count > 0 else {
            XCTFail("Unable to parse IOS version from \(str)")
            return 0.0
        }
        
        
        guard let majorVersion = Double(versionComponents[0]) else {
            XCTFail("Unable to parse IOS version from \(str)")
            return 0.0
        }
        
        if versionComponents.count > 1 {
            guard let minorVersion = Double(versionComponents[1]) else {
                XCTFail("Unable to parse IOS version from \(str)")
                return 0.0
            }
            return majorVersion + (minorVersion / 10)
        }
        else {
            return majorVersion
        }
        
    }
    
    
}
