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

class PhotoItemTests: PersistenceTestsBase {

    func testDescriptivePhotoFilenameSurvivesSaveAndCopy() throws {
        let photo = PhotoItem(image: UIImage(systemName: "star")!)
        let index = tempDir.appendingPathComponent("PhotoItem.json")
        let filename = "Estrella - PhotoItem-\(photo.itemID.uuidString).png"
        photo.imageFileName = filename
        try photo.save(to: index)
        let imageURL = tempDir.appendingPathComponent(filename)
        let modified = try fileModifiedDate(imageURL)
        let loaded = try PhotoItem.load(from: index)
        try loaded.save(to: index)
        XCTAssertEqual(loaded.imageFileName, filename)
        XCTAssertEqual(try fileModifiedDate(imageURL), modified)
        XCTAssertNoThrow(try PhotoItem.load(from: index))

        let copiedDirectory = tempDir.appendingPathComponent("Copied")
        try FileManager.default.createDirectory(at: copiedDirectory, withIntermediateDirectories: true)
        let copiedIndex = copiedDirectory.appendingPathComponent("PhotoItem.json")
        try loaded.save(to: copiedIndex)
        let copied = try PhotoItem.load(from: copiedIndex)
        XCTAssertGreaterThan(copied.image.size.width, 0)
    }

    func testRecoversAnUnambiguousPhotoFilenameFromAnOlderSave() throws {
        let photo = PhotoItem(image: UIImage(systemName: "star")!)
        let index = tempDir.appendingPathComponent("PhotoItem.json")
        try photo.save(to: index)
        let oldURL = try XCTUnwrap(photo.imageURL)
        let descriptiveURL = tempDir.appendingPathComponent("Estrella - " + oldURL.lastPathComponent)
        try FileManager.default.moveItem(at: oldURL, to: descriptiveURL)
        let recovered = try PhotoItem.load(from: index)
        XCTAssertEqual(recovered.imageFileName, descriptiveURL.lastPathComponent)
        XCTAssertGreaterThan(recovered.image.size.width, 0)
        try recovered.save(to: index)
        XCTAssertEqual(try PhotoItem.load(from: index).imageFileName, descriptiveURL.lastPathComponent)

        // With two possible files, refuse to guess which is the right image.
        try photo.save(to: index)
        try FileManager.default.removeItem(at: oldURL)
        try FileManager.default.copyItem(at: descriptiveURL,
            to: tempDir.appendingPathComponent("Otro - " + oldURL.lastPathComponent))
        XCTAssertThrowsError(try PhotoItem.load(from: index))
    }

    func testRepeatedComparisonOfLargePhotoReferencesIsFast() {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 2048, height: 2048), format: format).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2048, height: 2048))
        }
        let photo = PhotoItem(image: image)
        let copy = photo.copy()
        let start = Date()
        for _ in 0..<100 {
            XCTAssertEqual(photo, photo)
            XCTAssertEqual(photo, copy)
        }
        // A generous bound for trivial comparisons, but far below the repeated
        // full-image PNG encoding that blocked SwiftUI for tens of seconds.
        XCTAssertLessThan(Date().timeIntervalSince(start), 1)
    }

    func testPhotoEqualityStillComparesContentAndMetadata() throws {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 16, height: 16)).image { context in
            UIColor.orange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 16, height: 16))
        }
        let data = try XCTUnwrap(image.pngData())
        let photo = PhotoItem(image: try XCTUnwrap(UIImage(data: data)), title: "Caption")
        let reloadedImage = try XCTUnwrap(UIImage(data: data))
        let other = PhotoItem(image: reloadedImage, title: "Caption")
        XCTAssertEqual(photo, other)
        XCTAssertEqual(photo.hashValue, other.hashValue)
        other.title = "Changed"
        XCTAssertNotEqual(photo, other)
        other.title = photo.title
        other.assetId = "Different asset"
        XCTAssertNotEqual(photo, other)
        other.assetId = nil
        other.image = UIImage(systemName: "star")!
        XCTAssertNotEqual(photo, other)
    }

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
