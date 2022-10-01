//
//  PersistenceTests.swift
//  PersistenceTests
//
//  Created by Andy on 24/09/2021.
//

import XCTest
@testable import PECS_Maker

class PersistenceTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    var assetIds = ["001-apple", "002-avocado", "003-banana", "004-blueberry", "005-cherry"]
    
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
        let data = try encoder.encode(photoItem1)
        
        //Re-load the item
        let decoder = JSONDecoder()
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
        let data = try encoder.encode(photoBrowserData1)
        
        //Re-load the item
        let decoder = JSONDecoder()
        let photoBrowserData2 = try decoder.decode(PhotoBrowserData.self, from: data)
                
        XCTAssertNotNil(photoBrowserData2)
        
        XCTAssertEqual(photoBrowserData1.photoItems.count, photoBrowserData2.photoItems.count)
        
    }

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
        let data = try encoder.encode(pageLayoutState1)
        
        //Re-load the item
        let decoder = JSONDecoder()
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

}
