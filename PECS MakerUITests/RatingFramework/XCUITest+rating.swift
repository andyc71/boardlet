//
//  XCUITest+rating.swift
//  SharedSwiftUI
//
//  Created by Andy on 10/12/2022.
//
// Ideally this would live in its own test framework, but for
// now it is manually included in whatever target needs it.
// That's easy for RatingTestApp because it lives within the
// same framework as this file, but we have to do a manual file
// addition for any other app's UI tests.

import XCTest

extension XCUIApplication {
    
    //Helper function to deal with the standard IOS rating alert.
    //Limitations:
    //- We can't get granular control over whether the actual rating
    //  so rate=true just causes 5* to be chosen.
    //- We can't actually subumit the rating, so we have to cancel
    //  after choosing the rating
    //- rate=false causes the rating dialog to be cancelled.
    func submitRating(rate: Bool) {
        
        let app = self
        
        if rate {
            
            let elementsQuery = app.scrollViews.otherElements

            let starControl = elementsQuery.sliders["Rating"]
            if starControl.waitForExistence(timeout: 2) {
                starControl.adjust(toNormalizedSliderPosition: 1)
            }
            else {
                //Rating control shows up as a slider in the Accessibility Inspector
                //but the query only finds it as otherElements. This means we can
                //swipe on it, but we cannot set a value as a slider.
                let starControl = elementsQuery.otherElements["Rating"]
                XCTAssertTrue(starControl.waitForExistence(timeout: 1))
                starControl.swipeRight()
            }
            
            //Can't actually submit the rating in the simulator.
            //If this fails it's likely that Cancel hasn't appeared
            //because we didn't manage to hit the rating star control (above)
            elementsQuery.buttons["Cancel"].tap()
            
        }
        else {
            let rateButton = app.scrollViews.otherElements.buttons["Not Now"]
            XCTAssertTrue(rateButton.waitForExistence(timeout: 1))
            rateButton.tap()
        }
        
    }
}

