//
//  FeatureVotingUITests.swift
//  FeatureVotingUITests
//
//  Created by Andy on 23/05/2024.
//

import XCTest
@testable import FeatureFramework

///These tests are to test the Vote for New Features popups. Although they get tested in the
///FeaturesFramework test app, there's a risk we will forget to run it because it's separate. As
///the popups are qute fragie, it's best to make sure we have it in this suite of tests as well.
///The tests are completely standalone, so we could conisder adding into a new framework.
///There is a dependency on FeatureFramewor for AccessibilityIdentifiers, but that could be
///resolved with a file include.
class FeatureVotingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-mfResetFeatureVoting")
        app.launchArguments.append("-mfMockEmail")
        app.launch()
    }

    override func tearDownWithError() throws {}

    // MARK: - Voting Prompt

    /// User should see a prompt that asks them to vote. They can dismiss it and it disappears. The app starts
    /// and it doesn't re-appear.
    func testVotingPrompt_Dismiss() throws {
        //let votePromptView = app.staticTexts[AccessibilityIdentifiers.votePromptView]
        //XCTAssert(votePromptView.exists)

        let voteButton = app.buttons[AccessibilityIdentifiersFF.votePromptVoteButton]
        //voteButton.waitForExistence(timeout: 2)
        XCTAssert(voteButton.exists)
        //voteButton.tap()

        //XCTAssert(app.staticTexts["Vote for Features"].exists)

        let dismissButton = app.buttons[AccessibilityIdentifiersFF.votePromptDismissButton]
        XCTAssert(dismissButton.exists)
        dismissButton.tap()
        XCTAssertFalse(voteButton.exists)

        app = XCUIApplication()
        app.launchArguments = []
        app.launch()
        XCTAssertFalse(voteButton.exists)

    }

    // MARK: - Feature Voting
    
    func testFeatureVoting() throws {

        // Vote button should appear when the app starts.
        // Tap it to display a list of features.
        let voteButton = app.buttons[AccessibilityIdentifiersFF.votePromptVoteButton]
        voteButton.tap()

        // Vote for the first feature on the list.
        let featureButton = app.buttons[AccessibilityIdentifiersFF.featureCell(id: "topics")]
        featureButton.tap()
        
        // Thank you for voting appears.
        let thankYouText = app.staticTexts["Thank you for voting"]
        XCTAssertTrue(thankYouText.exists)
        
        //Make sure the Thank you prompt disappears automatically.
        let exists = NSPredicate(format: "exists == false")
        expectation(for: exists, evaluatedWith: thankYouText, handler: nil)
        waitForExpectations(timeout: 6, handler: nil)
        
        //Make sure the prompt to vote disappears on the main screen.
        XCTAssertFalse(voteButton.exists)
        

    }
    
    func testFeatureVotingWithEmail() throws {

        // Vote button should appear when the app starts.
        // Tap it to display a list of features.
        let voteButton = app.buttons[AccessibilityIdentifiersFF.votePromptVoteButton]
        voteButton.tap()

        // Vote for the last feature on the list.
        let featureButton = app.buttons[AccessibilityIdentifiersFF.featureCell(id: "other")]
        featureButton.tap()
        
        // Compose mail appears. User cancels.
        let cancelMailButton = app.buttons["Cancel"]
        cancelMailButton.tap()

        // We are back on the main screen. Repeat the process, but this time we
        // should actually send the email.
        voteButton.tap()
        featureButton.tap()
        
        // Compose mail appears. User sends email.
        let sendMailButton = app.buttons["Send"]
        sendMailButton.tap()
        
        // Thank you for voting appears.
        let thankYouText = app.staticTexts["Thank you for voting"]
        XCTAssertTrue(thankYouText.exists)
        
        //Make sure the Thank you prompt disappears automatically.
        let exists = NSPredicate(format: "exists == false")
        expectation(for: exists, evaluatedWith: thankYouText, handler: nil)
        waitForExpectations(timeout: 6, handler: nil)
        
        //Make sure the prompt to vote disappears on the main screen.
        XCTAssertFalse(voteButton.exists)
        

    }
}
