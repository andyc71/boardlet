import XCTest
@testable import BoardScanner

@MainActor
final class AuthoringTests: XCTestCase {
    func testStarterSymbolsAndPortableDocumentRoundTrip() throws {
        let set = try NativeBoardFactory.make(title: "  Daily talk  ", rows: 3, columns: 3, starter: true)
        XCTAssertEqual(set.title, "Daily talk")
        XCTAssertEqual(set.buttons.count, 9)
        XCTAssertEqual(set.renderedAssetCount, 9)
        try set.validate()
        for symbol in BuiltinSymbol.choices { XCTAssertFalse(try ButtonArtwork.symbol(symbol).isEmpty, symbol.name) }
        let restored = try BoardStorage.decodePageSet(BoardDocument(pageSet: set).encoded())
        XCTAssertEqual(restored.buttons.count, 9)
        XCTAssertEqual(restored.assets.mapValues(\.data), set.assets.mapValues(\.data))
    }

    func testPositionsProtectHiddenAndMergedCellsAndFailuresAreTransactional() throws {
        var set = try PageSetAuthoring.emptyBoard(title: "Grid", rows: 3, columns: 3)
        var draft = try PageSetAuthoring.draft(in: set, pageID: set.homePageID, layoutID: 1, row: 0, column: 0)
        draft.placement.columnSpan = 2
        draft.placement.visible = false
        try save(draft, in: &set)
        XCTAssertEqual(PageSetAuthoring.freeCells(in: set.pages[0].layouts[0]), [2, 3, 4, 5, 6, 7, 8])
        XCTAssertThrowsError(try PageSetAuthoring.draft(in: set, pageID: set.homePageID, layoutID: 1, row: 0, column: 1))
        let adjacent = try PageSetAuthoring.draft(in: set, pageID: set.homePageID, layoutID: 1, row: 0, column: 2)
        try save(adjacent, in: &set)
        let before = try encoded(set)
        draft.placement.column = 1
        XCTAssertThrowsError(try save(draft, in: &set))
        XCTAssertEqual(try encoded(set), before)
        draft.placement.column = Int.max
        XCTAssertThrowsError(try save(draft, in: &set))
        XCTAssertEqual(try encoded(set), before)
    }

    func testSharedButtonAndArtworkReferencesSurviveLayoutRemoval() throws {
        var set = try NativeBoardFactory.make(title: "Shared", rows: 1, columns: 1, starter: true)
        let originalPage = set.pages[0], originalPlacement = originalPage.layouts[0].placements[0]
        let key = originalPlacement.elementID
        let oldAsset = try XCTUnwrap(set.buttons[key]?.assetKey)
        var other = try XCTUnwrap(set.buttons[key])
        other.id = "imported-other"
        set.buttons["imported-other"] = other
        try PageSetAuthoring.apply(.addPage(title: "Second", rows: 2, columns: 2), to: &set)
        set.pages[1].layouts[0].placements = [originalPlacement]
        var draft = ButtonEditDraft(button: try XCTUnwrap(set.buttons[key]), placement: originalPlacement,
                                    pageID: originalPage.id, layoutID: 1)
        draft.button.message = "Edited everywhere"
        let replacement = try ButtonArtwork.symbol(BuiltinSymbol.choices[1])
        try save(draft, artwork: .replace(replacement), in: &set)
        XCTAssertNotEqual(set.buttons[key]?.assetKey, oldAsset)
        XCTAssertNotNil(set.assets[oldAsset])
        XCTAssertEqual(set.buttons["imported-other"]?.assetKey, oldAsset)
        try PageSetAuthoring.apply(.removeButton(pageID: originalPage.id, layoutID: 1, placementID: originalPlacement.id), to: &set)
        XCTAssertEqual(set.buttons[key]?.message, "Edited everywhere")
        XCTAssertEqual(set.pages[1].layouts[0].placements.first?.elementID, key)
    }

    func testPageLinksHomeAndDeletion() throws {
        var set = try PageSetAuthoring.emptyBoard(title: "Home", rows: 2, columns: 2)
        let home = set.homePageID
        try PageSetAuthoring.apply(.addPage(title: "Drinks", rows: 2, columns: 2), to: &set)
        let drinks = set.pages[1]
        var draft = try PageSetAuthoring.draft(in: set, pageID: home, layoutID: 1, row: 0, column: 0)
        draft.button.label = "Drinks"
        draft.button.communicationAction = .openPage
        draft.button.destinationIDs = [drinks.id]
        try save(draft, in: &set)
        XCTAssertEqual(SnapCommunicationBehavior.resolve(draft.button), .destinations)
        XCTAssertThrowsError(try PageSetAuthoring.apply(.deletePage(id: home), to: &set))
        var explicitWord = draft.button
        explicitWord.id = "word-with-retained-source-link"
        explicitWord.communicationAction = .addMessage
        set.buttons[explicitWord.id] = explicitWord
        try PageSetAuthoring.apply(.deletePage(id: drinks.id), to: &set)
        XCTAssertEqual(set.buttons[explicitWord.id]?.communicationAction, .addMessage)
        XCTAssertEqual(set.buttons[draft.placement.elementID]?.communicationAction, CommunicationAction.none)
        XCTAssertEqual(set.buttons[draft.placement.elementID]?.destinationIDs, [])
        XCTAssertThrowsError(try save(draft, in: &set))
        try PageSetAuthoring.apply(.addPage(title: "New home", rows: 1, columns: 1), to: &set)
        let newHome = set.pages[1]
        try PageSetAuthoring.apply(.updatePage(id: newHome.id, layoutID: newHome.layouts[0].id,
                                              title: "Start", rows: 2, columns: 3, home: true), to: &set)
        XCTAssertEqual(set.homePageID, newHome.id)
        try PageSetAuthoring.apply(.deletePage(id: home), to: &set)
        XCTAssertEqual(set.pages.count, 1)
        XCTAssertThrowsError(try PageSetAuthoring.apply(.deletePage(id: newHome.id), to: &set))
    }

    func testImportedOverlapCanBeEditedWithoutMovingAndLayoutlessPageCanBeRepaired() throws {
        var set = try NativeBoardFactory.make(title: "Imported", rows: 1, columns: 1, starter: true)
        let first = set.pages[0].layouts[0].placements[0]
        var overlapping = first
        overlapping.id += 1
        set.pages[0].layouts[0].placements.append(overlapping)
        var draft = ButtonEditDraft(button: try XCTUnwrap(set.buttons[first.elementID]), placement: first,
                                    pageID: set.homePageID, layoutID: 1)
        draft.button.label = "Changed"
        try save(draft, in: &set)
        XCTAssertEqual(set.buttons[first.elementID]?.label, "Changed")
        set.pages[0].layouts = []
        try PageSetAuthoring.apply(.updatePage(id: set.homePageID, layoutID: -1, title: "Repaired", rows: 2, columns: 2, home: false), to: &set)
        XCTAssertEqual(set.pages[0].layouts.count, 1)
    }

    func testCreatedBoardAutosavesGraphAndPicturesAcrossRelaunch() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let model = ScannerModel(libraryRoot: root, legacySaveURL: root.appendingPathComponent("missing"))
        model.createBoard(title: "My words", rows: 2, columns: 2, starter: false)
        await idle(model)
        XCTAssertTrue(model.openInEditor)
        XCTAssertNil(model.editPageSet(.addPage(title: "Drinks", rows: 2, columns: 2)))
        await idle(model)
        let set = try XCTUnwrap(model.pageSet)
        var draft = try PageSetAuthoring.draft(in: set, pageID: set.homePageID, layoutID: 1, row: 0, column: 0)
        draft.button.label = "Drinks"
        draft.button.communicationAction = .openPage
        draft.button.destinationIDs = [set.pages[1].id]
        let artwork = try ButtonArtwork.symbol(BuiltinSymbol.choices[6])
        XCTAssertNil(model.editPageSet(.upsertButton(pageID: draft.pageID, layoutID: draft.layoutID, button: draft.button,
                                                    placement: draft.placement, artwork: .replace(artwork))))
        await idle(model)
        let relaunched = ScannerModel(libraryRoot: root, legacySaveURL: root.appendingPathComponent("missing"))
        await relaunched.restore()
        XCTAssertFalse(relaunched.openInEditor)
        XCTAssertEqual(relaunched.pageSet?.pages.count, 2)
        XCTAssertEqual(relaunched.pageSet?.buttons[draft.button.id]?.destinationIDs, [set.pages[1].id])
        XCTAssertEqual(relaunched.pageSet?.assets.values.first?.data, artwork)
        XCTAssertFalse(relaunched.dirty)
    }

    func testScreenshotCopyPreservesWordsPicturesAndOriginalLibraryEntry() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: root) }
        let png = try ButtonArtwork.symbol(BuiltinSymbol.choices[6])
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        var card = ScannedCard(row: 0, column: 0, label: "Water", confidence: 1, bounds: rect, pictureBounds: rect, imagePNG: png, needsReview: false)
        card.message = "Please bring water"
        card.included = false
        let board = ScannedBoard(columns: 1, rows: 1, cards: [card], sourcePNG: png, method: "Test")
        let model = ScannerModel(libraryRoot: root, legacySaveURL: root.appendingPathComponent("missing"))
        let id = UUID()
        try await model.library.save(BoardDocument(board: board), id: id)
        model.openSaved(id)
        await idle(model)
        model.makeEditableCopy()
        await idle(model)
        XCTAssertEqual(model.libraryEntries.count, 2)
        XCTAssertNotEqual(model.libraryID, id)
        XCTAssertEqual(model.pageSet?.buttons.values.first?.message, "Please bring water")
        XCTAssertEqual(model.pageSet?.assets.values.first?.data, png)
        XCTAssertEqual(model.pageSet?.pages[0].layouts[0].placements[0].visible, false)
        let original = try await model.library.load(id)
        XCTAssertEqual(original.document.board?.cards.first?.imagePNG, png)
        XCTAssertNotNil(original.document.board)
    }

    func testPhotoNormalizationAndInvalidArtwork() async throws {
        let png = try XCTUnwrap(SampleBoard.image().pngData())
        let normalized = try await ButtonArtwork.normalize(png)
        let image = try RasterImage(data: normalized, maximumDimension: 4096)
        XCTAssertLessThanOrEqual(max(image.image.width, image.image.height), 512)
        var set = try PageSetAuthoring.emptyBoard(title: "Pictures", rows: 1, columns: 1)
        let draft = try PageSetAuthoring.draft(in: set, pageID: set.homePageID, layoutID: 1, row: 0, column: 0)
        XCTAssertThrowsError(try save(draft, artwork: .replace(Data("invalid".utf8)), in: &set))
        XCTAssertTrue(set.buttons.isEmpty)
        XCTAssertTrue(set.assets.isEmpty)
    }

    private func save(_ draft: ButtonEditDraft, artwork: ArtworkChange = .unchanged, in set: inout SnapPageSet) throws {
        try PageSetAuthoring.apply(.upsertButton(pageID: draft.pageID, layoutID: draft.layoutID, button: draft.button,
                                                placement: draft.placement, artwork: artwork), to: &set)
    }
    private func encoded(_ set: SnapPageSet) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return try encoder.encode(set)
    }
    private func idle(_ model: ScannerModel) async {
        let deadline = Date().addingTimeInterval(10)
        while model.busy && Date() < deadline { try? await Task.sleep(for: .milliseconds(10)) }
        XCTAssertFalse(model.busy)
        XCTAssertNil(model.error)
    }
}
