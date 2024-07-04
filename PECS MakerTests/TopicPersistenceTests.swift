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
        format1.labelBoldFont = true
        format1.labelColor = Color.yellow
        format1.labelPosition = .bottom
        format1.labelHeightPercentage = 0.2
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
        XCTAssertEqual(format1.labelColor.getHex(), format2.labelColor.getHex())
        XCTAssertEqual(format1.labelPosition, format2.labelPosition)
        XCTAssertEqual(format1.labelHeightPercentage, format2.labelHeightPercentage)
        XCTAssertEqual(format1.labelBoldFont, format2.labelBoldFont)
        
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
