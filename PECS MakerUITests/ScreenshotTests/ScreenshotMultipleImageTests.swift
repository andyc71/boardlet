//
//  PECS_MakerUITests.swift
//  PECS MakerUITests
//
//  Created by Andy on 24/09/2021.
//

import XCTest

class ScreenshotMultipleImageTests: PECSTestsBase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchArguments.append(LaunchArguments.autoFill)
    }
    
//    override func preLaunch() {
//    }
    
    func testEndToEndMultipleImages() throws {
        
        //The app is being passed the autofill setting meaning it will
        //select 9 photos automatically even if we choose new photos
        //from the photo browser. However it will only reset the photos
        //if it detects that the number has changed, so here we are
        //manually selecting 8.
        let photoCount = 8
        
        Snapshot.snapshot(ScreenshotNames.homeScreen)
        
        //Photos: Select images. This is just for the purposes of
        //the screenshot. In actuality, this will be overwritten
        //because we have passed the autofill Launch argument.
        selectPhotosFromMainMenu(count: photoCount, snapshotID: ScreenshotNames.photosScreen, recheckSelections: false)

        //Layout: Select A4 page size - any layout
        selectLayout(pageSize: .a4, orientation: .portrait, layout: PageLayout(width: 2, height: 3), snapshotID: ScreenshotNames.layoutScreen)
        
        //Titles: We have set the autofill launch argument, so in reality
        //these will be auto-filled, and we don't want the titles to be
        //typed in.
        completeTitles(count: photoCount, snapshotID: ScreenshotNames.titlesScreen, isAutoFilled: true)

        //Preview and Print
        completePreviewAndPrintBySaving(snapshotID: ScreenshotNames.previewScreen)
                
    }
    
}
