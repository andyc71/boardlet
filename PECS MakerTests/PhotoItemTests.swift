//
//  PhotoItemTests.swift
//  PhotoItemTests
//
//  Created by Andy on 09/02/2022.
//

import XCTest
import PersistenceFramework
@testable import PECS_Maker
import SwiftUI
import PDFKit

class PhotoItemTests: PersistenceTestsBase {

    func testSinglePhotoItemEncoding() throws {
        
        //Load an image to use in the PhotoItem to be persisted
        let assetId: String = assetIds[0]
        
        try encodeAndDecodePhoto(assetId)
    }
    
    func encodeAndDecodePhoto(_ assetId: String) throws {

        let photoItem1 = makePhotoItem(assetId: assetId)
        
        //Save the photo item
        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = tempDir
        let data = try encoder.encode(photoItem1)
        
        //Re-load the item
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = tempDir
        let photoItem2 = try decoder.decode(PhotoItem.self, from: data)
        
        XCTAssertNotNil(photoItem2)
        
        XCTAssertEqual(photoItem1.id, photoItem2.id)
        XCTAssertEqual(photoItem1.assetId, photoItem2.assetId)
        XCTAssertEqual(photoItem1.title, photoItem2.title)
        XCTAssertEqual(photoItem1.fitzgeraldKey, photoItem2.fitzgeraldKey)

        //At this point the image will be actually loaded from disk.
        XCTAssertGreaterThan(photoItem2.image.size.width, 0)
        XCTAssertGreaterThan(photoItem2.image.size.height, 0)

        XCTAssertEqual(photoItem1.image.size.width, photoItem2.image.size.width)
        XCTAssertEqual(photoItem1.image.size.height, photoItem2.image.size.height)
        
    }
    
    func saveAndLoadPhoto(_ assetId: String) throws {

        let photoItem1 = makePhotoItem(assetId: assetId)
        XCTAssertTrue(photoItem1.needsSave)
        
        let indexFile = tempDir.appendingPathComponent("PhotoItem.json")
        
        //Save the photo item
        try photoItem1.save(to: indexFile)
        XCTAssertFalse(photoItem1.needsSave)
        
        //Re-load the item
        let photoItem2 = try PhotoItem.load(from: indexFile)
        XCTAssertFalse(photoItem2.needsSave)
        
        XCTAssertNotNil(photoItem2)
        
        XCTAssertEqual(photoItem1.id, photoItem2.id)
        XCTAssertEqual(photoItem1.assetId, photoItem2.assetId)
        XCTAssertEqual(photoItem1.title, photoItem2.title)
        XCTAssertEqual(photoItem1.fitzgeraldKey, photoItem2.fitzgeraldKey)

        //At this point the image will be actually loaded from disk.
        XCTAssertGreaterThan(photoItem2.image.size.width, 0)
        XCTAssertGreaterThan(photoItem2.image.size.height, 0)

        XCTAssertEqual(photoItem1.image.size.width, photoItem2.image.size.width)
        XCTAssertEqual(photoItem1.image.size.height, photoItem2.image.size.height)
        
    }

    func testLargePhotoItemEncoding() throws {
        //Load an image to use in the PhotoItem to be persisted
        let assetId: String = largePhotoAssetId
        try encodeAndDecodePhoto(assetId)
    }
    
    func testLargePhotoItemSaving() throws {
        //Load an image to use in the PhotoItem to be persisted
        let assetId: String = largePhotoAssetId
        try saveAndLoadPhoto(assetId)
    }
    
    func fileModifiedDate(_ fileURL: URL) throws -> Date {
        let attr = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        return attr[FileAttributeKey.modificationDate] as! Date
    }
    
    func testForUnnecessarySaving() throws {
        //Load an image to use in the PhotoItem to be persisted
        let assetId: String = assetIds[0]

        let photoItem1 = makePhotoItem(assetId: assetId)
        XCTAssertTrue(photoItem1.needsSave)
        
        let indexFile = tempDir.appendingPathComponent("PhotoItem.json")
        
        //Save the photo item
        try photoItem1.save(to: indexFile)
        XCTAssertFalse(photoItem1.needsSave)
        
        //Store the modifed date after the save
        let photoFileURL1 = tempDir.appendingPathComponent(photoItem1.imageFileName!)
        let modifiedDate1 = try fileModifiedDate(photoFileURL1)
        
        usleep(500)
        
        //Save the photo item again. No disk write should
        //happen because it's unchanged, so the file modified
        //date should be the same.
        try photoItem1.save(to: indexFile)
        XCTAssertFalse(photoItem1.needsSave)

        let photoFileURL2 = tempDir.appendingPathComponent(photoItem1.imageFileName!)
        let modifiedDate2 = try fileModifiedDate(photoFileURL2)
        
        XCTAssertEqual(photoFileURL1.path, photoFileURL2.path)
        XCTAssertEqual(modifiedDate1, modifiedDate2)
        
        usleep(500)

        //Modify the photo and save it again. This time the file
        //modified date should change.
        let assetId2: String = assetIds[2]
        photoItem1.image = loadImageAsset(assetId: assetId2)!
        try photoItem1.save(to: indexFile)
        XCTAssertFalse(photoItem1.needsSave)

        let photoFileURL3 = tempDir.appendingPathComponent(photoItem1.imageFileName!)
        let modifiedDate3 = try fileModifiedDate(photoFileURL3)
        
        XCTAssertEqual(photoFileURL1.path, photoFileURL3.path)
        XCTAssertNotEqual(modifiedDate1, modifiedDate3)
        
    }


    func testPhotoBrowserDataEncoding() throws {
        
        let photoBrowserData1 = PhotoBrowserData()

        for assetId in assetIds {
            let photoItem = makePhotoItem(assetId: assetId)
            photoBrowserData1.photoItems.append(photoItem)
        }
        
        //Save the item
        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = tempDir

        let data = try encoder.encode(photoBrowserData1)
        
        //Re-load the item
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = tempDir
        let photoBrowserData2 = try decoder.decode(PhotoBrowserData.self, from: data)
                
        XCTAssertNotNil(photoBrowserData2)
        
        XCTAssertEqual(photoBrowserData1.photoItems.count, photoBrowserData2.photoItems.count)
        
    }
    
    func testPhotoBrowserDataEncodingWithLargePhotos() throws {
        
        let photoBrowserData1 = PhotoBrowserData()
        
        //TODO: Need to assess this with much larger numbers (max photos we can select is 150).
        //Also consider what ZLImageBrowser does to the image before passing it back to us
        //because it can compress a raw file down to 2MB somehow.
        //Also need to see if we can avoid saving the image every time if it's unchanged.
        let assetIds: [String] = [String](repeating: largePhotoAssetId, count: 5)

        for assetId in assetIds {
            let photoItem = makePhotoItem(assetId: assetId)
            photoBrowserData1.photoItems.append(photoItem)
        }
        
        //Save the item. For 5 large files this will take a couple of secs.
        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = tempDir

        let data = try encoder.encode(photoBrowserData1)
        
        //Re-load the item
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = tempDir
        let photoBrowserData2 = try decoder.decode(PhotoBrowserData.self, from: data)
                
        XCTAssertNotNil(photoBrowserData2)
        
        XCTAssertEqual(photoBrowserData1.photoItems.count, photoBrowserData2.photoItems.count)
        
    }
    


}

extension PhotoItemTests {
    func testAACStandardSourceSurvivesCopyPersistenceAndImageEdit() throws {
        let image = try XCTUnwrap(loadImageAsset(assetId: assetIds[0]))
        let source = SymbolSource(provider: .aacStandard, symbolID: 1234, languageCode: "es",
                                  imageURL: URL(string: "https://aacstandard.com/static/test.png"),
                                  sourceURL: URL(string: "https://aacstandard.com/api/v1/symbols/1234"))
        let original = PhotoItem(image: image, title: "Apple", symbolSource: source)

        let copy = original.copy()
        XCTAssertEqual(copy.symbolSource, source)
        XCTAssertNotEqual(copy.itemID, original.itemID)

        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = tempDir
        let data = try encoder.encode(copy)
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = tempDir
        let restored = try decoder.decode(PhotoItem.self, from: data)
        XCTAssertEqual(restored.symbolSource, source)
        _ = restored.image
        XCTAssertEqual(restored.symbolSource?.isModified, false)

        restored.image = image
        XCTAssertEqual(restored.symbolSource?.isModified, true)
        XCTAssertEqual(original.symbolSource?.isModified, false)
        let editedData = try encoder.encode(restored)
        let editedRestored = try decoder.decode(PhotoItem.self, from: editedData)
        XCTAssertEqual(editedRestored.symbolSource?.isModified, true)
    }

    func testARASAACSourceSurvivesCopyPersistenceAndImageEdit() throws {
        let image = try XCTUnwrap(loadImageAsset(assetId: assetIds[0]))
        let source = SymbolSource(provider: .arasaac, symbolID: 1234)
        let original = PhotoItem(image: image, title: "Apple", symbolSource: source)

        let copy = original.copy()
        XCTAssertEqual(copy.symbolSource, source)
        XCTAssertNotEqual(copy.itemID, original.itemID)

        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = tempDir
        let data = try encoder.encode(copy)
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = tempDir
        let restored = try decoder.decode(PhotoItem.self, from: data)
        XCTAssertEqual(restored.symbolSource, source)
        _ = restored.image
        XCTAssertEqual(restored.symbolSource?.isModified, false)

        restored.image = image
        XCTAssertEqual(restored.symbolSource?.isModified, true)
        XCTAssertEqual(original.symbolSource?.isModified, false)
        let editedData = try encoder.encode(restored)
        let editedRestored = try decoder.decode(PhotoItem.self, from: editedData)
        XCTAssertEqual(editedRestored.symbolSource?.isModified, true)
    }

    func testARASAACAttributionIsIncludedInPDFExport() throws {
        let repo = try repoFactory.createEmptyRepo(directoryURL: tempDir, setActive: false)
        let state = PageLayoutState(topic: repo, setupSinks: false)
        defer { state.deleteTempFiles() }
        let image = try XCTUnwrap(loadImageAsset(assetId: assetIds[0]))
        state.setPhotos([PhotoItem(image: image,
                                   symbolSource: SymbolSource(provider: .arasaac, symbolID: 1234))])
        let attributedImage = try XCTUnwrap(state.createPrintableCollage().first?.image)

        let pdfURL = try XCTUnwrap(state.createPDF())
        let document = try XCTUnwrap(PDFDocument(url: pdfURL))
        let page = try XCTUnwrap(document.page(at: 0))
        let expectedPageSize = state.pageMeasurements2.convertToPDFMeasurements()
        XCTAssertEqual(page.bounds(for: .mediaBox).width, expectedPageSize.width, accuracy: 0.01)
        XCTAssertEqual(page.bounds(for: .mediaBox).height, expectedPageSize.height, accuracy: 0.01)
        let annotations = page.annotations
        XCTAssertTrue(annotations.contains {
            $0.url?.absoluteString == "https://creativecommons.org/licenses/by-nc-sa/4.0/"
        })

        state.setPhotos([PhotoItem(image: image)])
        let plainImage = try XCTUnwrap(state.createPrintableCollage().first?.image)
        XCTAssertEqual(attributedImage.size, plainImage.size)
        XCTAssertNotEqual(attributedImage.pngData(), plainImage.pngData())
        let plainPDFURL = try XCTUnwrap(state.createPDF())
        let plainDocument = try XCTUnwrap(PDFDocument(url: plainPDFURL))
        XCTAssertFalse(try XCTUnwrap(plainDocument.page(at: 0)).annotations.contains {
            $0.url?.absoluteString == "https://creativecommons.org/licenses/by-nc-sa/4.0/"
        })
    }

    func testAACStandardCreditIsIncludedInPrintableBoard() throws {
        let repo = try repoFactory.createEmptyRepo(directoryURL: tempDir, setActive: false)
        let state = PageLayoutState(topic: repo, setupSinks: false)
        let image = try XCTUnwrap(loadImageAsset(assetId: assetIds[0]))
        state.setPhotos([PhotoItem(image: image, symbolSource: SymbolSource(provider: .aacStandard, symbolID: 1234))])
        let attributed = try XCTUnwrap(state.createPrintableCollage().first?.image)
        state.setPhotos([PhotoItem(image: image)])
        let plain = try XCTUnwrap(state.createPrintableCollage().first?.image)
        XCTAssertEqual(attributed.size, plain.size)
        XCTAssertNotEqual(attributed.pngData(), plain.pngData())
    }

    func testLegacySymbolSourceDecodesWithoutOptionalMetadata() throws {
        let data = Data(#"{"provider":"arasaac","symbolID":1234,"isModified":false}"#.utf8)
        let source = try JSONDecoder().decode(SymbolSource.self, from: data)
        XCTAssertEqual(source.provider, .arasaac)
        XCTAssertNil(source.languageCode)
        XCTAssertNil(source.imageURL)
        XCTAssertNil(source.sourceURL)
    }

    func testAACStandardTopicImageSourcePersists() throws {
        let repo = try repoFactory.createEmptyRepo(directoryURL: tempDir, setActive: false)
        let state = PageLayoutState(topic: repo, setupSinks: false)
        let image = try XCTUnwrap(loadImageAsset(assetId: assetIds[0]))
        let source = SymbolSource(provider: .aacStandard, symbolID: 5678)
        state.setTopicImage(PhotoItem(image: image, symbolSource: source),
                            isUserSelection: true, saveChanges: true)

        let restoredRepo = try PECSRepo.load(directory: tempDir)
        XCTAssertEqual(restoredRepo.topicImageSymbolSource, source)
        let restoredState = PageLayoutState(topic: restoredRepo, setupSinks: false)
        XCTAssertEqual(restoredState.topicImage.symbolSource, source)
    }

    func testARASAACTopicImageSourcePersists() throws {
        let repo = try repoFactory.createEmptyRepo(directoryURL: tempDir, setActive: false)
        let state = PageLayoutState(topic: repo, setupSinks: false)
        let image = try XCTUnwrap(loadImageAsset(assetId: assetIds[0]))
        let source = SymbolSource(provider: .arasaac, symbolID: 5678)
        state.setTopicImage(PhotoItem(image: image, symbolSource: source),
                            isUserSelection: true, saveChanges: true)

        let restoredRepo = try PECSRepo.load(directory: tempDir)
        XCTAssertEqual(restoredRepo.topicImageSymbolSource, source)
        let restoredState = PageLayoutState(topic: restoredRepo, setupSinks: false)
        XCTAssertEqual(restoredState.topicImage.symbolSource, source)
    }

    func testProviderOnlyPhotoPersistsWithoutAssetIdentifier() throws {
        let image = try XCTUnwrap(loadImageAsset(assetId: assetIds[0]))
        let original = PhotoItem(image: image)
        original.title = "Imported and edited"
        XCTAssertNil(original.assetId)
        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = tempDir
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = tempDir
        let restored = try decoder.decode(PhotoItem.self, from: data)
        XCTAssertNil(restored.assetId)
        XCTAssertEqual(restored.id, original.id)
        XCTAssertEqual(restored.title, original.title)
        XCTAssertEqual(restored.image.size, image.size)
    }

    func testAppendingProviderPhotosPreservesExistingEditsOrderAndLimit() throws {
        let image = try XCTUnwrap(loadImageAsset(assetId: assetIds[0]))
        let existing = PhotoItem(image: image)
        existing.title = "Keep my title"
        let first = PhotoItem(image: image)
        first.title = "First"
        let second = PhotoItem(image: image)
        second.title = "Second"
        let board = PhotoBrowserData()
        board.photoItems = [existing]
        board.add([first, second])
        XCTAssertTrue(board.photoItems[0] === existing)
        XCTAssertEqual(board.photoItems.map(\.title), ["Keep my title", "First", "Second"])
        XCTAssertNotEqual(board.photoItems[1].id, first.id)
        XCTAssertTrue(board.photoItems.allSatisfy { $0.assetId == nil })
        board.add(Array(repeating: first, count: AppSettings.maxSelectionsInPhotoPicker))
        XCTAssertEqual(board.photoCount, AppSettings.maxSelectionsInPhotoPicker)
        board.add([second])
        XCTAssertEqual(board.photoCount, AppSettings.maxSelectionsInPhotoPicker)
    }
}
