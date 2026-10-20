//
//  ScreenshotTopicsScreenTests.swift
//  PECS ScreenshotTopicsScreenTests
//
//  Created by Andy on 10/01/2023.
//

import XCTest

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

class ScreenshotTopicsScreenTests: PECSTestsBase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func prepareFixturesBeforeLaunch() {
        super.prepareFixturesBeforeLaunch()
        // Fastlane's locale is available before choosing the localized fixtures.
        copySampleTopics()
    }
    
    var screenshotName: String {
        ScreenshotNames.topicsScreen
    }
    
    func getFileResourceUrl(resourceName: String, ofType: String) -> URL? {
        
        let testBundle = Bundle(for: type(of: self))
        guard let resourcePath = testBundle.path(forResource: resourceName, ofType: ofType) else {
            XCTFail("Failed to load index file as asset")
            return nil
        }
        return URL(fileURLWithPath: resourcePath)
    }

    func getJSONIndexFileResourceUrl(resourceName: String) -> URL? {
        
        return getFileResourceUrl(resourceName: resourceName, ofType: "json")
    }
    
    func isDirectory(at path: String) -> Bool {
        let fileManager = FileManager.default
        var isDir : ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }
    
    //Checks sourceFileName for a languange prefix (e.g. "EN_") and compares
    //that with the language in use. If they match, it returns the filename,
    //without that prefix, appended to targetDirectory. If they don't match
    //then it returns nil. If there is no prefix it appends the entire
    //filename to targetDirectory.
    func handlLocalization(sourceFile: String, targetDirectory: URL) -> URL? {
        if sourceFile.starts(with: "EN_") {
            if isSpanish {
                return nil
            }
            else {
                return  targetDirectory.appendingPathComponent(sourceFile.deletingPrefix("EN_"))
            }
        }
        else if sourceFile.starts(with: "ES_") {
            if !isSpanish {
                return nil
            }
            else {
                return targetDirectory.appendingPathComponent(sourceFile.deletingPrefix("ES_"))
            }
        }
        else {
            return targetDirectory.appendingPathComponent(sourceFile)
        }
    }
    
    func copyDirectoryContents(_ sourceDirectory: URL, to targetDirectory: URL) throws {
        
        let fileManager = FileManager.default
        try fileManager.createDirectory(atPath: targetDirectory.path, withIntermediateDirectories: true)
        
        let sourceFiles = try fileManager.contentsOfDirectory(atPath: sourceDirectory.path)
        
        for sourceFile in sourceFiles {
            let sourceURL = sourceDirectory.appendingPathComponent(sourceFile)
            
            guard let targetURL = handlLocalization(sourceFile: sourceFile, targetDirectory: targetDirectory) else {
                continue
            }
            
            if isDirectory(at: sourceURL.path) {
                try copyDirectoryContents(sourceURL, to: targetURL)
            }
            else {
                try fileManager.copyItem(at: sourceURL, to: targetURL)
            }
        }
        
    }
    
    func copySampleTopics() {
        let testBundle = Bundle(for: type(of: self))
        guard let catalog = testBundle.url(forResource: "StarterBoards", withExtension: nil) else {
            XCTFail("The production StarterBoards catalog must be included in the UI test bundle")
            return
        }
        let localizedCatalog = catalog.appendingPathComponent(isSpanish ? "es" : "en")
        let destination = tempDir.appendingPathComponent("topics")
        do {
            // Use the same resources as the app, without mixing in legacy demo topics.
            let expected = try JSONDecoder().decode([String].self, from:
                Data(contentsOf: localizedCatalog.appendingPathComponent("order.json")))
            try FileManager.default.copyItem(at: localizedCatalog.appendingPathComponent("topics"),
                                             to: destination)
            let actual = try FileManager.default.contentsOfDirectory(atPath: destination.path)
            XCTAssertEqual(Set(actual), Set(expected), "Screenshots must contain only default topics")
        } catch {
            XCTFail("Unable to copy default topics: \(error.localizedDescription)")
        }
    }

    @MainActor func testPopulatedTopicScreen() throws {
        
        snapshotIfNeeded(screenshotName)
    }

    @MainActor func testTopicCardWidthStaysConstantAcrossRotation() {
        XCUIDevice.shared.orientation = .portrait
        defer { XCUIDevice.shared.orientation = requiredOrientation }
        navigateToTopicScreen()
        if XCUIDevice.isiPad {
            app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.menuButton)
            app.tapButton(id: AccessibilityIdentifiers.TopicSelectionView.maximizeButton)
        }

        let first = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: 0)]
        XCTAssertTrue(first.waitForExistence(timeout: 10))
        let portraitWidth = first.frame.width
        XCTAssertEqual(portraitWidth, 100, accuracy: 1)
        XCTAssertGreaterThan(first.frame.height, portraitWidth,
                             "A card needs room for a square image, title, and margins")

        // This test runs on iPhone 18 Pro and full-screen iPad Pro 13-inch.
        let expectedColumns = XCUIDevice.isiPad ? 8 : 3
        let lastInRow = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: expectedColumns - 1)]
        let nextRow = app.buttons[AccessibilityIdentifiers.TopicSelectionView.topicButton(for: expectedColumns)]
        XCTAssertEqual(first.frame.minY, lastInRow.frame.minY, accuracy: 1)
        XCTAssertGreaterThan(nextRow.frame.minY, first.frame.minY)
        let portrait = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        portrait.name = "Topics-portrait"
        portrait.lifetime = .keepAlways
        add(portrait)

        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertGreaterThan(app.frame.width, app.frame.height)
        XCTAssertEqual(first.frame.width, portraitWidth, accuracy: 1)
        XCTAssertEqual(first.frame.minY, nextRow.frame.minY, accuracy: 1,
                       "Landscape should fit more cards across without stretching them")
        let landscape = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        landscape.name = "Topics-landscape"
        landscape.lifetime = .keepAlways
        add(landscape)
    }

    /// Captures localized marketing screens using the production default boards.
    /// Run explicitly with -only-testing; no system Photos library is modified.
    @MainActor func testAppStoreMarketingScreens() throws {
        func capture(_ name: String) {
            Snapshot.snapshot(name)
            let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
            attachment.name = "AppStore-" + name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        let featuredBoard = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] %@", isSpanish ? "Necesito" : "I Need"
        )).firstMatch
        XCTAssertTrue(featuredBoard.waitForExistence(timeout: 20), app.debugDescription)
        let permission = XCUIApplication(bundleIdentifier: "com.apple.springboard").alerts.firstMatch
        if permission.exists {
            let deny = permission.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Don'")).firstMatch
            if deny.exists { deny.tap() }
        }
        if !XCUIDevice.isiPad { capture("01-boards") }
        featuredBoard.tap()
        let layout = app.buttons[AccessibilityIdentifiers.PhotoSelectionView.layoutButton]
        XCTAssertTrue(layout.waitForExistence(timeout: 10), app.debugDescription)
        if XCUIDevice.isiPad {
            capture("01-boards")
            tapSidebarButton()
        }
        capture("02-board")
        layout.tap()
        let close = app.buttons["BoardEditor.closeLayout"]
        XCTAssertTrue(close.waitForExistence(timeout: 10), app.debugDescription)
        capture("03-layout")
        close.tap()
        app.tapButton(id: AccessibilityIdentifiers.PhotoSelectionView.printButton)
        let preview = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH 'PreviewScreen.previewImage.'"
        )).firstMatch
        XCTAssertTrue(preview.waitForExistence(timeout: 20), app.debugDescription)
        capture("04-print")
    }

    
}
