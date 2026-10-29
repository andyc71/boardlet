//
//  WhatsNewUITests.swift
//  FeatureVotingUITests
//
//  Created by Andy on 23/05/2024.
//

import XCTest
@testable import EngagementKit

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
        app.launchEnvironment["PECS_TEST_STARTUP"] = "existing"
        app.launchArguments.append("-mfResetWhatsNew")
    }

    override func tearDownWithError() throws {}

    func testAccessibilityLandscapeKeepsContinueAvailable() throws {
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        let title = app.staticTexts[AccessibilityIdentifiersFF.FeaturesView.title]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        let lastFeature = app.staticTexts[isSpanish ? "Tarjetas de solo texto" : "Text only cards"]
        let scrollView = app.scrollViews["WhatsNew.featureScroll"]
        for _ in 0..<12 where !lastFeature.isHittable {
            // Start above the pinned Continue area rather than the scroll view's bottom edge.
            scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.05, thenDragTo: scrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.1)))
        }
        XCTAssertTrue(lastFeature.isHittable)
        let continueButton = app.buttons[AccessibilityIdentifiersFF.FeaturesView.closeButton]
        XCTAssertTrue(continueButton.isHittable)
        let capture = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        capture.name = "WhatsNew-accessibility-landscape"
        capture.lifetime = .keepAlways
        add(capture)
        continueButton.tap()
        XCTAssertTrue(title.waitForDisappearance(timeout: 5))
    }
    

    // MARK: - What's New Prompt

    /// User should see a what's new prompt the first time they go into the app
    /// (bearing in mind that we passed the -mfResetWhatsNew argument.
    func testWhatsNewScreen() throws {

        //Make sure the What's New screen appears.
        let featuresViewTitle = app.staticTexts[AccessibilityIdentifiersFF.FeaturesView.title]
        //voteButton.waitForExistence(timeout: 2)
        XCTAssertTrue(featuresViewTitle.waitForExistence(timeout: 5))

        let featureTitles = isSpanish
            ? ["Actualizado para iOS 27", "Diseños flexibles", "Búsqueda de símbolos", "Tarjetas de solo texto"]
            : ["Updated for iOS 27", "Flexible layouts", "Symbol search", "Text only cards"]
        for title in featureTitles {
            XCTAssertTrue(app.staticTexts[title].exists)
        }
        let portrait = XCTAttachment(screenshot: app.screenshot())
        portrait.name = "WhatsNew-iPhone-portrait"
        portrait.lifetime = .keepAlways
        add(portrait)

        XCUIDevice.shared.orientation = .landscapeLeft
        let landscapeReady = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in self.app.frame.width > self.app.frame.height }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [landscapeReady], timeout: 5), .completed)
        // Allow the system sheet's rotation animation to finish before capture.
        Thread.sleep(forTimeInterval: 2)
        let titles = featureTitles.map { app.staticTexts[$0] }
        for title in titles {
            XCTAssertTrue(title.isHittable, "All four updates should be visible in landscape")
        }
        XCTAssertLessThan(titles[0].frame.maxX, titles[1].frame.minX)
        XCTAssertEqual(titles[0].frame.minY, titles[1].frame.minY, accuracy: 2)
        XCTAssertEqual(titles[2].frame.minY, titles[3].frame.minY, accuracy: 2)
        XCTAssertGreaterThan(titles[2].frame.minY, titles[0].frame.maxY)
        XCTAssertTrue(app.buttons[AccessibilityIdentifiersFF.FeaturesView.closeButton].isHittable)
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "WhatsNew-iPhone-landscape"
        landscape.lifetime = .keepAlways
        add(landscape)
        XCUIDevice.shared.orientation = requiredOrientation
        
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

