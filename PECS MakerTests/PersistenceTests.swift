//
//  PersistenceTests.swift
//  PersistenceTests
//
//  Created by Andy on 24/09/2021.
//

import XCTest
@testable import PECS_Maker

class PersistenceTests: XCTestCase {
    
    var tempDir: URL!
    
    override func setUpWithError() throws {
        tempDir = try createTemporaryDirectory()
    }
    
    override func tearDownWithError() throws {
        try deleteDirectory(tempDir)
    }
    
    var assetIds = ["001-apple", "002-avocado", "003-banana", "004-blueberry", "005-cherry"]
    
    func createTemporaryDirectory() throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true)
        return url
    }

    func deleteDirectory(_ directory: URL) throws {
        try FileManager.default.removeItem(at: directory)
    }


    func makePhotoItem(assetId: String) -> PhotoItem {
        let imageFileName = "\(assetId).png"
        let image = UIImage(named: imageFileName, in: Bundle(for: type(of: self)), compatibleWith: nil)
        XCTAssertNotNil(image)
        XCTAssert(image!.size.width > 0 && image!.size.height > 0)
        
        //Create the photo item
        let title = String(assetId[assetId.index(assetId.startIndex, offsetBy: 4)...])
        //let title = assetId.dropFirst(4)
        let fitzgeraldKey = FitzgeraldKey.noun
        let photoItem = PhotoItem(image: image!, asset: nil, assetId: assetId, title: title, fitzgeraldKey: fitzgeraldKey)
        
        return photoItem
    }

    func testSinglePhotoItemEncoding() throws {
        
        //Load an image to use in the PhotoItem to be persisted
        let assetId: String = assetIds[0]

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
        
        XCTAssertEqual(photoItem1.image.size.width, photoItem2.image.size.width)
        XCTAssertEqual(photoItem1.image.size.height, photoItem2.image.size.height)
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

    func testTopicEncoding() throws {
        
        let photoBrowserData = PhotoBrowserData()

        for assetId in assetIds {
            let photoItem = makePhotoItem(assetId: assetId)
            photoBrowserData.photoItems.append(photoItem)
        }
        
        let topic1 = Topic(topicName: "Animals", pageSize: .a4, orientation: .landscape, layout: .init(width: 3, height: 2), photos: photoBrowserData)
        
        //Save the item
        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = tempDir
        let data = try encoder.encode(topic1)
        
        //Re-load the item
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = tempDir
        let topic2 = try decoder.decode(Topic.self, from: data)
                
        XCTAssertNotNil(topic2)
        
        XCTAssertEqual(topic1.photos.photoItems.count, topic2.photos.photoItems.count)
        XCTAssertEqual(topic1.pageSize, topic2.pageSize)
        XCTAssertEqual(topic1.orientation, topic2.orientation)
        XCTAssertEqual(topic1.layout, topic2.layout)
        
        //We will only have the photos saved to disk - this index
        //file only gets saved if you call the save method on the
        //topic; encode just saves to topic to the Data type.
        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(assetIds.count, files.count)
        
        let photoFiles = files.filter {$0.pathExtension.uppercased() == "PNG"}
        XCTAssertEqual(assetIds.count, photoFiles.count)

    }
    
    func testTopicSaving() throws {
        
        let photoBrowserData = PhotoBrowserData()

        for assetId in assetIds {
            let photoItem = makePhotoItem(assetId: assetId)
            photoBrowserData.photoItems.append(photoItem)
        }
        
        let topic1 = Topic(topicName: "Animals", pageSize: .a4, orientation: .landscape, layout: .init(width: 3, height: 2), photos: photoBrowserData)
        
        
        try topic1.save(directory: tempDir)
                        
        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(assetIds.count + 1, files.count)
        //let files = FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        
        XCTAssertTrue(files.contains(where: {$0.lastPathComponent == "index.json"}))

        let photoFiles = files.filter {$0.pathExtension.uppercased() == "PNG"}
        XCTAssertEqual(assetIds.count, photoFiles.count)


        let topic2 = try Topic.load(directory: tempDir)
        XCTAssertNotNil(topic2)
        
        XCTAssertEqual(topic1.photos.photoItems.count, topic2.photos.photoItems.count)
        XCTAssertEqual(topic1.pageSize, topic2.pageSize)
        XCTAssertEqual(topic1.orientation, topic2.orientation)
        XCTAssertEqual(topic1.layout, topic2.layout)
    
    }
    
    ///Make sure we don't have leftover photos in the topic folder after we remove
    ///a photo from the photos collection
    func testTopicFileCleanup() throws {
        
        let photoBrowserData = PhotoBrowserData()

        for assetId in assetIds {
            let photoItem = makePhotoItem(assetId: assetId)
            photoBrowserData.photoItems.append(photoItem)
        }
        
        let topic1 = Topic(topicName: "Animals", pageSize: .a4, orientation: .landscape, layout: .init(width: 3, height: 2), photos: photoBrowserData)
        XCTAssertEqual(topic1.photos.photoCount, assetIds.count)
        
        try topic1.save(directory: tempDir)
                        
        let files = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(topic1.photos.photoCount + 1, files.count)
        //let files = FileManager.default.contentsOfDirectory(atPath: tempDir.path)
        
        XCTAssertTrue(files.contains(where: {$0.lastPathComponent == "index.json"}))

        let photoFiles = files.filter {$0.pathExtension.uppercased() == "PNG"}
        XCTAssertEqual(topic1.photos.photoCount, photoFiles.count)
        
        topic1.photos.removePhoto(with: assetIds.last!)
        XCTAssertEqual(topic1.photos.photoCount, assetIds.count - 1)
        
        try topic1.save(directory: tempDir)
        
        let files2 = try FileManager.default.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)
        XCTAssertEqual(topic1.photos.photoCount + 1, files2.count)

        let photoFiles2 = files2.filter {$0.pathExtension.uppercased() == "PNG"}
        XCTAssertEqual(topic1.photos.photoCount, photoFiles2.count)


    }
    
    
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

    }

}
