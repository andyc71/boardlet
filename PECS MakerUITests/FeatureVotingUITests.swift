//
//  FeatureVotingUITests.swift
//  FeatureVotingUITests
//
//  Created by Andy on 23/05/2024.
//

import XCTest
@testable import FeatureFramework

typealias FeatureVotingUITestsBaseClass = PECSTestsBase

///NOTE: Can copy everything in this file between EasyPECS UI tests and FeatureFrameworkTestApp
///except for the extension at the bottom which is app specific.

///These tests are to test the Vote for New Features popups. Although they get tested in the
///FeaturesFramework test app, there's a risk we will forget to run it because it's separate. As
///the popups are qute fragie, it's best to make sure we have it in this suite of tests as well.
///The tests are completely standalone, so we could conisder adding into a new framework.
///There is a dependency on FeatureFramewor for AccessibilityIdentifiers, but that could be
///resolved with a file include.
class FeatureVotingUITests: FeatureVotingUITestsBaseClass {
    
    override var suppressFeatureVoting: Bool { false }

    override func setLaunchArguments() {
        super.setLaunchArguments()
        app.launchArguments.append("-mfResetFeatureVoting")
        app.launchArguments.append("-mfMockEmail")
    }

    override func tearDownWithError() throws {}
    

    // MARK: - Voting Prompt

    /// User should not see a prompt that asks them to vote until they have interacted with the
    /// app for a while (5 interactions). They can dismiss the prompt and it disappears. The app starts
    /// and it doesn't re-appear.
    func testFeatureVoting_DismissPrompt() throws {

        let voteButton = app.buttons[AccessibilityIdentifiersFF.votePromptVoteButton]
        //voteButton.waitForExistence(timeout: 2)
        XCTAssertFalse(voteButton.exists)

        //Interact with the app a few times to cause the voting prompt to appear.
        interactWithAppToCauseVotingPrompt()
        XCTAssertTrue(voteButton.exists)

        //Dismiss the prompt.
        let dismissButton = app.buttons[AccessibilityIdentifiersFF.votePromptDismissButton]
        XCTAssert(dismissButton.exists)
        dismissButton.forceTap()
        XCTAssertTrue(voteButton.waitForDisappearance(timeout: 2))

        //Restart the app and make sure the prompt didn't re-appear, even after
        //interacting for a while.
        app = XCUIApplication()
        app.launchArguments = []
        app.launch()
        
        // Wait for the app to restore state and move to the main menu. On iOS 27
        // the restored topic list can exist before its rows are hittable.
        let mainMenuItem = app.buttons[AccessibilityIdentifiers.MainMenu.selectPhotoButton]
        if !mainMenuItem.waitForExistence(timeout: 3) {
            if appVersionSupportsTopics {
                let topicButton = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0)]
                XCTAssertTrue(topicButton.waitForExistence(timeout: 5))
                expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: topicButton)
                waitForExpectations(timeout: 5)
                topicButton.tap()
                XCTAssertTrue(mainMenuItem.waitForExistence(timeout: 5))
            }
        }
        
        XCTAssertFalse(voteButton.exists)
        interactWithAppToCauseVotingPrompt()
        XCTAssertFalse(voteButton.exists)

    }
    
    // MARK: - Feature Voting
    
    func testFeatureVoting_Vote() throws {
        
        // Vote button should appear when the app starts after a little interaction
        interactWithAppToCauseVotingPrompt()

        // Tap it to display a list of features.
        let voteButton = app.buttons[AccessibilityIdentifiersFF.votePromptVoteButton]
        voteButton.tap()

        // Vote for the first feature on the list.
        let featureButton = app.buttons[AccessibilityIdentifiersFF.FeaturesView.featureCell(id: "talking-choice-board")]
        featureButton.tap()
        
        // Thank you for voting appears.
        let thankYouText = app.staticTexts[isSpanish ? "Gracias por votar" : "Thank you for voting"]
        XCTAssertTrue(thankYouText.exists)
        
        //Make sure the Thank you prompt disappears automatically.
        let exists = NSPredicate(format: "exists == false")
        expectation(for: exists, evaluatedWith: thankYouText, handler: nil)
        waitForExpectations(timeout: 6, handler: nil)
        
        //Make sure the prompt to vote disappears on the main screen.
        XCTAssertFalse(voteButton.exists)
        

    }
    
    func testFeatureVoting_SendEmail() throws {
        
        // Vote button should appear when the app starts after a little interaction
        interactWithAppToCauseVotingPrompt()

        // Vote button should appear when the app starts.
        // Tap it to display a list of features.
        let voteButton = app.buttons[AccessibilityIdentifiersFF.votePromptVoteButton]
        voteButton.tap()

        // Vote for the last feature on the list.
        let featureButton = app.buttons[AccessibilityIdentifiersFF.FeaturesView.featureCell(id: "other")]
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

        // The simulator mail composer confirms the mocked send before reporting
        // the result back to FeatureFramework.
        let mailConfirmationButton = app.buttons["OK"]
        XCTAssertTrue(mailConfirmationButton.waitForExistence(timeout: 2))
        mailConfirmationButton.tap()
        
        // Thank you for voting appears.
        let thankYouText = app.staticTexts[isSpanish ? "Gracias por votar" : "Thank you for voting"]
        XCTAssertTrue(thankYouText.waitForExistence(timeout: 2))
        
        //Make sure the Thank you prompt disappears automatically.
        let exists = NSPredicate(format: "exists == false")
        expectation(for: exists, evaluatedWith: thankYouText, handler: nil)
        waitForExpectations(timeout: 6, handler: nil)
        
        //Make sure the prompt to vote disappears on the main screen.
        XCTAssertFalse(voteButton.exists)
        

    }
}

extension FeatureVotingUITests {
    
    //Voting prompt isn't displayed automatically unless the user
    //interacts with the app (i.e. visits screens).
    func interactWithAppToCauseVotingPrompt() {


        //Need 5 interactions.
        
        //1
        XCTAssertTrue(navigateToLayoutScreen())
        returnToMainMenu()

        //2
        XCTAssertTrue(navigateToTitlesScreen())
        returnToMainMenu()
        
        //3
        navigateToPreviewScreen()
        returnToMainMenu()

        //4
        XCTAssertTrue(navigateToLayoutScreen())
        returnToMainMenu()

        //5
        XCTAssertTrue(navigateToTitlesScreen())
        //XCTAssertTrue(returnToMainMenu())


    }
}
