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

func makeHighResolutionTestImage() -> UIImage {
    let size = CGSize(width: 4032, height: 3024)
    let format = UIGraphicsImageRendererFormat()
    format.opaque = true
    format.scale = 1

    return UIGraphicsImageRenderer(size: size, format: format).image { context in
        UIColor.systemBlue.setFill()
        context.fill(CGRect(origin: .zero, size: size))

        UIColor.systemYellow.setFill()
        for offset in stride(from: 0, to: Int(size.width), by: 256) {
            context.fill(CGRect(x: offset, y: 0, width: 128, height: Int(size.height)))
        }
    }
}

class PersistenceTestsBase: XCTestCase {
    
    var tempDir: URL!
    var repoFactory = RepoFactory<PECSRepo>()
    
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

    func loadImageAsset(assetId: String) -> UIImage? {
        if assetId == largePhotoAssetId {
            return makeHighResolutionTestImage()
        }

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
