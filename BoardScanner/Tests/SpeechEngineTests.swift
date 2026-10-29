import Combine
import XCTest
@testable import BoardScanner

/// Opt-in integration checks: these use installed voices and the real system engine.
@MainActor
final class SpeechEngineTests: XCTestCase {
    func testNaturalCompletionAndSubsequentSpeech() async throws {
        let speaker = SpeechController()
        defer { speaker.stop() }
        let settings = try settings(for: speaker)

        await speakToCompletion("I", using: speaker, settings: settings)
        await speakToCompletion("I want water.", using: speaker, settings: settings)
        await speakToCompletion("Please help me.", using: speaker, settings: settings)
    }

    func testStopThenSpeakAgainWithUnavailableSavedVoice() async throws {
        let speaker = SpeechController()
        defer { speaker.stop() }
        var settings = try settings(for: speaker)
        settings.voiceIdentifier = "BoardScanner.nonexistent.saved.voice"

        XCTAssertTrue(speaker.speak(String(repeating: "Please wait. ", count: 100), settings: settings))
        XCTAssertTrue(speaker.isSpeaking)
        speaker.stop()
        XCTAssertFalse(speaker.isSpeaking)
        await speakToCompletion("I want water.", using: speaker, settings: settings)
    }

    func testRapidReplacementStillCompletesAndCanSpeakAgain() async throws {
        let speaker = SpeechController()
        defer { speaker.stop() }
        let settings = try settings(for: speaker)

        for _ in 0..<20 {
            XCTAssertTrue(speaker.speak("Please give me time to finish my message.", settings: settings))
        }
        await speakToCompletion("Thank you.", using: speaker, settings: settings)
        await speakToCompletion("I want water.", using: speaker, settings: settings)
    }

    private func settings(for speaker: SpeechController) throws -> CommunicationSettings {
        let voices = speaker.voices
        let voice = try XCTUnwrap(voices.first { $0.language == "en-US" } ?? voices.first,
                                 "This integration scheme requires an installed system voice.")
        var settings = CommunicationSettings()
        settings.voiceIdentifier = voice.identifier
        return settings
    }

    private func speakToCompletion(_ text: String, using speaker: SpeechController,
                                   settings: CommunicationSettings) async {
        guard speaker.speak(text, settings: settings) else {
            XCTFail(speaker.error ?? "Speech request was rejected.")
            return
        }
        XCTAssertTrue(speaker.isSpeaking)
        // Subscribe after submission: speak() first clears the previous request.
        // Only a subsequent engine callback can end this request without stop().
        let completed = expectation(description: "System engine ends: \(text)")
        let observation = speaker.$isSpeaking.dropFirst().filter { !$0 }.prefix(1).sink { _ in
            completed.fulfill()
        }
        await fulfillment(of: [completed], timeout: 30)
        observation.cancel()
        XCTAssertFalse(speaker.isSpeaking)
        XCTAssertNil(speaker.error)
    }
}
