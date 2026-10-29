import XCTest

// The VoiceOver test service ships with the iOS 27 SDK / Swift 6.4 toolchain.
// Keep the rest of the project buildable with its supported earlier toolchains.
#if compiler(>=6.4)
  final class VoiceOverUITests: XCTestCase {
    @MainActor
    func testVoiceOverReadsVocabularyComposedMessageAndEditor() throws {
      guard #available(iOS 27, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
      continueAfterFailure = false
      let app = makeBoard()
      let voiceOver = try enableVoiceOver()
      let utterances = try traverse(voiceOver, until: "Toilet", name: "Starter vocabulary")
      for label in [
        "Message Empty", "Edit message", "Speak message dimmed", "Stop speaking dimmed",
        "Undo last word dimmed", "Clear message dimmed", "Type", "Phrases", "Yes", "No", "I want",
        "More", "Help", "Stop Row", "Water", "Eat", "Toilet",
      ] {
        XCTAssertTrue(
          utterances.contains { $0.hasPrefix(label) },
          "VoiceOver must reach \(label): \(utterances)")
      }
      XCTAssertTrue(utterances.last?.contains("Add to message") == true)

      // Targeted XCTest double taps activate known controls while VoiceOver is enabled.
      // They do not establish location-independent activation of the traversed focus.
      app.buttons.matching(
        NSPredicate(format: "identifier BEGINSWITH 'snapButton_' AND label == 'Toilet'")
      ).firstMatch.doubleTap()
      XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Toilet")
      let message = try traverse(
        voiceOver, until: "Message Toilet", backwards: true, name: "Composed message")
      XCTAssertTrue(message.last?.hasPrefix("Message Toilet") == true)
      let speak = try traverse(voiceOver, until: "Speak message", name: "Speak composed message")
      XCTAssertFalse(speak.last?.contains("dimmed") == true)
      XCTAssertTrue(app.buttons["speakMessage"].isEnabled)

      app.buttons["editMessage"].doubleTap()
      let editor = try traverse(voiceOver, until: "Toilet", name: "Message editor")
      XCTAssertTrue(editor.last?.contains("Edit these words") == true)
      XCTAssertFalse(
        editor.contains { $0.hasPrefix("Yes Row") },
        "Modal traversal must not expose the board underneath")
      app.buttons["Done"].doubleTap()
      app.buttons["clearMessage"].doubleTap()
      XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Empty")
      app.buttons["editMessage"].doubleTap()
      _ = try traverse(voiceOver, until: "Add last message", name: "Recall cleared message")
      app.buttons["reuseLastMessage"].doubleTap()
      app.buttons["Done"].doubleTap()
      XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Toilet")
    }

    @MainActor
    func testVoiceOverReadsLinkedPagesAndPreservedMessage() throws {
      guard #available(iOS 27, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
      continueAfterFailure = false
      let url = try SnapTestFixture.make(
        extraSQL: """
          INSERT INTO Button VALUES(4,40,'Drink','I want water',0,0);
          INSERT INTO ElementPlacement VALUES(5,40,'1,0','1,1',1,3);
          """)
      addTeardownBlock { try? FileManager.default.removeItem(at: url) }
      let app = XCUIApplication()
      app.launchArguments = [
        "--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
        "--import-test-document", url.path,
      ]
      app.launch()
      normalizeOrientation()
      XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 20))
      let voiceOver = try enableVoiceOver()
      let link = try traverse(voiceOver, until: "Go to café", name: "Linked page button")
      XCTAssertTrue(link.last?.contains("Open linked page") == true)
      app.buttons["snapButton_1"].doubleTap()
      XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Child")
      assertFocus(voiceOver, prefix: "Child Heading")
      let drink = try traverse(voiceOver, until: "Drink", name: "Child page vocabulary")
      XCTAssertTrue(drink.last?.contains("Add to message") == true)
      app.buttons["snapButton_4"].doubleTap()
      XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "I want water")
      app.buttons["pageHome"].doubleTap()
      XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Home")
      _ = try traverse(
        voiceOver, until: "Message I want water", backwards: true,
        name: "Message after returning home")
      app.buttons["allPages"].doubleTap()
      app.buttons["snapPage_child"].doubleTap()
      assertFocus(voiceOver, prefix: "Child Heading")
      XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "I want water")
    }

    @MainActor
    func testVoiceOverFocusesNewPageAtMaximumTextInLandscapeScanning() throws {
      guard #available(iOS 27, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
      continueAfterFailure = false
      let url = try SnapTestFixture.make()
      addTeardownBlock { try? FileManager.default.removeItem(at: url) }
      let app = XCUIApplication()
      app.launchArguments = [
        "--ui-testing", "--fresh-start", "--library-id", UUID().uuidString,
        "--import-test-document", url.path,
        "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
      ]
      app.launch()
      normalizeOrientation()
      XCTAssertTrue(app.buttons["snapButton_1"].waitForExistence(timeout: 20))
      app.tapBoardControl("communicationSettings")
      let method = app.buttons["selectionMethod"]
      for _ in 0..<8 where !method.isHittable { app.swipeUp() }
      method.tap()
      app.buttons["Step scanning"].tap()
      app.buttons["Done"].tap()
      let voiceOver = try enableVoiceOver()
      XCUIDevice.shared.orientation = .landscapeLeft
      _ = try traverse(voiceOver, until: "Start scan", name: "Maximum text scan control")
      let select = app.buttons["scanSelect"]
      app.typeKey(.space, modifierFlags: [])
      let scanStarted = XCTNSPredicateExpectation(
        predicate: NSPredicate(format: "label BEGINSWITH %@", "Select: Go to café"),
        object: select)
      XCTAssertEqual(XCTWaiter.wait(for: [scanStarted], timeout: 5), .completed, select.label)
      app.typeKey(.space, modifierFlags: [])
      let compactHeader = !app.staticTexts["snapPageTitle"].exists
      if compactHeader {
        XCTAssertEqual(app.buttons["scanSelect"].value as? String, "Child")
      } else {
        XCTAssertEqual(app.staticTexts["snapPageTitle"].label, "Child")
      }
      assertFocus(voiceOver, prefix: compactHeader ? "Pages Child" : "Child Heading")
      _ = try traverse(voiceOver, until: "Return", name: "Maximum text child page")
      XCTAssertEqual(app.buttons["scanSelect"].label, "Start scan")
      XCTAssertEqual(app.otherElements["communicationMessage"].value as? String, "Empty")
    }

    @available(iOS 27, *)
    @MainActor private func assertFocus(_ service: XCUIVoiceOverService, prefix: String) {
      let focus = XCTNSPredicateExpectation(
        predicate: NSPredicate { _, _ in
          (try? service.currentSpeech().utterance.hasPrefix(prefix)) == true
        }, object: nil)
      let result = XCTWaiter.wait(for: [focus], timeout: 5)
      let utterance = (try? service.currentSpeech().utterance) ?? "No speech"
      let transcript = XCTAttachment(string: utterance)
      transcript.name = "Page context focus"
      transcript.lifetime = .keepAlways
      add(transcript)
      XCTAssertEqual(
        result, .completed,
        "VoiceOver must move to \(prefix); current speech: \(utterance)")
    }

    @available(iOS 27, *)
    @MainActor private func enableVoiceOver() throws -> XCUIVoiceOverService {
      let service = XCUIDevice.shared.voiceOverService
      let originallyEnabled = service.isEnabled
      // XCTest teardown runs even when continueAfterFailure aborts a test.
      addTeardownBlock { @MainActor in
        if !originallyEnabled {
          try service.disable()
          XCTAssertFalse(service.isEnabled)
        }
      }
      if !originallyEnabled { try service.enable() }
      XCTAssertTrue(service.isEnabled)
      return service
    }

    @available(iOS 27, *)
    @MainActor private func traverse(
      _ service: XCUIVoiceOverService, until prefix: String, backwards: Bool = false, name: String
    ) throws -> [String] {
      var utterances = [try service.currentSpeech().utterance]
      var movingBackwards = backwards
      var reversedAtBoundary = false
      for _ in 0..<40 where utterances.last?.hasPrefix(prefix) != true {
        let next = try (movingBackwards ? service.moveBackward() : service.moveForward()).utterance
        // VoiceOver does not wrap at the screen boundary. A transition can leave
        // focus near the bottom, so search in the other direction once.
        if next == utterances.last {
          if reversedAtBoundary { break }
          movingBackwards.toggle()
          reversedAtBoundary = true
        }
        utterances.append(next)
      }
      let transcript = XCTAttachment(string: utterances.joined(separator: "\n"))
      transcript.name = name
      transcript.lifetime = .keepAlways
      add(transcript)
      XCTAssertTrue(
        utterances.last?.hasPrefix(prefix) == true,
        "VoiceOver did not reach \(prefix): \(utterances)")
      return utterances
    }

    @MainActor private func normalizeOrientation() {
      XCUIDevice.shared.orientation = .landscapeLeft
      XCUIDevice.shared.orientation = .portrait
    }

    @MainActor private func makeBoard() -> XCUIApplication {
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString]
      app.launch()
      normalizeOrientation()
      app.buttons["createMenu"].tap()
      app.buttons["New board"].tap()
      app.textFields["newBoardName"].tap()
      app.textFields["newBoardName"].typeText("VoiceOver board")
      let hide = app.buttons["Hide keyboard"]
      if hide.waitForExistence(timeout: 2), hide.isHittable { hide.tap() }
      app.buttons["createNativeBoard"].tap()
      XCTAssertTrue(app.staticTexts["Board created · Saved"].waitForExistence(timeout: 10))
      app.tapBoardControl("toggleEditing")
      return app
    }
  }
#endif
