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
        
        if XCUIDevice.isiPad {
            let photoCount = 8
            
            //Photos: Select images. This is just for the purposes of
            //the screenshot. In actuality, this will be overwritten
            //because we have passed the autofill Launch argument.
            selectPhotosFromMainMenu(count: photoCount, snapshotID: nil, recheckSelections: false)
            navigateToPhotoSelectionScreen()
        }
        else {
            //On iPhone we just snapshot the main menu.
        }
        
        snapshot(ScreenshotNames.darkMode)
        

    }

}
