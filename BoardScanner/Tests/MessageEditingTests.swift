import XCTest
@testable import BoardScanner

@MainActor
final class MessageEditingTests: XCTestCase {
    func testCorrectionMovementAndRemovalPreservePicturesAndIdentity() {
        let speaker = EditingSpeaker()
        let session = CommunicationSession(speaker: speaker, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        session.settings.speakOnSelection = false
        let image = Data([1, 2, 3])
        session.append("I want", imagePNG: image)
        session.append("water")
        session.append("please")
        let id = session.tokens[0].id
        session.updateToken(id, text: "  I need  ")
        XCTAssertEqual(session.tokens[0].id, id)
        XCTAssertEqual(session.tokens[0].imagePNG, image)
        session.moveToken(session.tokens[2].id, earlier: true)
        XCTAssertEqual(session.message, "I need please water")
        session.moveTokens(from: IndexSet([0, 1]), to: 3)
        XCTAssertEqual(session.message, "water I need please")
        session.removeTokens(at: IndexSet(integer: 0))
        XCTAssertEqual(session.message, "I need please")
        XCTAssertEqual(session.tokens[0].imagePNG, image)
        session.updateToken(id, text: "  ")
        XCTAssertEqual(session.message, "I need please")
        XCTAssertTrue(speaker.messages.isEmpty, "Corrections must not speak automatically")
        session.speak()
        XCTAssertEqual(speaker.messages, ["I need please"])
    }

    func testClearAndReuseKeepPictureTokensWithFreshIDsAndSpeakOnce() {
        let speaker = EditingSpeaker()
        let session = CommunicationSession(speaker: speaker, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        session.append("Hello", imagePNG: Data([4]))
        session.append("!")
        let original = session.tokens
        session.clear()
        session.clear()
        XCTAssertEqual(session.lastMessageText, "Hello!")
        let count = speaker.messages.count
        session.reuseLastMessage()
        XCTAssertEqual(session.message, "Hello!")
        XCTAssertEqual(session.tokens.map(\.imagePNG), original.map(\.imagePNG))
        XCTAssertTrue(Set(session.tokens.map(\.id)).isDisjoint(with: original.map(\.id)))
        XCTAssertEqual(speaker.messages.count, count + 1)
        XCTAssertEqual(speaker.messages.last, "Hello!")
        session.reuseLastMessage()
        XCTAssertEqual(session.message, "Hello! Hello!")
        XCTAssertEqual(Set(session.tokens.map(\.id)).count, 4)
    }

    func testRejectedSpeechDoesNotReplaceRecallAndClearAfterSpeakCanBeReused() {
        let speaker = EditingSpeaker()
        let session = CommunicationSession(speaker: speaker, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        session.settings.speakOnSelection = false
        session.append("First")
        session.speak()
        session.clear()
        session.append("Second")
        speaker.accept = false
        session.speak()
        session.speakText("Rejected")
        XCTAssertEqual(session.lastMessageText, "First")
        XCTAssertEqual(session.message, "Second")
        speaker.accept = true
        session.settings.clearAfterSpeaking = true
        session.speak()
        XCTAssertTrue(session.tokens.isEmpty)
        session.reuseLastMessage()
        XCTAssertEqual(session.message, "Second")
        session.speakText("Immediate phrase")
        XCTAssertEqual(session.message, "Second", "Immediate phrases must leave the composer intact")
        XCTAssertEqual(session.lastMessageText, "Immediate phrase")
    }

    func testDocumentSwitchDropsConversationAndRecallButNotPreferences() {
        let speaker = EditingSpeaker()
        let session = CommunicationSession(speaker: speaker, defaults: UserDefaults(suiteName: UUID().uuidString)!)
        session.settings.speakOnSelection = false
        session.append("Private message")
        session.speak()
        session.showKeyboard = true
        session.resetConversation()
        session.reuseLastMessage()
        XCTAssertTrue(session.tokens.isEmpty)
        XCTAssertTrue(session.lastMessage.isEmpty)
        XCTAssertFalse(session.showKeyboard)
        XCTAssertFalse(session.settings.speakOnSelection)
    }
}

@MainActor
private final class EditingSpeaker: SpeechOutput {
    var messages: [String] = []
    var accept = true
    func speak(_ text: String, settings: CommunicationSettings) -> Bool {
        guard accept else { return false }
        messages.append(text)
        return true
    }
    func stop() { }
}
