import AVFoundation
import XCTest
@testable import BoardScanner

@MainActor
final class CommunicationSessionTests: XCTestCase {
    func testIsolatedEnglishPronounHasPronunciationHintWithoutChangingText() {
        let key = NSAttributedString.Key(AVSpeechSynthesisIPANotationAttribute)
        for language in ["en-US", "en-GB", "en_AU"] {
            let text = " \nI "
            let utterance = AVSpeechUtterance(attributedString: SpeechController.speechText(text, language: language))
            XCTAssertEqual(utterance.speechString, text)
            XCTAssertEqual(utterance.attributedSpeechString.attribute(key, at: 2, effectiveRange: nil) as? String, "aɪ")
            XCTAssertNil(utterance.attributedSpeechString.attribute(key, at: 0, effectiveRange: nil))
        }
        for (text, language) in [("I want water", "en-US"), ("capital I", "en-US"),
                                 ("III", "en-GB"), ("iPad", "en-US"), ("I", "es-ES")] {
            let speech = SpeechController.speechText(text, language: language)
            XCTAssertEqual(speech.string, text)
            speech.enumerateAttribute(key, in: NSRange(location: 0, length: speech.length)) { value, _, _ in
                XCTAssertNil(value, "Unexpected pronunciation override for \(text) in \(language)")
            }
        }
    }

    func testPronounSelectionPreservesSentenceText() {
        let (session, speaker, _) = makeSession()
        session.append("I")
        XCTAssertEqual(speaker.messages.last, "I")
        session.append("want")
        session.append("water")
        session.speak()
        XCTAssertEqual(session.message, "I want water")
        XCTAssertEqual(speaker.messages.last, "I want water")
    }

    private func makeSession() -> (CommunicationSession, RecordingSpeaker, UserDefaults) {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let speaker = RecordingSpeaker()
        return (CommunicationSession(speaker: speaker, defaults: defaults), speaker, defaults)
    }

    func testMessageOrderPunctuationUndoClearAndSpeech() {
        let (session, speaker, _) = makeSession()
        session.append(" I want ")
        session.append("water")
        session.append("!")
        session.append(" \n ")
        XCTAssertEqual(session.message, "I want water!")
        XCTAssertEqual(speaker.messages, ["I want", "water", "!"])
        session.speak()
        XCTAssertEqual(speaker.messages.last, "I want water!")
        session.undo()
        XCTAssertEqual(session.message, "I want water")
        session.clear()
        XCTAssertEqual(session.message, "")
        XCTAssertEqual(speaker.stops, 2)
        let previous = speaker.messages
        session.speak()
        session.undo()
        XCTAssertEqual(speaker.messages, previous)
    }

    func testCompositionOnlyAndClearOnlyWhenSpeechAccepted() {
        let (session, speaker, _) = makeSession()
        session.settings.speakOnSelection = false
        session.settings.clearAfterSpeaking = true
        session.append("Please help")
        XCTAssertTrue(speaker.messages.isEmpty)
        speaker.accept = false
        session.speak()
        XCTAssertEqual(session.message, "Please help")
        speaker.accept = true
        session.speak()
        XCTAssertTrue(session.tokens.isEmpty)
        XCTAssertEqual(speaker.messages.last, "Please help")
    }

    func testSettingsSurviveRelaunchAndAreBounded() {
        let (session, speaker, defaults) = makeSession()
        session.settings.voiceIdentifier = "a voice"
        session.settings.rate = 99
        session.settings.speakOnSelection = false
        let restored = CommunicationSession(speaker: speaker, defaults: defaults)
        XCTAssertEqual(restored.settings.voiceIdentifier, "a voice")
        XCTAssertEqual(restored.settings.rate, 0.65)
        XCTAssertFalse(restored.settings.speakOnSelection)
    }

    func testSnapMessagesUseMessageFallbackAndDoNotSpeakFolderNames() {
        let (session, _, _) = makeSession()
        let pageSet = SnapPageSet(title: "Test", schemaVersion: "4.20", homePageID: "home", pages: [], buttons: [:], assets: [:])
        var button = SnapButton(id: "1", label: "Water", message: "I would like water", destinationIDs: [], serializedCommands: "")
        session.select(button, in: pageSet)
        XCTAssertEqual(session.message, "I would like water")
        button.message = " \n"
        session.select(button, in: pageSet)
        XCTAssertEqual(session.message, "I would like water Water")
        button.destinationIDs = ["home"]
        session.select(button, in: pageSet)
        XCTAssertEqual(session.tokens.count, 2)
    }

    func testImmediateSpeechAndActionButtonsKeepTheirMeaning() {
        let (session, speaker, _) = makeSession()
        let pageSet = SnapPageSet(title: "Test", schemaVersion: "4.20", homePageID: "home", pages: [], buttons: [:], assets: [:])
        session.append("My sentence")
        var button = SnapButton(id: "1", label: "Wait", message: "Give me time", destinationIDs: [],
                                communicationAction: .speakImmediately, serializedCommands: "")
        session.select(button, in: pageSet)
        XCTAssertEqual(speaker.messages.last, "Give me time")
        XCTAssertEqual(session.message, "My sentence")
        button.communicationAction = .speakMessage
        session.select(button, in: pageSet)
        XCTAssertEqual(speaker.messages.last, "My sentence")
        button.communicationAction = .clearMessage
        session.select(button, in: pageSet)
        XCTAssertTrue(session.tokens.isEmpty)
        button.communicationAction = .keyboard
        session.select(button, in: pageSet)
        XCTAssertTrue(session.showKeyboard)
    }

    func testHiddenAndEmptyCardsNeverCommunicate() {
        let (session, _, _) = makeSession()
        var card = ScannedCard(row: 0, column: 0, label: "Water", confidence: 1,
                               bounds: .zero, pictureBounds: .zero, imagePNG: Data(), needsReview: false)
        card.included = false
        session.select(card)
        card.included = true
        card.isEmpty = true
        session.select(card)
        XCTAssertTrue(session.tokens.isEmpty)
        card.isEmpty = false
        session.select(card)
        XCTAssertEqual(session.message, "Water")
        card.message = "I want water"
        session.select(card)
        XCTAssertEqual(session.message, "Water I want water")
    }
}

@MainActor
private final class RecordingSpeaker: SpeechOutput {
    var messages: [String] = []
    var stops = 0
    var accept = true
    func speak(_ text: String, settings: CommunicationSettings) -> Bool {
        guard accept else { return false }
        messages.append(text)
        return true
    }
    func stop() { stops += 1 }
}
