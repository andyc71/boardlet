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
        XCTAssertEqual(assetIds.count + 2, files.count)
        
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
        XCTAssertEqual(assetIds.count + 2, files.count)
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
        XCTAssertNotEqual(repo1, repo2)
    
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
        let expectedFileCountOriginal = expectedImageFileCountOriginal + 1
                        
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
                        "How I Feel", "Feeling unwell", "What would Help"]
        for language in ["en", "es"] {
            let names = try StarterBoardInstaller.orderedDirectoryNames(from: source, language: language)
            XCTAssertEqual(names.map { String($0.dropLast(39)) }, expected)
            let topics = try names.reversed().map {
                try PECSRepo.load(directory: source.appendingPathComponent(language + "/topics/" + $0))
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
                at: source.appendingPathComponent(language + "/topics"), includingPropertiesForKeys: nil)
            XCTAssertEqual(folders.count, 19)
            for folder in folders {
                let repo = try PECSRepo.load(directory: folder)
                XCTAssertEqual(repo.photos.photoItems.count, 9)
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
        XCTAssertEqual(folders.count, 19)
        let edited = folders[0].appendingPathComponent("index.json")
        let userEdit = Data("user-edited content".utf8)
        try userEdit.write(to: edited)
        try fm.removeItem(at: folders[1])
        try StarterBoardInstaller.install(from: source, into: documents, language: "en")
        XCTAssertEqual(try Data(contentsOf: edited), userEdit)
        XCTAssertFalse(fm.fileExists(atPath: folders[1].path))
        XCTAssertEqual(try fm.contentsOfDirectory(atPath: topics.path).count, 18)
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
        let names = original.photos.photoItems.map(\.imageFileName)
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
        XCTAssertEqual(recovered.photos.photoItems.map(\.imageFileName), names)
        try recovered.saveToFile()
        XCTAssertEqual(try PECSRepo.load(directory: directory).photos.photoItems.map(\.imageFileName), names)

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
            XCTAssertEqual(factory.availableTopics.count, 19)
            let topics = documents.appendingPathComponent("topics")
            factory.availableTopics.forEach(factory.deleteTopic)
            XCTAssertTrue(factory.availableTopics.isEmpty)

            XCTAssertEqual(try StarterBoardInstaller.missingBoards(
                from: source, into: documents, language: language).count, 19)
            let restored = try StarterBoardInstaller.restoreMissing(
                from: source, into: documents, language: language)
            XCTAssertEqual(restored.count, 19)
            XCTAssertEqual(try fm.contentsOfDirectory(atPath: topics.path).count, 19)
            for folder in restored {
                XCTAssertEqual(try PECSRepo.load(directory: folder).photos.photoItems.count, 9)
            }
            // Match the production restore's save-and-reload operation.
            let first = try PECSRepo.load(directory: XCTUnwrap(restored.first))
            try factory.renameTopic(first, topicName: first.topicName)
            _ = try PECSRepo.load(directory: first.docDir)
            XCTAssertEqual(factory.availableTopics.count, 19)
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
        let userEdit = Data("preserve my edited board".utf8)
        try userEdit.write(to: edited)

        XCTAssertEqual(try StarterBoardInstaller.missingBoards(from: source, into: documents, language: "en").count, 12)
        // Preparing the confirmation is read-only; cancellation leaves these seven boards alone.
        XCTAssertEqual(try fm.contentsOfDirectory(atPath: topics.path).count, 7)
        let restored = try StarterBoardInstaller.restoreMissing(from: source, into: documents, language: "en")
        XCTAssertEqual(restored.count, 12)
        XCTAssertEqual(try fm.contentsOfDirectory(atPath: topics.path).count, 19)
        XCTAssertEqual(try Data(contentsOf: edited), userEdit)
        XCTAssertTrue(try StarterBoardInstaller.restoreMissing(from: source, into: documents, language: "en").isEmpty)
        for folder in restored { XCTAssertEqual(try PECSRepo.load(directory: folder).photos.photoItems.count, 9) }
    }
}
