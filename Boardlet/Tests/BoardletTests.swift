import Testing
import Foundation
import UIKit
import PDFKit
import Combine
import ImageIO
@testable import Boardlet

@MainActor
struct BoardletTests {
    @Test func cropRespectsCameraOrientationAndRejectsEmptyRegions() async throws {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 30), format: format).image { context in
            UIColor.red.setFill(); context.fill(CGRect(x: 0, y: 0, width: 20, height: 30))
        }
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, try #require(image.cgImage), [kCGImagePropertyOrientation: 6] as CFDictionary)
        #expect(CGImageDestinationFinalize(destination))
        let editor = ImageEditor()
        let result = try await editor.crop(data as Data, x: 0, y: 0, width: 1, height: 1)
        let cropped = try #require(UIImage(data: result))
        #expect(cropped.imageOrientation == .up)
        #expect(cropped.size == CGSize(width: 30, height: 20))
        await #expect(throws: (any Error).self) { try await editor.crop(data as Data, x: 1, y: 1, width: 0, height: 0) }
    }
    func temporaryDisk() -> LibraryDisk { LibraryDisk(root: URL.temporaryDirectory.appendingPathComponent("BoardletTests-\(UUID().uuidString)")) }
    func png() throws -> Data {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 30)).image { context in UIColor.red.setFill(); context.fill(CGRect(x: 0, y: 0, width: 20, height: 30)) }
        return try #require(image.pngData())
    }
    @Test func editsUndoRedoAndReopenKeepIdentityOrderAndAudio() async throws {
        let disk = temporaryDisk(); let store = BoardStore(storage: disk, mediaURL: disk.mediaURL)
        await store.load()
        let id = store.create(name: "Daily routine", template: .routine)
        let original = try #require(store.board(id))
        let first = try #require(original.cards.first)
        store.moveCard(first.id, board: id, offset: 2)
        #expect(store.board(id)?.cards[2].id == first.id)
        store.undo(id); #expect(store.board(id)?.cards.map(\.id) == original.cards.map(\.id))
        store.redo(id); #expect(store.board(id)?.cards[2].id == first.id)
        let recording = try await disk.storeAsset(Data([1,2,3]), extension: "m4a")
        store.edit(id) { $0.cards[0].recording = recording; $0.cards[0].voice = .recording }
        store.duplicate(id)
        #expect(store.boards.count == 2)
        #expect(store.boards[1].cards[0].recording == recording)
        #expect(store.boards[1].cards[0].id != store.boards[0].cards[0].id)
        await store.flush()
        let reopened = BoardStore(storage: LibraryDisk(root: disk.root), mediaURL: disk.mediaURL); await reopened.load()
        #expect(reopened.library == store.library)
        store.edit(id) { $0.deletedAt = Date() }; #expect(store.boards.count == 1)
        store.undo(id); #expect(store.boards.count == 2)
    }
    @Test func concurrentSavesCannotReplaceNewerRevision() async throws {
        let disk = temporaryDisk()
        let first = Library(boards: [Board(name: "Old")]); let newer = Library(boards: [Board(name: "New")])
        try await disk.save(newer, revision: 2); try await disk.save(first, revision: 1)
        #expect(try await disk.load() == newer)
    }
    @Test func previousSaveRecoveryRetainsCorruptManifest() async throws {
        let disk = temporaryDisk(); let original = Library(boards: [Board(name: "Recover me")])
        try await disk.save(original, revision: 1)
        try await disk.save(Library(boards: [Board(name: "Later")]), revision: 2)
        try Data("broken".utf8).write(to: disk.root.appendingPathComponent("library.json"))
        await #expect(throws: (any Error).self) { try await disk.load() }
        #expect(try await disk.restoreBackup() == original)
        #expect(try FileManager.default.contentsOfDirectory(atPath: disk.root.path).contains { $0.hasPrefix("recovery-") })
    }
    @Test func rejectsFutureVersionsAndUnsafePaths() throws {
        var library = Library(); library.schemaVersion = 2
        #expect(throws: (any Error).self) { try library.validated() }
        library = Library(boards: [Board(name: "Unsafe", cards: [Card(label: "x", image: "../private.png")])])
        #expect(throws: (any Error).self) { try library.validated() }
    }
    @Test(arguments: [0, 1, 6, 7, 40]) func paginationPreservesOrderAndAllCards(count: Int) {
        let settings = PrintSettings()
        let pages = settings.pageIndices(cardCount: count)
        #expect(pages.flatMap { $0 } == Array(0..<count))
        #expect(pages.count == max(1, (count + 5) / 6))
        var repeated = settings; repeated.repeatSingle = true
        #expect(repeated.pageIndices(cardCount: 1).first?.count == 6)
    }
    @Test func pdfContainsEveryLabelCreditsAndConfiguredPaper() throws {
        var board = Board(name: "Rutina diaria")
        board.cards = (1...14).map { Card(label: "Una etiqueta española larga número \($0)", systemSymbol: "sun.max") }
        board.cards[0].attribution = .arasaac(123)
        board.print.paper = .letter; board.print.landscape = true
        let renderer = BoardRenderer(board: board, mediaURL: temporaryDisk().mediaURL)
        let document = try #require(PDFDocument(data: renderer.pdf()))
        #expect(document.pageCount == 4)
        #expect(document.string?.contains("número 14") == true)
        #expect(document.string?.contains("CC BY-NC-SA") == true)
        #expect(document.page(at: 0)?.bounds(for: .mediaBox).width == 792)
        #expect(document.page(at: 0)?.bounds(for: .mediaBox).height == 612)
    }
    @Test func duplicateMessageEntriesStayDistinct() {
        let card = Card(label: "Water")
        let entries = [MessageEntry(card: card), MessageEntry(card: card)]
        #expect(entries.count == 2); #expect(entries[0].id != entries[1].id)
        #expect(entries.map(\.card.id) == [card.id, card.id])
    }
    @Test func legacyImportIsReadOnlyRepeatableAndPreservesOptionalFields() async throws {
        let disk = temporaryDisk(); let source = disk.root.appendingPathComponent("Legacy")
        try FileManager.default.createDirectory(at: source, withIntermediateDirectories: true)
        let image = try png(); try image.write(to: source.appendingPathComponent("image.png")); try image.write(to: source.appendingPathComponent("cover.png"))
        let audio = validWave(); try audio.write(to: source.appendingPathComponent("voice.wav"))
        let cardID = UUID()
        let json: [String: Any] = ["version": 1, "topic": ["topicName": "Comida", "topicDirectoryName": "stable-legacy-id", "imageFileName": "cover.png"], "pageSize": "A5", "orientation": "landscape", "layout": ["width": 3, "height": 2], "photos": ["photoItems": [["id": cardID.uuidString, "title": "Quiero agua", "imageFileName": "image.png", "audioFileName": "voice.wav", "fitzgeraldKey": "noun", "symbolSource": ["provider": "arasaac", "symbolID": 123, "isModified": true]]]], "formatting": ["labelPosition": "top", "marginPercentage": 0.1, "labelBoldFont": true, "cellFillColor": "#FFFF00", "pageTitleVisible": true]]
        let data = try JSONSerialization.data(withJSONObject: json); try data.write(to: source.appendingPathComponent("index.json"))
        let importer = LegacyImporter(storage: disk)
        let result = try await importer.importFolder(source, existing: [])
        let board = try #require(result.boards.first)
        #expect(board.cards[0].id == cardID)
        #expect(board.cards[0].recording != nil); #expect(board.cards[0].voice == .recording)
        #expect(board.cards[0].attribution?.modified == true); #expect(board.cover != nil)
        #expect(board.print.columns == 3 && board.print.rows == 2 && board.print.landscape)
        #expect(board.print.paper == .a5 && board.print.labelsAbove && board.print.background == "#FFFF00")
        #expect(board.legacyMetadata == data)
        #expect(try Data(contentsOf: source.appendingPathComponent("index.json")) == data)
        let repeated = try await importer.importFolder(source, existing: result.boards)
        #expect(repeated.boards.isEmpty && repeated.skipped == 1)
        try FileManager.default.removeItem(at: source.appendingPathComponent("image.png"))
        await #expect(throws: (any Error).self) { try await importer.importFolder(source, existing: []) }
        #expect(try await disk.load().boards.isEmpty)
    }
    @Test func archiveRoundTripPreservesMediaAndRejectsMissingFiles() async throws {
        let disk = temporaryDisk(); let store = BoardStore(storage: disk, mediaURL: disk.mediaURL)
        await store.load(); let id = store.create(name: "Backup", template: .blank)
        let name = try await disk.storeAsset(png(), extension: "png")
        store.edit(id) { $0.cards = [Card(label: "Picture", image: name, originalImage: name)] }
        let archive = try JSONDecoder().decode(LibraryArchive.self, from: LibraryArchive.export(store: store))
        let newDisk = temporaryDisk(); let recovered = try await archive.validatedImport(storage: newDisk)
        #expect(recovered == store.library)
        #expect(try Data(contentsOf: newDisk.mediaURL.appendingPathComponent(name)) == png())
        let invalid = LibraryArchive(format: archive.format, library: archive.library, media: [:])
        await #expect(throws: (any Error).self) { try await invalid.validatedImport(storage: newDisk) }
    }
    @Test func photoImportRetainsSuccessAndRejectsLateCallbacksAfterCancel() async throws {
        let disk = temporaryDisk(); let session = CardImportSession(); let image = try png()
        let good = ImageImportSource { completion in completion(.success(image)); return Progress(totalUnitCount: 1) }
        let bad = ImageImportSource { completion in completion(.failure(ImageImportError.invalidImage)); return Progress(totalUnitCount: 1) }
        session.importPhotos([good, bad], storage: disk)
        await waitUntilFinished(session)
        #expect(session.cards.count == 1); #expect(session.failures.count == 1)
        var delayed: ImageImportSource.Completion?
        let slow = ImageImportSource { completion in delayed = completion; return Progress(totalUnitCount: 1) }
        session.importPhotos([slow], storage: disk); session.cancel(); delayed?(.success(image))
        await Task.yield()
        #expect(session.cards.count == 1); #expect(session.loading == false)
    }
    func validWave() -> Data {
        var data = Data("RIFF".utf8)
        func uint32(_ value: UInt32) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        func uint16(_ value: UInt16) { var v = value.littleEndian; withUnsafeBytes(of: &v) { data.append(contentsOf: $0) } }
        uint32(236); data.append(Data("WAVEfmt ".utf8)); uint32(16); uint16(1); uint16(1); uint32(8000); uint32(16000); uint16(2); uint16(16)
        data.append(Data("data".utf8)); uint32(200); data.append(Data(repeating: 0, count: 200)); return data
    }
    private func waitUntilFinished(_ session: CardImportSession) async {
        for _ in 0..<200 { if !session.loading { return }; try? await Task.sleep(for: .milliseconds(10)) }
        Issue.record("Importer did not finish")
    }
}
