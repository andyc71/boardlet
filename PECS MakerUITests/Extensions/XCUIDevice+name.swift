//
//  XCUIDevice+name.swift
//  PECS MakerUITests
//
//  Created by Andy on 05/01/2023.
//

import XCTest

extension XCUIDevice {
    
    static var deviceName: String {

        guard let simulator = ProcessInfo().environment["SIMULATOR_DEVICE_NAME"] else { return "" }

        do {
            // The simulator name contains "Clone X of " inside the screenshot file when running parallelized UI Tests on concurrent devices
            let regex = try NSRegularExpression(pattern: "Clone [0-9]+ of ")
            let range = NSRange(location: 0, length: simulator.count)
            let simulatorName = regex.stringByReplacingMatches(in: simulator, range: range, withTemplate: "")
            return simulatorName
        }
        catch {
            XCTFail("Unable to create device name. RegEx failed. \(error.localizedDescription)")
            return ""
        }
    }

}
