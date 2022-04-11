//
//  PECS_MakerUITests.swift
//  PECS MakerUITests
//
//  Created by Andy on 24/09/2021.
//

import XCTest

class ScreenshotTests: PECSTestsBase {
    

    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchArguments.append(LaunchArguments.autoFill)
    }
    
    func testEndToEndWithMultiplePhotos() throws {

        let photoCount = 9
        
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
        
        //Store the printed image somewhere it can be accessed
        //and eye-balled later. Consider giving it a descriptive
        //name, or adding a page to describe the layout. Or add
        //a description to the PDF.
        

        //Repeat for other layouts.
        
        
    }
    
}
