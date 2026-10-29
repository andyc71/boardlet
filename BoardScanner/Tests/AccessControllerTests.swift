import Combine
import XCTest

@testable import BoardScanner

@MainActor
final class AccessControllerTests: XCTestCase {
    private let choices = [ScanItem(id: "a", label: "Yes"), ScanItem(id: "b", label: "No")]
    private func controller() -> AccessController {
        let value = AccessController(defaults: UserDefaults(suiteName: UUID().uuidString)!)
        value.settings.mode = .manual
        value.setItems(choices, context: "home")
        return value
    }

    func testExplicitStartWrapSelectAndSuspend() {
        let scan = controller()
        XCTAssertNil(scan.select())
        XCTAssertEqual(scan.focusedID, "a")
        scan.step(backward: true)
        XCTAssertEqual(scan.focusedID, "b")
        scan.step()
        XCTAssertEqual(scan.focusedID, "a")
        XCTAssertEqual(scan.select(), "a")
        XCTAssertFalse(scan.isScanning)
        XCTAssertNil(scan.focusedID)
        scan.suspend("sheet", while: true)
        scan.suspend("inactive", while: true)
        scan.suspend("sheet", while: false)
        scan.start()
        XCTAssertFalse(scan.isScanning)
        XCTAssertFalse(scan.acceptSelection("a"))
        scan.suspend("inactive", while: false)
        scan.start()
        XCTAssertTrue(scan.isScanning)
        scan.settings.mode = .direct
        scan.start()
        XCTAssertFalse(scan.isScanning)
    }

    func testContextChangesResetFocusAndRepeatGate() {
        let scan = controller()
        scan.settings.repeatDelay = 1
        XCTAssertTrue(scan.acceptSelection("a", now: 10))
        XCTAssertFalse(scan.acceptSelection("a", now: 10.5))
        XCTAssertTrue(scan.acceptSelection("a", now: 11))
        XCTAssertTrue(scan.acceptSelection("b", now: 11.1))
        scan.start()
        scan.setItems(choices, context: "other-page")
        XCTAssertFalse(scan.isScanning)
        XCTAssertTrue(scan.acceptSelection("b", now: 11.2))
        scan.resetForDocument()
        XCTAssertTrue(
            scan.acceptSelection("b", now: 11.3),
            "A new document must not inherit the previous document’s repeat gate")
        scan.start()
        scan.setItems([], context: "empty-page")
        scan.step()
        XCTAssertFalse(scan.isScanning)
    }

    func testSettingsPersistIndependentlyFromVoicePreferencesAndClamp() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let oldVoice = try JSONEncoder().encode(CommunicationSettings())
        defaults.set(oldVoice, forKey: "communication.settings.v1")
        let scan = AccessController(defaults: defaults)
        scan.settings = AccessSettings(
            mode: .automatic, scanInterval: 90, repeatDelay: -1, buttonScale: 9)
        let restored = AccessController(defaults: defaults)
        XCTAssertEqual(
            restored.settings,
            AccessSettings(mode: .automatic, scanInterval: 5, repeatDelay: 0, buttonScale: 2))
        XCTAssertEqual(defaults.data(forKey: "communication.settings.v1"), oldVoice)
        XCTAssertEqual(
            AccessSettings(scanInterval: .nan, repeatDelay: .infinity, buttonScale: .nan).validated,
            AccessSettings())
    }

    func testScanOrderExcludesHiddenEmptyAndMissingButtonsAndPreservesPlacementIdentity() {
        let a = SnapButton(
            id: "a", label: "Yes", message: "", destinationIDs: [], serializedCommands: "")
        let pageSet = SnapPageSet(
            title: "Test", schemaVersion: "4.20", homePageID: "home", pages: [], buttons: ["a": a],
            assets: [:])
        let layout = SnapLayout(
            id: 1, setting: "", columns: 3, rows: 2,
            placements: [
                SnapPlacement(
                    id: 4, elementID: "a", column: 0, row: 1, columnSpan: 1, rowSpan: 1,
                    visible: true),
                SnapPlacement(
                    id: 1, elementID: "a", column: 0, row: 0, columnSpan: 1, rowSpan: 1,
                    visible: true),
                SnapPlacement(
                    id: 2, elementID: "a", column: 1, row: 0, columnSpan: 1, rowSpan: 1,
                    visible: false),
                SnapPlacement(
                    id: 3, elementID: "missing", column: 2, row: 0, columnSpan: 1, rowSpan: 1,
                    visible: true),
            ])
        XCTAssertEqual(ScanItem.placements(in: layout, pageSet: pageSet).map(\.id), ["1", "4"])
        let cards = (0..<4).map { index in
            ScannedCard(
                row: index / 2, column: index % 2, label: String(index), confidence: 1,
                bounds: .zero,
                pictureBounds: .zero, imagePNG: Data(), needsReview: false, included: index != 1,
                isEmpty: index == 2)
        }
        let board = ScannedBoard(
            columns: 2, rows: 2, cards: cards.reversed(), sourcePNG: Data(), method: "test")
        XCTAssertEqual(ScanItem.cards(in: board).map(\.label), ["0", "3"])
    }

    func testAutomaticTimerAdvancesWithoutSelectingAndCannotReviveStoppedScan() async {
        let scan = controller()
        scan.settings.mode = .automatic
        scan.settings.scanInterval = 0.5
        scan.start()
        let advanced = expectation(description: "Timer advances")
        let observation = scan.$focusedID.dropFirst().first(where: { $0 == "b" }).sink { _ in
            advanced.fulfill()
        }
        let timer = Task { await scan.runAutomaticScan() }
        await fulfillment(of: [advanced], timeout: 3)
        XCTAssertTrue(scan.isScanning, "A timer must not select the highlighted item")
        scan.suspend("sheet", while: true)
        await timer.value
        XCTAssertNil(scan.focusedID)
        scan.suspend("sheet", while: false)
        XCTAssertFalse(scan.isScanning, "Dismissing a sheet must require an explicit restart")
        observation.cancel()
        scan.start()
        let cancelledTimer = Task { await scan.runAutomaticScan() }
        cancelledTimer.cancel()
        await cancelledTimer.value
        XCTAssertEqual(scan.focusedID, "a")
        scan.stop()
    }
}
