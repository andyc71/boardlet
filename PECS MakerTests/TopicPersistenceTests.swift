//
//  PersistenceTests.swift
//  PersistenceTests
//
//  Created by Andy on 24/09/2021.
//

import XCTest
import PersistenceFramework
@testable import PECS_Maker
import SwiftUI


class TopoicPersistenceTests: PersistenceTestsBase {

    func testInspirationRequiresAChosenTitle() {
        for title in ["", "   ", "New Board", "New Board 12", "Nuevo Tablero", "Nuevo Tablero 4", L10n.Repo.defaultTopicTitle,
                      L10n.Repo.defaultTopicTitle + " 3"] {
            XCTAssertFalse(PECSRepo.isChosenBoardTitle(title), title)
        }
        for title in ["Fruit", " Breakfast ", "New Board games", "Activities 12"] {
            XCTAssertTrue(PECSRepo.isChosenBoardTitle(title), title)
        }
    }

    func testNewBoardSuggestionOfferPersistsAndOldBoardsDoNotOptIn() throws {
        let repo = try repoFactory.createEmptyRepo(directoryURL: tempDir, setActive: false)
        repo.offersSuggestionsAfterNaming = true
        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = tempDir
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = tempDir
        let data = try encoder.encode(repo)
        XCTAssertTrue(try decoder.decode(PECSRepo.self, from: data).offersSuggestionsAfterNaming)

        repo.offersSuggestionsAfterNaming = false
        XCTAssertFalse(try decoder.decode(PECSRepo.self, from: encoder.encode(repo)).offersSuggestionsAfterNaming)

        var oldBoard = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        oldBoard.removeValue(forKey: "offersSuggestionsAfterNaming")
        let oldData = try JSONSerialization.data(withJSONObject: oldBoard)
        XCTAssertFalse(try decoder.decode(PECSRepo.self, from: oldData).offersSuggestionsAfterNaming)
    }

    func testCollageFormattingEncoding() throws {
        
        let format1 = CollageFormatting()
        format1.cardTitleFontBold = true
        format1.cardTitleFontColor = Color.yellow
        format1.cardTitlePosition = .bottom
        format1.cardTitleFontHeightPercentage = 0.2
        format1.gridlinesThick = true
        format1.gridlinesColor = Color.green
        format1.cellFillColor = Color.yellow
        format1.fitzgeraldBordersEnabled = true
        format1.fitzgeraldBordersThick = true
        format1.marginPercentage = 0.2
        
        //Save the item
        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = tempDir

        let data = try encoder.encode(format1)
        
        //Re-load the item
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = tempDir
        let format2 = try decoder.decode(CollageFormatting.self, from: data)
                
        //Check that the original and reloaded item match
        XCTAssertNotNil(format2)
        XCTAssertEqual(format1.cardTitleFontColor.getHex(), format2.cardTitleFontColor.getHex())
        XCTAssertEqual(format1.cardTitleFontBold, format2.cardTitleFontBold)
        XCTAssertEqual(format1.cardTitlePosition, format2.cardTitlePosition)
        XCTAssertEqual(format1.cardTitleFontHeightPercentage, format2.cardTitleFontHeightPercentage)
        
        XCTAssertEqual(format1, format2)
        
        //Make a change and ensure that they don't match.
        format1.marginPercentage += 1.0
        XCTAssertNotEqual(format1, format2)
        
    }

    func testTopicEncoding() throws {
        
        let repo1 = try createTestRepo()
        
        //Save the item
        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = tempDir
        let data = try encoder.encode(repo1)
        
        //Re-load the item
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = tempDir
        let repo2 = try decoder.decode(PECSRepo.self, from: data)
                
        XCTAssertNotNil(repo2)
        
        compareRepos(repo1, repo2)
        
        //Expecting one file for each photo, plus the index file and the topic image.
        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(assetIds.count + 3, files.count)
        
        let photoFiles = files.filter {$0.pathExtension.uppercased() == "PNG"}
        XCTAssertEqual(assetIds.count + 1, photoFiles.count)

    }
    
    func createTestRepo() throws -> PECSRepo {
        
        let photoBrowserData = PhotoBrowserData()
        for assetId in assetIds {
            let photoItem = makePhotoItem(assetId: assetId)
            photoBrowserData.photoItems.append(photoItem)
        }

        let repo1 = try repoFactory.createEmptyRepo(directoryURL: tempDir, setActive: false)
        repo1.topicName = "Animals"
        repo1.pageSize = PageSize.a4
        repo1.orientation = PageOrientation.landscape
        repo1.layout = PageLayout(width: 3, height: 2)
        repo1.photos = photoBrowserData
        repo1.checkmarks = PageLayoutCheckmarks()
        repo1.checkmarks.didPageLayout = true
        repo1.checkmarks.didTitles = true
        repo1.checkmarks.didPrint = false
        return repo1
    }
    
    func compareRepos(_ repo1: PECSRepo, _ repo2: PECSRepo) {
        XCTAssertEqual(repo1.topicName, repo2.topicName)
        XCTAssertEqual(repo1.photos.photoItems.count, repo2.photos.photoItems.count)
        XCTAssertEqual(repo1.pageSize, repo2.pageSize)
        XCTAssertEqual(repo1.orientation, repo2.orientation)
        XCTAssertEqual(repo1.layout, repo2.layout)
        XCTAssertEqual(repo1.checkmarks.didPageLayout, repo2.checkmarks.didPageLayout)
        XCTAssertEqual(repo1.checkmarks.didTitles, repo2.checkmarks.didTitles)
        XCTAssertEqual(repo1.checkmarks.didPrint, repo2.checkmarks.didPrint)
        
        //Now do the same comparison using Equatable
        XCTAssertEqual(repo1.photos.photoItems.count, repo2.photos.photoItems.count)
        XCTAssertEqual(repo1.photos.photoItems[0], repo2.photos.photoItems[0])
        XCTAssertEqual(repo1.photos, repo2.photos)
        XCTAssertEqual(repo1.checkmarks, repo2.checkmarks)
        //The repo itself isn't equatable because of its identifier, but we might
        //serialize that one day.
        //XCTAssertEqual(repo1, repo2)
        
    }
    
    func testTopicSaving() throws {
        
        let repo1 = try createTestRepo()
        
        try repo1.save(directory: tempDir)
                        
        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(assetIds.count + 3, files.count)
        //let files = FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        
        XCTAssertTrue(files.contains(where: {$0.lastPathComponent == "index.json"}))

        let photoFiles = files.filter {$0.pathExtension.uppercased() == "PNG"}
        XCTAssertEqual(assetIds.count + 1, photoFiles.count)


        let repo2 = try PECSRepo.load(directory: tempDir)
        XCTAssertNotNil(repo2)
        
        compareRepos(repo1, repo2)
        
        //repo1.checkmarks.didTitles = !repo1.checkmarks.didTitles
        repo1.photos.photoItems.remove(at: 0)
        //XCTAssertNotEqual(repo1.checkmarks, repo2.checkmarks)
        XCTAssertEqual(repo1.id, repo2.id) // Document identity survives edits and reloads.
        XCTAssertNotEqual(repo1.photos, repo2.photos)
    
    }
    
    ///Make sure we don't have leftover photos in the topic folder after we remove
    ///a photo from the photos collection
    func testTopicFileCleanup() throws {
                
        let repo1 = try createTestRepo()
        XCTAssertEqual(repo1.photos.photoCount, assetIds.count)
        
        try repo1.save(directory: tempDir)
        
        //Expected file count is the number of photos, plus the index file, plus the topic image
        let expectedPhotoCountOriginal = repo1.photos.photoCount
        let expectedImageFileCountOriginal = expectedPhotoCountOriginal + 1
        let expectedFileCountOriginal = expectedImageFileCountOriginal + 2
                        
        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(expectedFileCountOriginal, files.count)
        
        XCTAssertTrue(files.contains(where: {$0.lastPathComponent == "index.json"}))

        let photoFiles = files.filter {$0.pathExtension.uppercased() == "PNG"}
        XCTAssertEqual(expectedImageFileCountOriginal, photoFiles.count)
        
        repo1.photos.removePhoto(with: assetIds.last!)
        XCTAssertEqual(expectedPhotoCountOriginal - 1, repo1.photos.photoCount)
        
        try repo1.save(directory: tempDir)
        
        let files2 = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(expectedFileCountOriginal - 1, files2.count)

        let photoFiles2 = files2.filter {$0.pathExtension.uppercased() == "PNG"}
        XCTAssertEqual(expectedImageFileCountOriginal - 1, photoFiles2.count)


    }
    
    /*
    func testPageLayoutStateFilePersistence() throws {
        
        let photoBrowserData = PhotoBrowserData()

        for assetId in assetIds {
            let photoItem = makePhotoItem(assetId: assetId)
            photoBrowserData.photoItems.append(photoItem)
        }
        
        let pageLayoutState1 = PageLayoutState()
        pageLayoutState1.photoBrowserData = photoBrowserData
        
        //Save the item
        try pageLayoutState1.save(topicName: "Cats")
        
        //Re-load the item
        //let pageLayoutState2 = try PageLayoutState(folderName: folderName)
        let pageLayoutState2 = PageLayoutState()
        try pageLayoutState2.load(topicName: "Cats")
                
        XCTAssertEqual(pageLayoutState1.photos.count, pageLayoutState2.photos.count)
        XCTAssertEqual(pageLayoutState1.pageSize, pageLayoutState2.pageSize)
        XCTAssertEqual(pageLayoutState1.orientation, pageLayoutState2.orientation)
        XCTAssertEqual(pageLayoutState1.pageLayout, pageLayoutState2.pageLayout)

    }*/

}

final class StarterBoardTests: XCTestCase {
    func testNewBoardsInstallIntoAnExistingLibraryInBothLanguages() throws {
        let fm = FileManager.default
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        for language in ["en", "es"] {
            let documents = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? fm.removeItem(at: documents) }
            try fm.createDirectory(at: documents, withIntermediateDirectories: true)
            let names = try StarterBoardInstaller.orderedDirectoryNames(from: source, language: language)
            // The original 15 were installed previously, then deleted by the user.
            let newBoardNames = ["Getting dressed", "Feeling unwell", "Arts & crafts", "At the shops"]
            let newBoards = names.filter { newBoardNames.contains(String($0.dropLast(39))) }
            let originalBoards = names.filter { !newBoards.contains($0) }
            let ledger: [String: Any] = ["language": language, "installed": originalBoards]
            try JSONSerialization.data(withJSONObject: ledger)
                .write(to: documents.appendingPathComponent(".starter-boards-v1.json"))
            try StarterBoardInstaller.install(from: source, into: documents, language: language)
            let installed = try fm.contentsOfDirectory(atPath: documents.appendingPathComponent("topics").path)
            XCTAssertEqual(Set(installed), Set(newBoards))
            try StarterBoardInstaller.install(from: source, into: documents, language: language)
            XCTAssertEqual(try fm.contentsOfDirectory(atPath: documents.appendingPathComponent("topics").path).count, 4)
        }
    }

    func testStarterOrderAndUserOrderInBothLanguages() throws {
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        let expected = ["Greetings", "I Need", "My Answer", "Breakfast", "Lunch", "Dinner",
                        "Drinks", "Snacks", "At Mealtimes", "Things to Do", "Getting dressed",
                        "Playtime", "Arts & crafts", "Places to Go", "At the shops", "Transport",
                        "How I Feel", "Feeling unwell", "What would Help", "Home", "School", "Work", "Technology", "Health"]
        for language in ["en", "es"] {
            let names = try StarterBoardInstaller.orderedDirectoryNames(from: source, language: language)
            XCTAssertEqual(names.map { String($0.dropLast(39)) }, expected)
            let topics = try names.reversed().map {
                try PECSRepo.load(directory: source.appendingPathComponent("topics/" + $0))
            }
            let ordered = PECSRepoFactory.orderedTopics(topics, savedOrder: [])
            XCTAssertEqual(ordered.map(\.topicDirectoryName), names.map(Optional.some))
            // Renaming a board must not change its saved position.
            topics[0].topicName = "Renamed board"
            let customOrder = Array(names.reversed())
            let reordered = PECSRepoFactory.orderedTopics(topics, savedOrder: customOrder + [customOrder[0]])
            XCTAssertEqual(reordered.map(\.topicDirectoryName), customOrder.map(Optional.some))
        }
    }

    func testBundledBoardsDecodeInBothLanguages() throws {
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        for language in ["en", "es"] {
            let folders = try FileManager.default.contentsOfDirectory(
                at: source.appendingPathComponent("topics"), includingPropertiesForKeys: nil)
            XCTAssertEqual(folders.count, 24)
            for folder in folders {
                let repo = try PECSRepo.load(directory: folder)
                repo.selectLanguage(language)
                XCTAssertEqual(repo.photos.photoItems.count, 20)
                XCTAssertEqual(repo.topicDirectoryName, folder.lastPathComponent)
                for card in repo.photos.photoItems {
                    XCTAssertTrue(card.hasPhoto)
                    XCTAssertNotNil(card.image.cgImage)
                    XCTAssertFalse(card.title?.isEmpty ?? true)
                }
            }
        }
    }

    func testInstallPreservesEditsDeletionsAndChosenLanguage() throws {
        let fm = FileManager.default
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        let documents = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: documents) }
        try StarterBoardInstaller.install(from: source, into: documents, language: "es-ES")
        let topics = documents.appendingPathComponent("topics")
        let folders = try fm.contentsOfDirectory(at: topics, includingPropertiesForKeys: nil).sorted { $0.path < $1.path }
        XCTAssertEqual(folders.count, 24)
        let edited = folders[0].appendingPathComponent("index.json")
        let userEdit = Data("user-edited content".utf8)
        try userEdit.write(to: edited)
        try fm.removeItem(at: folders[1])
        try StarterBoardInstaller.install(from: source, into: documents, language: "en")
        XCTAssertEqual(try Data(contentsOf: edited), userEdit)
        XCTAssertFalse(fm.fileExists(atPath: folders[1].path))
        XCTAssertEqual(try fm.contentsOfDirectory(atPath: topics.path).count, 23)
    }
}

extension StarterBoardTests {
    func testPreviouslySavedStarterBoardRecoversImageReferences() throws {
        let fm = FileManager.default
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        let documents = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: documents) }
        let restored = try StarterBoardInstaller.restoreMissing(from: source, into: documents, language: "en")
        let directory = try XCTUnwrap(restored.first)
        let index = directory.appendingPathComponent("index.json")
        let original = try PECSRepo.load(directory: directory)
        let names = original.photos.photoItems.map { "Legacy - PhotoItem-\($0.itemID.uuidString).png" }
        for (card, name) in zip(original.photos.photoItems, names) {
            try fm.moveItem(at: XCTUnwrap(card.imageURL), to: directory.appendingPathComponent(name))
        }
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: index)) as? [String: Any])
        var photos = try XCTUnwrap(json["photos"] as? [String: Any])
        var items = try XCTUnwrap(photos["photoItems"] as? [[String: Any]])
        for i in items.indices {
            let id = try XCTUnwrap(items[i]["id"] as? String)
            items[i]["imageFileName"] = "PhotoItem-\(id).png"
        }
        photos["photoItems"] = items
        json["photos"] = photos
        try JSONSerialization.data(withJSONObject: json).write(to: index)

        let recovered = try PECSRepo.load(directory: directory)
        XCTAssertEqual(recovered.photos.photoItems.map(\.imageFileName), names.map(Optional.some))
        try recovered.saveToFile()
        XCTAssertEqual(try PECSRepo.load(directory: directory).photos.photoItems.map(\.imageFileName), names.map(Optional.some))

        // A genuinely missing image must still report an error.
        let imageURL = try XCTUnwrap(recovered.photos.photoItems.first?.imageURL)
        try fm.removeItem(at: imageURL)
        XCTAssertThrowsError(try PECSRepo.load(directory: directory))
    }

    func testExplicitRestoreAfterDeletingAllBoardsInBothLanguages() throws {
        let fm = FileManager.default
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        let originalDocuments = RepoHelper.documentsDirectory
        defer { RepoHelper.documentsDirectory = originalDocuments }
        for language in ["en", "es"] {
            let documents = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            defer { try? fm.removeItem(at: documents) }
            try StarterBoardInstaller.install(from: source, into: documents, language: language)
            RepoHelper.documentsDirectory = documents
            let factory = RepoFactory<PECSRepo>()
            XCTAssertEqual(factory.availableTopics.count, 24)
            let topics = documents.appendingPathComponent("topics")
            factory.availableTopics.forEach(factory.deleteTopic)
            XCTAssertTrue(factory.availableTopics.isEmpty)

            XCTAssertEqual(try StarterBoardInstaller.missingBoards(
                from: source, into: documents, language: language).count, 24)
            let restored = try StarterBoardInstaller.restoreMissing(
                from: source, into: documents, language: language)
            XCTAssertEqual(restored.count, 24)
            XCTAssertEqual(try fm.contentsOfDirectory(atPath: topics.path).count, 24)
            for folder in restored {
                XCTAssertEqual(try PECSRepo.load(directory: folder).photos.photoItems.count, 20)
            }
            // Match the production restore's save-and-reload operation.
            let first = try PECSRepo.load(directory: XCTUnwrap(restored.first))
            try factory.renameTopic(first, topicName: first.topicName)
            _ = try PECSRepo.load(directory: first.docDir)
            XCTAssertEqual(factory.availableTopics.count, 24)
            for board in factory.availableTopics {
                let imageNames = board.photos.photoItems.map(\.imageFileName)
                try board.saveToFile()
                let reloaded = try PECSRepo.load(directory: board.docDir)
                XCTAssertEqual(reloaded.photos.photoItems.map(\.imageFileName), imageNames)
            }
            XCTAssertTrue(try StarterBoardInstaller.restoreMissing(
                from: source, into: documents, language: language).isEmpty)
        }
    }

    func testExplicitRestoreAddsTwelveMissingBoardsWithoutReplacingEdits() throws {
        let fm = FileManager.default
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        let documents = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: documents) }
        try StarterBoardInstaller.install(from: source, into: documents, language: "en")
        let topics = documents.appendingPathComponent("topics")
        let folders = try fm.contentsOfDirectory(at: topics, includingPropertiesForKeys: nil)
        for folder in folders.prefix(12) { try fm.removeItem(at: folder) }
        let edited = folders[12].appendingPathComponent("index.json")
        let editedBoard = try PECSRepo.load(directory: folders[12])
        editedBoard.topicName = "My renamed starter board"
        editedBoard.photos.photoItems[0].title = "My edited card"
        try editedBoard.saveToFile()
        let userEdit = try Data(contentsOf: edited)

        XCTAssertEqual(try StarterBoardInstaller.missingBoards(from: source, into: documents, language: "en").count, 12)
        // Preparing the confirmation is read-only; cancellation leaves these twelve boards alone.
        XCTAssertEqual(try fm.contentsOfDirectory(atPath: topics.path).count, 12)
        let restored = try StarterBoardInstaller.restoreMissing(from: source, into: documents, language: "en")
        XCTAssertEqual(restored.count, 12)
        XCTAssertEqual(try fm.contentsOfDirectory(atPath: topics.path).count, 24)
        XCTAssertEqual(try Data(contentsOf: edited), userEdit)
        XCTAssertTrue(try StarterBoardInstaller.restoreMissing(from: source, into: documents, language: "en").isEmpty)
        for folder in restored { XCTAssertEqual(try PECSRepo.load(directory: folder).photos.photoItems.count, 20) }
    }
}

final class MultilingualBoardTests: XCTestCase {
    private func pixels(_ image: UIImage) throws -> Data {
        let cgImage = try XCTUnwrap(image.cgImage)
        let width = cgImage.width, height = cgImage.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let context = try XCTUnwrap(CGContext(data: &bytes, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return Data(bytes)
    }

    private func installedBoard() throws -> (PECSRepo, URL) {
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        let documents = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try StarterBoardInstaller.install(from: source, into: documents, language: "en")
        let name = try XCTUnwrap(StarterBoardInstaller.orderedDirectoryNames(from: source, language: "en").first)
        return (try PECSRepo.load(directory: documents.appendingPathComponent("topics").appendingPathComponent(name)), documents)
    }

    func testBoundedFallbackAndIntentionallyEmptyTranslations() {
        var text = BoardText(sourceLanguage: "es", text: "Hola")
        text.values["zh-Hant"] = "您好"
        text.values["zh-Hans"] = "你好"
        text.values["es"] = "Hola"
        for language in ["fr", "de", "it", "pt", "nl", "pl", "ru", "uk", "ja", "ko", "ar", "he", "tr", "el", "sv", "da", "no", "fi", "cs", "hu", "ro", "bg"] {
            text.values[language] = language
        }
        XCTAssertEqual(text.resolve(language: "zh-TW").text, "您好")
        XCTAssertEqual(text.resolve(language: "zh-Hant-HK").language, "zh-Hant")
        XCTAssertEqual(text.resolve(language: "es-MX").language, "es")
        XCTAssertEqual(text.resolve(language: "sw-KE").text, "Hola")
        XCTAssertLessThan(BoardLanguage.candidates(for: "zh-Hant-TW").count, 5)
        text.edit("", language: "en")
        XCTAssertEqual(text.resolve(language: "en-GB").text, "")
        XCTAssertEqual(text.resolve(language: "en-GB").language, "en")
    }

    func testLanguageEditsImagesStructureAndReload() throws {
        let (board, documents) = try installedBoard()
        defer { try? FileManager.default.removeItem(at: documents) }
        board.selectLanguage("en")
        let originalTitle = board.topicName
        let card = try XCTUnwrap(board.photos.photoItems.first)
        let originalCardTitle = card.title
        let originalImage = card.image.pngData()
        board.selectLanguage("es")
        XCTAssertNotEqual(card.title, originalCardTitle)
        board.topicName = "Mi tablero"
        card.title = "Mi saludo"
        let replacement = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        card.image = replacement
        card.symbolSource = SymbolSource(provider: .arasaac, symbolID: 1234, languageCode: "es")
        card.assetId = "spanish-photo"
        board.photos.add(photo: PhotoItem.blankCard(title: "Solo español"))
        let newID = try XCTUnwrap(board.photos.photoItems.last?.itemID)
        XCTAssertEqual(board.photos.photoItems.last?.localizedTitle?.sourceLanguage, "es")
        board.photos.photoItems.swapAt(0, 1)
        try board.saveToFile()
        let reloaded = try PECSRepo.load(directory: board.docDir)
        XCTAssertEqual(reloaded.topicName, "Mi tablero")
        XCTAssertEqual(reloaded.photos.photoItems[1].title, "Mi saludo")
        XCTAssertEqual(reloaded.photos.photoItems[1].symbolSource?.languageCode, "es")
        XCTAssertEqual(reloaded.photos.photoItems[1].assetId, "spanish-photo")
        XCTAssertEqual(try pixels(reloaded.photos.photoItems[1].image), try pixels(replacement))
        reloaded.selectLanguage("en")
        XCTAssertEqual(reloaded.topicName, originalTitle)
        XCTAssertEqual(reloaded.photos.photoItems[1].title, originalCardTitle)
        XCTAssertNil(reloaded.photos.photoItems[1].symbolSource)
        XCTAssertNil(reloaded.photos.photoItems[1].assetId)
        XCTAssertEqual(reloaded.photos.photoItems[1].image.pngData(), originalImage)
        XCTAssertEqual(reloaded.photos.photoItems.last?.itemID, newID)
        XCTAssertEqual(reloaded.photos.photoItems.last?.title, "Solo español")
        XCTAssertEqual(reloaded.photos.photoItems.last?.resolvedTextLanguage, "es")
        try reloaded.saveToFile()
        let again = try PECSRepo.load(directory: board.docDir)
        again.selectLanguage("es")
        XCTAssertEqual(again.topicName, "Mi tablero")
        XCTAssertEqual(again.photos.photoItems[1].title, "Mi saludo")
        XCTAssertEqual(try pixels(again.photos.photoItems[1].image), try pixels(replacement))
        let removedOverride = try XCTUnwrap(again.photos.photoItems[1].imageOverrides["es"])
        again.photos.photoItems.remove(at: 1)
        try again.saveToFile()
        XCTAssertFalse(FileManager.default.fileExists(atPath: again.docDir.appendingPathComponent(removedOverride).path))
        let resources = try XCTUnwrap(FileManager.default.enumerator(at: again.docDir.appendingPathComponent("locales"), includingPropertiesForKeys: nil))
        for case let url as URL in resources where url.pathExtension == "json" {
            let table = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: url))
            XCTAssertFalse(table.values.contains("Mi saludo"), "Deleted translations must not remain hidden in shared exports")
        }
    }

    func testSwitchingLanguageDoesNotCreateTranslationsOrDirtyImages() throws {
        let (board, documents) = try installedBoard()
        defer { try? FileManager.default.removeItem(at: documents) }
        let titles = board.photos.photoItems.compactMap(\.localizedTitle)
        let title = board.localization?.title
        for language in ["es", "en-GB", "fr", "zh-Hant-TW", "en"] { board.selectLanguage(language) }
        XCTAssertEqual(titles, board.photos.photoItems.compactMap(\.localizedTitle))
        XCTAssertEqual(title, board.localization?.title)
        XCTAssertTrue(board.photos.photoItems.allSatisfy { !$0.needsSave })
        board.selectLanguage(nil)
        XCTAssertNil(board.localization?.preferredLanguage)
        let placeholder = PhotoItem.blankCard()
        placeholder.localizedTitle = BoardText(sourceLanguage: "en", text: "Reserved slot")
        placeholder.selectLanguage("es")
        XCTAssertTrue(placeholder.isPlaceholder, "Resolving text must not change structural placeholder state")
        XCTAssertFalse(placeholder.hasPhoto)
        placeholder.title = "Authored card"
        XCTAssertFalse(placeholder.isPlaceholder, "An actual title edit creates a card")
    }

    func testSaveToAnotherDirectoryAndDuplicateCardPreserveAllLanguages() throws {
        let (board, documents) = try installedBoard()
        defer { try? FileManager.default.removeItem(at: documents) }
        board.selectLanguage("es")
        let card = try XCTUnwrap(board.photos.photoItems.first)
        let copy = card.copy()
        XCTAssertNotEqual(copy.itemID, card.itemID)
        XCTAssertNotEqual(copy.localizedTitle?.key, card.localizedTitle?.key)
        copy.title = "Otro saludo"
        XCTAssertNotEqual(copy.title, card.title)
        board.photos.photoItems.append(copy)
        let destination = documents.appendingPathComponent("export")
        try board.save(directory: destination)
        let reloaded = try PECSRepo.load(directory: destination)
        XCTAssertEqual(reloaded.photos.photoItems.last?.title, "Otro saludo")
        reloaded.selectLanguage("en")
        XCTAssertEqual(reloaded.photos.photoItems.last?.title, "Hello")
        XCTAssertNotNil(reloaded.photos.photoItems.last?.image.cgImage)
    }
}

extension MultilingualBoardTests {
    private func legacyFixture(source: URL, documents: URL, alias: String, edited: Bool) throws -> URL {
        let original = try XCTUnwrap(StarterBoardInstaller.legacyBoards(from: source)[alias])
        let canonical = source.appendingPathComponent("topics").appendingPathComponent(original.canonicalDirectory)
        let destination = documents.appendingPathComponent("topics").appendingPathComponent(alias)
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try FileManager.default.copyItem(at: canonical, to: destination)
        let index = destination.appendingPathComponent("index.json")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: index)) as? [String: Any])
        json.removeValue(forKey: "localization")
        json.removeValue(forKey: "id")
        json["version"] = 1
        var topic = try XCTUnwrap(json["topic"] as? [String: Any])
        topic["topicName"] = edited ? "My changed meaning" : original.title
        topic["topicDirectoryName"] = alias
        json["topic"] = topic
        var photos = try XCTUnwrap(json["photos"] as? [String: Any])
        var cards = try XCTUnwrap(photos["photoItems"] as? [[String: Any]])
        for i in cards.indices {
            let reference = try XCTUnwrap(cards[i]["localizedTitle"] as? [String: String])
            let old = try XCTUnwrap(original.cards.first { $0.value.key == reference["key"] })
            cards[i]["id"] = old.key
            cards[i]["title"] = edited && i == 0 ? "Changed card" : old.value.title
            cards[i].removeValue(forKey: "localizedTitle")
        }
        if edited { cards.removeLast() }
        photos["photoItems"] = cards
        json["photos"] = photos
        try JSONSerialization.data(withJSONObject: json).write(to: index)
        return destination
    }

    func testLegacyStarterUpgradePreservesEditedMeaningsDeletionsAndDistinctCopies() throws {
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        let documents = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: documents) }
        let aliases = try StarterBoardInstaller.legacyBoards(from: source)
        let canonical = try XCTUnwrap(StarterBoardInstaller.orderedDirectoryNames(from: source, language: "en").first)
        let spanish = try XCTUnwrap(aliases.first { $0.value.canonicalDirectory == canonical && $0.value.language == "es" }?.key)
        let englishURL = try legacyFixture(source: source, documents: documents, alias: canonical, edited: false)
        let spanishURL = try legacyFixture(source: source, documents: documents, alias: spanish, edited: true)
        let english = try PECSRepo.load(directory: englishURL)
        english.selectLanguage("es")
        XCTAssertEqual(english.topicName, "Saludos")
        XCTAssertEqual(english.photos.photoItems.first?.title, "Hola")
        let edited = try PECSRepo.load(directory: spanishURL)
        let ids = edited.photos.photoItems.map(\.itemID)
        edited.selectLanguage("en")
        XCTAssertEqual(edited.topicName, "My changed meaning")
        XCTAssertEqual(edited.photos.photoItems.first?.title, "Changed card")
        XCTAssertEqual(edited.photos.photoItems.count, english.photos.photoItems.count - 1)
        XCTAssertEqual(edited.photos.photoItems.first?.localizedTitle?.sourceLanguage, "und")
        XCTAssertEqual(edited.photos.photoItems[1].title, "Goodbye")
        try edited.saveToFile()
        XCTAssertEqual(try PECSRepo.load(directory: spanishURL).photos.photoItems.map(\.itemID), ids)
        try StarterBoardInstaller.install(from: source, into: documents, language: "en")
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: documents.appendingPathComponent("topics").path).count, 25)
        XCTAssertTrue(try StarterBoardInstaller.missingBoards(from: source, into: documents, language: "es").isEmpty)
    }

    func testLegacySpanishDeletionLedgerDoesNotReinstallCanonicalCopy() throws {
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        let documents = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: documents) }
        try FileManager.default.createDirectory(at: documents, withIntermediateDirectories: true)
        let oldNames = try StarterBoardInstaller.legacyBoards(from: source).filter { $0.value.language == "es" }.map(\.key)
        let ledger: [String: Any] = ["language": "es", "installed": oldNames]
        try JSONSerialization.data(withJSONObject: ledger).write(to: documents.appendingPathComponent(".starter-boards-v1.json"))
        try StarterBoardInstaller.install(from: source, into: documents, language: "en")
        XCTAssertFalse(FileManager.default.fileExists(atPath: documents.appendingPathComponent("topics").path))
        XCTAssertEqual(try StarterBoardInstaller.restoreMissing(from: source, into: documents, language: "en").count, 24)
    }

    func testUnknownLegacyContentRemainsSourceFallbackAfterTranslation() throws {
        let (board, documents) = try installedBoard()
        defer { try? FileManager.default.removeItem(at: documents) }
        let card = try XCTUnwrap(board.photos.photoItems.first)
        card.localizedTitle = BoardText(key: card.itemID.uuidString, sourceLanguage: "und", text: "Unassigned text")
        card.selectLanguage("es")
        XCTAssertEqual(card.title, "Unassigned text")
        XCTAssertNil(card.resolvedTextLanguage)
        card.title = "Texto traducido"
        card.selectLanguage("fr")
        XCTAssertEqual(card.title, "Unassigned text")
        try board.saveToFile()
        let reloaded = try PECSRepo.load(directory: board.docDir)
        reloaded.selectLanguage("es")
        XCTAssertEqual(reloaded.photos.photoItems.first?.title, "Texto traducido")
        reloaded.selectLanguage("en")
        XCTAssertEqual(reloaded.photos.photoItems.first?.title, "Unassigned text")
    }
}

extension MultilingualBoardTests {
    func testUnsavedImageOverrideSurvivesLanguageSwitchAndRegionalFallback() throws {
        let (board, documents) = try installedBoard()
        defer { try? FileManager.default.removeItem(at: documents) }
        board.selectLanguage("en")
        let card = try XCTUnwrap(board.photos.photoItems.first)
        let base = try pixels(card.image)
        board.selectLanguage("es")
        let override = UIGraphicsImageRenderer(size: CGSize(width: 5, height: 5)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 5, height: 5))
        }
        card.image = override
        board.selectLanguage("en")
        XCTAssertEqual(try pixels(card.image), base)
        board.selectLanguage("es-MX")
        XCTAssertEqual(try pixels(card.image), try pixels(override))
        try board.saveToFile()
        let reloaded = try PECSRepo.load(directory: board.docDir)
        XCTAssertEqual(reloaded.localization?.preferredLanguage, "es-MX")
        XCTAssertEqual(try pixels(reloaded.photos.photoItems[0].image), try pixels(override))
    }

    func testLocalizedCoverAndReadOnlyThumbnailKeepTranslations() throws {
        let (board, documents) = try installedBoard()
        defer { try? FileManager.default.removeItem(at: documents) }
        board.selectLanguage("en")
        let original = try pixels(board.topicImage)
        board.selectLanguage("es")
        let cover = UIGraphicsImageRenderer(size: CGSize(width: 6, height: 6)).image { context in
            UIColor.green.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 6, height: 6))
        }
        board.topicImage = cover
        try board.saveToFile()
        let reloaded = try PECSRepo.load(directory: board.docDir)
        XCTAssertEqual(try pixels(reloaded.topicImage), try pixels(cover))
        reloaded.selectLanguage("en")
        XCTAssertEqual(try pixels(reloaded.topicImage), original)
        let strings = reloaded.photos.photoItems.compactMap(\.localizedTitle)
        reloaded.generateTopicThumbnail = true
        let before = try Data(contentsOf: board.docDir.appendingPathComponent("index.json"))
        reloaded.refreshLocalizedThumbnail()
        XCTAssertEqual(reloaded.photos.photoItems.compactMap(\.localizedTitle), strings)
        XCTAssertEqual(try Data(contentsOf: board.docDir.appendingPathComponent("index.json")), before)
    }

    func testFrameworkDuplicatePreservesTranslationsWithDistinctBoardIdentity() throws {
        let (board, documents) = try installedBoard()
        defer { try? FileManager.default.removeItem(at: documents) }
        let originalDocuments = RepoHelper.documentsDirectory
        defer { RepoHelper.documentsDirectory = originalDocuments }
        RepoHelper.documentsDirectory = documents
        board.selectLanguage("es")
        try board.saveToFile()
        let factory = RepoFactory<PECSRepo>()
        let copy = try factory.duplicateTopic(repo: board)
        XCTAssertNotEqual(copy.id, board.id)
        XCTAssertNotEqual(copy.docDir, board.docDir)
        XCTAssertEqual(copy.photos.photoItems.first?.localizedTitle?.values, board.photos.photoItems.first?.localizedTitle?.values)
        copy.selectLanguage("en")
        XCTAssertEqual(copy.photos.photoItems.first?.title, "Hello")
        XCTAssertNotNil(copy.photos.photoItems.first?.image.cgImage)
    }
}

extension StarterBoardTests {
    func testSavingThroughSymlinkPreservesEveryImageAndTranslationTable() throws {
        let fm = FileManager.default
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        let root = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: root) }
        let real = root.appendingPathComponent("real")
        let linked = root.appendingPathComponent("linked")
        try StarterBoardInstaller.install(from: source, into: real, language: "en")
        try fm.createSymbolicLink(at: linked, withDestinationURL: real)
        let names = try StarterBoardInstaller.orderedDirectoryNames(from: source, language: "en")
        for name in names {
            let board = try PECSRepo.load(directory: linked.appendingPathComponent("topics").appendingPathComponent(name))
            let expectedImages = try board.photos.photoItems.map { card in
                try Data(contentsOf: XCTUnwrap(card.imageURL))
            }
            let expectedText = board.photos.photoItems.map { $0.localizedTitle?.values }
            // Exercise repeated writes, including cleanup of superseded string tables.
            board.selectLanguage("es")
            try board.saveToFile()
            board.selectLanguage("en")
            try board.saveToFile()
            let reloaded = try PECSRepo.load(directory: board.docDir)
            XCTAssertEqual(reloaded.photos.photoItems.map { $0.localizedTitle?.values }, expectedText)
            for (card, expected) in zip(reloaded.photos.photoItems, expectedImages) {
                XCTAssertEqual(try Data(contentsOf: XCTUnwrap(card.imageURL)), expected)
            }
        }
    }

    func testRestoreRecoversUnreadableFoldersAndPublishesAllTwentyFourBoards() throws {
        let fm = FileManager.default
        let source = try XCTUnwrap(Bundle.main.url(forResource: "StarterBoards", withExtension: nil))
        let documents = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: documents) }
        let previousDocuments = RepoHelper.documentsDirectory
        defer { RepoHelper.documentsDirectory = previousDocuments }
        RepoHelper.documentsDirectory = documents
        try StarterBoardInstaller.install(from: source, into: documents, language: "en")
        let names = try StarterBoardInstaller.orderedDirectoryNames(from: source, language: "en")
        let topics = documents.appendingPathComponent("topics")
        // Match the reported state: folders remain but their language/image
        // resources were removed, so they are absent from the visible library.
        for name in names.dropFirst(2) {
            let board = topics.appendingPathComponent(name)
            try fm.removeItem(at: board.appendingPathComponent("locales"))
            try fm.removeItem(at: board.appendingPathComponent("images"))
        }
        let factory = RepoFactory<PECSRepo>()
        XCTAssertEqual(factory.availableTopics.count, 2)
        let preserved = topics.appendingPathComponent(names[0]).appendingPathComponent("index.json")
        let preservedData = try Data(contentsOf: preserved)
        let damaged = topics.appendingPathComponent(names[2]).appendingPathComponent("index.json")
        let damagedData = try Data(contentsOf: damaged)
        XCTAssertEqual(try StarterBoardInstaller.missingBoards(from: source, into: documents, language: "en").count, 22)
        let restored = try StarterBoardInstaller.restoreMissing(from: source, into: documents, language: "en")
        XCTAssertEqual(restored.count, 22)
        let first = try PECSRepo.load(directory: XCTUnwrap(restored.first))
        try factory.renameTopic(first, topicName: first.topicName)
        XCTAssertEqual(factory.availableTopics.count, 24)
        XCTAssertEqual(try Data(contentsOf: preserved), preservedData)
        let recovery = documents.appendingPathComponent(".starter-board-recovery")
        let backups = try fm.contentsOfDirectory(at: recovery, includingPropertiesForKeys: nil)
        XCTAssertEqual(backups.count, 22)
        let savedDamagedIndex = try XCTUnwrap(backups.map {
            $0.appendingPathComponent(names[2]).appendingPathComponent("index.json")
        }.first { fm.fileExists(atPath: $0.path) })
        XCTAssertEqual(try Data(contentsOf: savedDamagedIndex), damagedData)
        XCTAssertTrue(try StarterBoardInstaller.restoreMissing(from: source, into: documents, language: "en").isEmpty)
        factory.availableTopics.forEach(factory.deleteTopic)
        XCTAssertEqual(try StarterBoardInstaller.restoreMissing(from: source, into: documents, language: "en").count, 24)
        XCTAssertEqual(RepoFactory<PECSRepo>().availableTopics.count, 24)
    }
}
