//
//  PersistenceTestsBase.swift
//  PersistenceTestsBase
//
//  Created by Andy on 24/09/2021.
//

import XCTest
import PersistenceFramework
@testable import PECS_Maker
import SwiftUI

class PersistenceTestsBase: XCTestCase {
    
    var tempDir: URL!
    var repoFactory = RepoFactory<PECSRepo>()
    
    let largePhotoAssetId = "IMG_0940.DNG"
    
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

    func loadImageAsset(assetId: String) -> UIImage? {
        let imageFileName = "\(assetId).png"
        let image = UIImage(named: imageFileName, in: Bundle(for: type(of: self)), compatibleWith: nil)
        XCTAssertNotNil(image)
        XCTAssert(image!.size.width > 0 && image!.size.height > 0)
        return image
    }

    func makePhotoItem(assetId: String) -> PhotoItem {
        let image = loadImageAsset(assetId: assetId)
        
        //Create the photo item
        let title = String(assetId[assetId.index(assetId.startIndex, offsetBy: 4)...])
        //let title = assetId.dropFirst(4)
        let fitzgeraldKey = FitzgeraldKey.noun
        let photoItem = PhotoItem(image: image!, asset: nil, assetId: assetId, title: title, fitzgeraldKey: fitzgeraldKey)
        
        return photoItem
    }

}
