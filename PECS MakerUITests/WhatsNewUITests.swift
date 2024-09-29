//
//  WhatsNewUITests.swift
//  FeatureVotingUITests
//
//  Created by Andy on 23/05/2024.
//

import XCTest
@testable import FeatureFramework

typealias WhatsNewUITestsBaseClass = PECSTestsBase

///NOTE: Can copy everything in this file between EasyPECS UI tests and FeatureFrameworkTestApp
///except for the extension at the bottom which is app specific.

///These tests are to test the What's New screen.
///The tests are completely standalone, so we could conisder adding into a new framework.
///There is a dependency on FeatureFramework for AccessibilityIdentifiers, but that could be
///resolved with a file include.
class WhatsNewUITests: WhatsNewUITestsBaseClass {
    
    override var suppressWhatsNewScreen: Bool { false }

    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchArguments.append("-mfResetWhatsNew")
    }

    override func tearDownWithError() throws {}
    

    // MARK: - What's New Prompt

    /// User should see a what's new prompt the first time they go into the app
    /// (bearing in mind that we passed the -mfResetWhatsNew argument.
    func testWhatsNewScreen() throws {

        //Make sure the What's New screen appears.
        let featuresViewTitle = app.staticTexts[AccessibilityIdentifiersFF.FeaturesView.title]
        //voteButton.waitForExistence(timeout: 2)
        XCTAssertTrue(featuresViewTitle.exists)
        
        //Dismiss the prompt.
        let dismissButton = app.buttons[AccessibilityIdentifiersFF.FeaturesView.closeButton]
        XCTAssert(dismissButton.exists)
        dismissButton.forceTap()
        XCTAssertTrue(featuresViewTitle.waitForDisappearance(timeout: 2))

        //Restart the app and make sure the prompt didn't re-appear
        app = XCUIApplication()
        app.launchArguments = []
        app.launch()
        XCTAssertFalse(featuresViewTitle.exists)

    }
    
}

