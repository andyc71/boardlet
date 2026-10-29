import UIKit
import XCTest

// Opt-in through BoardScannerVoiceOverInput. These probes distinguish automation
// input behavior from board layout; their failures are retained in ACTIVATION.md.
#if compiler(>=6.4)
  @MainActor
  final class VoiceOverInputDiagnostics: XCTestCase {
    func testSystemSettingsPortraitActivation() throws {
      try checkSystemSettingsActivation(landscape: false)
    }

    func testSystemSettingsLandscapeActivation() throws {
      try checkSystemSettingsActivation(landscape: true)
    }

    private func checkSystemSettingsActivation(landscape: Bool) throws {
      guard #available(iOS 27, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
      continueAfterFailure = false
      let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
      settings.launch()
      XCUIDevice.shared.orientation = .landscapeLeft
      XCUIDevice.shared.orientation = .portrait
      addTeardownBlock { @MainActor in
        XCUIDevice.shared.orientation = .portrait
        settings.terminate()
      }
      if landscape { XCUIDevice.shared.orientation = .landscapeLeft }
      let settledOrientation = XCTNSPredicateExpectation(
        predicate: NSPredicate { _, _ in
          landscape
            ? settings.frame.width > settings.frame.height
            : settings.frame.height > settings.frame.width
        }, object: nil)
      guard XCTWaiter.wait(for: [settledOrientation], timeout: 5) == .completed else {
        throw XCTSkip(
          "Settings does not present the requested interface orientation on this device")
      }
      let target = settings.descendants(matching: .any).matching(
        NSPredicate(format: "label == 'Accessibility'")
      ).firstMatch
      for _ in 0..<4 {
        if target.exists && target.isHittable { break }
        settings.swipeUp()
      }
      capture(settings.debugDescription, named: "System Settings before activation")
      XCTAssertTrue(target.exists)
      let destination = settings.descendants(matching: .any).matching(
        NSPredicate(format: "label BEGINSWITH 'VoiceOver'")
      ).firstMatch
      XCTAssertFalse(destination.exists, "Control destination must not already be open")
      let service = XCUIDevice.shared.voiceOverService
      let originallyEnabled = service.isEnabled
      addTeardownBlock { @MainActor in
        if !originallyEnabled {
          try service.disable()
          XCTAssertFalse(service.isEnabled)
        }
      }
      if !originallyEnabled { try service.enable() }
      var speech = [try service.currentSpeech().utterance]
      for _ in 0..<40 where speech.last?.hasPrefix("Accessibility") != true {
        speech.append(try service.moveForward().utterance)
      }
      capture(speech.joined(separator: "\n"), named: "System Settings VoiceOver focus")
      XCTAssertTrue(speech.last?.hasPrefix("Accessibility") == true)
      target.doubleTap()
      let opened = destination.waitForExistence(timeout: 5)
      capture(settings.debugDescription, named: "System Settings after activation")
      XCTAssertTrue(opened, "The Accessibility page must expose VoiceOver after activation")
    }

    func testLandscapeDefaultTextDoubleTap() throws {
      try checkToolbarActivation(landscape: true, maximumText: false)
    }

    func testPortraitDefaultTextDoubleTap() throws {
      try checkToolbarActivation(landscape: false, maximumText: false)
    }

    func testLandscapeDefaultTextVoiceOverKeyboardActivation() throws {
      try checkToolbarActivation(landscape: true, maximumText: false, keyboard: true)
    }

    func testPortraitDefaultTextVoiceOverKeyboardActivation() throws {
      try checkToolbarActivation(landscape: false, maximumText: false, keyboard: true)
    }

    func testLandscapeMaximumTextDoubleTap() throws {
      try checkToolbarActivation(landscape: true, maximumText: true)
    }

    func testPortraitMaximumTextDoubleTap() throws {
      try checkToolbarActivation(landscape: false, maximumText: true)
    }

    func testLandscapeDefaultTextSingleTap() throws {
      try checkToolbarActivation(landscape: true, maximumText: false, singleTap: true)
    }

    func testLandscapeMaximumTextScreenCenterDoubleTap() throws {
      try checkToolbarActivation(landscape: true, maximumText: true, screenCenter: true)
    }

    func testPortraitMaximumTextScreenCenterDoubleTap() throws {
      try checkToolbarActivation(landscape: false, maximumText: true, screenCenter: true)
    }

    private func checkToolbarActivation(
      landscape: Bool, maximumText: Bool, singleTap: Bool = false, screenCenter: Bool = false,
      keyboard: Bool = false
    )
      throws
    {
      guard #available(iOS 27, *) else { throw XCTSkip("VoiceOver service requires iOS 27") }
      continueAfterFailure = false
      let app = XCUIApplication()
      app.launchArguments = ["--ui-testing", "--fresh-start", "--library-id", UUID().uuidString]
      if maximumText {
        app.launchArguments += [
          "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
        ]
      }
      app.launch()
      XCUIDevice.shared.orientation = .landscapeLeft
      XCUIDevice.shared.orientation = .portrait
      addTeardownBlock { @MainActor in XCUIDevice.shared.orientation = .portrait }
      // An application's frame can differ from its active window on a
      // multi-display simulator. Establish the requested window shape directly.
      let window = app.windows.firstMatch
      let orientations: [UIDeviceOrientation] =
        landscape ? [.landscapeLeft, .portrait] : [.portrait, .landscapeLeft]
      var settled = false
      for orientation in orientations {
        XCUIDevice.shared.orientation = orientation
        let settledOrientation = XCTNSPredicateExpectation(
          predicate: NSPredicate { _, _ in
            guard window.exists else { return false }
            let frame = window.frame
            return landscape ? frame.width > frame.height : frame.height > frame.width
          }, object: nil)
        if XCTWaiter.wait(for: [settledOrientation], timeout: 5) == .completed {
          settled = true
          break
        }
      }
      capture(
        "Requested wide window: \(landscape), device orientation: \(XCUIDevice.shared.orientation.rawValue), "
          + "App: \(app.frame), window: \(window.frame)",
        named: "Window orientation prerequisite")
      XCTAssertTrue(
        settled,
        "The toolbar probe must run in the requested interface orientation")
      let service = XCUIDevice.shared.voiceOverService
      let originallyEnabled = service.isEnabled
      addTeardownBlock { @MainActor in
        if !originallyEnabled {
          try service.disable()
          XCTAssertFalse(service.isEnabled)
        }
      }
      if !originallyEnabled { try service.enable() }
      var speech = [try service.currentSpeech().utterance]
      for _ in 0..<30 where speech.last != "Create Button" {
        speech.append(try service.moveForward().utterance)
      }
      capture(speech.joined(separator: "\n"), named: "Create toolbar focus")
      XCTAssertEqual(speech.last, "Create Button", "Focus must reach the toolbar, not Create a board")
      let create = app.buttons["createMenu"]
      capture(
        "App: \(app.frame), window: \(window.frame), Create: \(create.frame), hittable: \(create.isHittable)",
        named: "Activation geometry")
      if keyboard {
        app.typeKey(" ", modifierFlags: [.control, .option])
      } else if screenCenter {
        // VoiceOver activation should be independent of the focused control's
        // hit point. Compare a raw in-window event with element-targeted input.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).doubleTap()
      } else if singleTap {
        create.tap()
      } else {
        create.doubleTap()
      }
      let opened = app.buttons["New board"].waitForExistence(timeout: 5)
      capture(
        (try? service.currentSpeech().utterance) ?? "No speech", named: "After toolbar activation")
      XCTAssertTrue(opened, "XCTest input must activate the standard Create toolbar button")
    }

    private func capture(_ text: String, named name: String) {
      let attachment = XCTAttachment(string: text)
      attachment.name = name
      attachment.lifetime = .keepAlways
      add(attachment)
    }
  }
#endif
