//
//  ScreenshotNoImagesTests.swift
//  ScreenshotNoImagesTests
//
//  Created by Andy on 14/01/2023.
//

import XCTest

//Purpose of this test is to take a screenshot when there are no images selected.
//All the other screenshot tests will autopopulate the photos which means the
//Select Photos icon on the Main Menu will show a tick next to it.
class ScreenshotNoImagesTests: PECSTestsBase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func setLaunchArguments() {
        super.setLaunchArguments()
        //Don't auto-populate.
        //app.launchArguments.append(LaunchArguments.autoFillSingle)
    }
    
    func testMainMenuWithNoImageSelections() throws {

        Snapshot.snapshot(ScreenshotNames.homeScreen)
                        
    }

    
}
