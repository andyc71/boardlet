//
//  PersistenceTests.swift
//  PersistenceTests
//
//  Created by Andy on 24/09/2021.
//

import XCTest
@testable import PECS_Maker
import SwiftUI

class PersistenceTests: XCTestCase {

    var tempDir: URL!
    
    let largePhotoAssetId = "generated-high-resolution-photo"
    
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
        let image: UIImage?
        if assetId == largePhotoAssetId {
            image = makeHighResolutionTestImage()
        } else {
            let imageFileName = "\(assetId).png"
            image = UIImage(named: imageFileName, in: Bundle(for: type(of: self)), compatibleWith: nil)
        }
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

    func testLargePhotoItemEncoding() throws {
        //Load an image to use in the PhotoItem to be persisted
        let assetId: String = largePhotoAssetId
        try encodeAndDecodePhoto(assetId)
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
        XCTAssertEqual(format1.cardTitleFontHeightPercentage, format2.cardTitleFontHeightPercentage)
        XCTAssertEqual(format1.cardTitlePosition, format2.cardTitlePosition)
        
        XCTAssertEqual(format1, format2)
        
        //Make a change and ensure that they don't match.
        format1.marginPercentage += 1.0
        XCTAssertNotEqual(format1, format2)
        
    }

    /* Obsolete as we now encode topics, not PLS
    func testPageLayoutStateEncoding() throws {
        
        let photoBrowserData = PhotoBrowserData()

        for assetId in assetIds {
            let photoItem = makePhotoItem(assetId: assetId)
            photoBrowserData.photoItems.append(photoItem)
        }
        
        let pageLayoutState1 = PageLayoutState()
        pageLayoutState1.photoBrowserData = photoBrowserData
        
        
        //Save the item
        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = tempDir
        let data = try encoder.encode(pageLayoutState1)
        
        //Re-load the item
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = tempDir
        let pageLayoutState2 = try decoder.decode(PageLayoutState.self, from: data)
                
        XCTAssertNotNil(pageLayoutState2)
        
        XCTAssertEqual(pageLayoutState1.photoBrowserData.photoItems.count, pageLayoutState2.photoBrowserData.photoItems.count)
        
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
        let folderName = "My Creation"
        try pageLayoutState1.save(folderName: folderName)
        
        //Re-load the item
        //let pageLayoutState2 = try PageLayoutState(folderName: folderName)
        let pageLayoutState2 = PageLayoutState()
        try pageLayoutState2.load(folderName: folderName)
                
        XCTAssertEqual(pageLayoutState1.photoBrowserData.photoItems.count, pageLayoutState2.photoBrowserData.photoItems.count)
        
    }
     */

}
