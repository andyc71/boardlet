//
//  DarkModeTests.swift
//  PECS MakerUITests
//
//  Created by Andy on 09/04/2022.
//

import XCTest

class ScreenshotDarkModeTests: PECSTestsBase {
    
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        //app.launchArguments += ["-AppleLanguages", "(es)"]
        //launchArguments.append("-AppleInterfaceStyle") launchArguments.append("Dark")
    }
    
    override var useDarkMode: Bool {
        get { return true }
    }
    
    func testStartScreenForDarkMode() {
        
        //Check the header
        //let header = app.staticTexts[LocalizableIDs.StartScreen.title]
        //XCTAssertNotNil(header)
        //Even though the readable title says "My Family", the
        //accessible title says "Home Screen".
        //XCTAssertEqual(header.label, "Home Screen")

        snapshot(ScreenshotNames.darkMode)
        

    }

}
