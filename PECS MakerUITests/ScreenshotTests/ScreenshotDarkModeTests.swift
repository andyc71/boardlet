//
//  DarkModeTests.swift
//  PECS MakerUITests
//
//  Created by Andy on 09/04/2022.
//

import XCTest

class ScreenshotDarkModeTests: ScreenshotTopicsScreenTests {
    
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override var useDarkMode: Bool {
        get { return true }
    }
    
    override var screenshotName: String {
        ScreenshotNames.darkMode
    }
    

}
