import XCTest
@testable import BoardScanner

final class SnapCommunicationBehaviorTests: XCTestCase {
    func testHomeAndKeyboardCommandsTakePrecedenceOverRetainedPageReferences() async throws {
        let url = try SnapTestFixture.make(extraSQL: SnapTestFixture.roleCommandsSQL)
        defer { try? FileManager.default.removeItem(at: url) }
        let imported = try await TDSnapImporter.load(url)
        let restored = try BoardStorage.decodePageSet(BoardDocument(pageSet: imported).encoded())
        for set in [imported, restored] {
            let home = try XCTUnwrap(set.buttons["40"])
            let keyboard = try XCTUnwrap(set.buttons["50"])
            XCTAssertEqual(SnapCommunicationBehavior.resolve(home), .action(.home))
            XCTAssertEqual(SnapCommunicationBehavior.resolve(keyboard), .action(.keyboard))
            XCTAssertEqual(home.destinationIDs, ["old-home"])
            XCTAssertEqual(keyboard.destinationIDs, ["old-keyboard"])
            XCTAssertEqual(home.serializedCommands, imported.buttons["40"]?.serializedCommands)
            XCTAssertEqual(keyboard.serializedCommands, imported.buttons["50"]?.serializedCommands)
            XCTAssertEqual(set.missingLinkCount, 3)
            XCTAssertEqual(set.unavailableNavigationLinkCount, 1, "The genuinely missing Return destination must still be reported")
        }
        var edited = restored
        edited.buttons["40"]?.communicationAction = .openPage
        XCTAssertEqual(SnapCommunicationBehavior.resolve(try XCTUnwrap(edited.buttons["40"])), .destinations)
        XCTAssertEqual(edited.unavailableNavigationLinkCount, 2)
    }

    func testRoleCommandPrecedenceDoesNotGuessFromLabelsOrExecuteCompoundCommands() {
        var button = makeButton(#"{"$values":[{"$type":"5"},{"$type":"2","LinkedPageId":"missing"}]}"#)
        button.label = "Home"
        button.destinationIDs = ["missing"]
        XCTAssertEqual(SnapCommunicationBehavior.resolve(button), .destinations)
        button.serializedCommands = ""
        XCTAssertEqual(SnapCommunicationBehavior.resolve(button), .destinations)
        button.serializedCommands = #"{"$values":[{"$type":"3","MessageAction":0}]}"#
        XCTAssertEqual(SnapCommunicationBehavior.resolve(button), .destinations)
        button.serializedCommands = #"{"$values":[{"$type":"5"}]}"#
        button.communicationAction = CommunicationAction.none
        XCTAssertEqual(SnapCommunicationBehavior.resolve(button), .action(.none))
    }

    func testKnownSingleCommandsAndUnknownSequences() {
        let mappings: [String: CommunicationAction] = ["4": .back, "5": .home, "8": .speakMessage,
            "9": .clearMessage, "10": .undo, "17": .keyboard, "75": .stop]
        for (type, action) in mappings {
            let button = makeButton(#"{"$values":[{"$type":""# + type + #""}]}"#)
            XCTAssertEqual(SnapCommunicationBehavior.resolve(button), .action(action))
        }
        XCTAssertEqual(SnapCommunicationBehavior.resolve(makeButton(#"{"$values":[{"$type":"3","MessageAction":0}]}"#)), .action(.addMessage))
        XCTAssertEqual(SnapCommunicationBehavior.resolve(makeButton(#"{"$values":[{"$type":"3","MessageAction":1}]}"#)), .action(.speakImmediately))
        for raw in ["not json", #"{"$values":[{"$type":"54"}]}"#,
                    #"{"$values":[{"$type":"8"},{"$type":"9"}]}"#] {
            XCTAssertEqual(SnapCommunicationBehavior.resolve(makeButton(raw)), .unsupported)
        }
    }

    func testExplicitActionOverridesImportedNavigationWithoutDestroyingIt() throws {
        var button = makeButton(#"{"$values":[{"$type":"2","LinkedPageId":"child"}]}"#)
        button.destinationIDs = ["child"]
        XCTAssertEqual(SnapCommunicationBehavior.resolve(button), .destinations)
        button.communicationAction = .speakImmediately
        let restored = try JSONDecoder().decode(SnapButton.self, from: JSONEncoder().encode(button))
        XCTAssertEqual(SnapCommunicationBehavior.resolve(restored), .action(.speakImmediately))
        XCTAssertEqual(restored.serializedCommands, button.serializedCommands)
        XCTAssertEqual(restored.destinationIDs, ["child"])
        button.communicationAction = nil
        XCTAssertEqual(SnapCommunicationBehavior.resolve(button), .destinations)
    }

    func testEditsSurviveCompletePageSetRoundTrip() async throws {
        let url = try SnapTestFixture.make()
        defer { try? FileManager.default.removeItem(at: url) }
        var pageSet = try await TDSnapImporter.load(url)
        pageSet.buttons["10"]?.label = "My drink"
        pageSet.buttons["10"]?.message = "Please bring water"
        pageSet.buttons["10"]?.communicationAction = .speakImmediately
        let document = BoardDocument(pageSet: pageSet)
        let restored = try BoardStorage.decodePageSet(document.encoded())
        XCTAssertEqual(restored.buttons["10"]?.message, "Please bring water")
        XCTAssertEqual(restored.buttons["10"]?.communicationAction, .speakImmediately)
        XCTAssertEqual(restored.buttons["10"]?.destinationIDs, ["child"])
    }

    private func makeButton(_ commands: String) -> SnapButton {
        SnapButton(id: "1", label: "Label", message: "Message", destinationIDs: [], serializedCommands: commands)
    }
}
