//
//  ScreenshotTopicsScreenTests.swift
//  PECS ScreenshotTopicsScreenTests
//
//  Created by Andy on 10/01/2023.
//

import XCTest

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }
}

class ScreenshotTopicsScreenTests: PECSTestsBase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func setLaunchArguments() {
        super.setLaunchArguments()

        copySampleTopics()

    }
    
    var screenshotName: String {
        ScreenshotNames.topicsScreen
    }
    
    func getFileResourceUrl(resourceName: String, ofType: String) -> URL? {
        
        let testBundle = Bundle(for: type(of: self))
        guard let resourcePath = testBundle.path(forResource: resourceName, ofType: ofType) else {
            XCTFail("Failed to load index file as asset")
            return nil
        }
        return URL(fileURLWithPath: resourcePath)
    }

    func getJSONIndexFileResourceUrl(resourceName: String) -> URL? {
        
        return getFileResourceUrl(resourceName: resourceName, ofType: "json")
    }
    
    func isDirectory(at path: String) -> Bool {
        let fileManager = FileManager.default
        var isDir : ObjCBool = false
        let exists = fileManager.fileExists(atPath: path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }
    
    //Checks sourceFileName for a languange prefix (e.g. "EN_") and compares
    //that with the language in use. If they match, it returns the filename,
    //without that prefix, appended to targetDirectory. If they don't match
    //then it returns nil. If there is no prefix it appends the entire
    //filename to targetDirectory.
    func handlLocalization(sourceFile: String, targetDirectory: URL) -> URL? {
        if sourceFile.starts(with: "EN_") {
            if isSpanish {
                return nil
            }
            else {
                return  targetDirectory.appendingPathComponent(sourceFile.deletingPrefix("EN_"))
            }
        }
        else if sourceFile.starts(with: "ES_") {
            if !isSpanish {
                return nil
            }
            else {
                return targetDirectory.appendingPathComponent(sourceFile.deletingPrefix("ES_"))
            }
        }
        else {
            return targetDirectory.appendingPathComponent(sourceFile)
        }
    }
    
    func copyDirectoryContents(_ sourceDirectory: URL, to targetDirectory: URL) throws {
        
        let fileManager = FileManager.default
        try fileManager.createDirectory(atPath: targetDirectory.path, withIntermediateDirectories: true)
        
        let sourceFiles = try fileManager.contentsOfDirectory(atPath: sourceDirectory.path)
        
        for sourceFile in sourceFiles {
            let sourceURL = sourceDirectory.appendingPathComponent(sourceFile)
            
            guard let targetURL = handlLocalization(sourceFile: sourceFile, targetDirectory: targetDirectory) else {
                continue
            }
            
            if isDirectory(at: sourceURL.path) {
                try copyDirectoryContents(sourceURL, to: targetURL)
            }
            else {
                try fileManager.copyItem(at: sourceURL, to: targetURL)
            }
        }
        
    }
    
    func copySampleTopics() {
        
        let testBundle = Bundle(for: type(of: self))
        guard let topicsPathInTestBundle = testBundle.resourceURL?.appendingPathComponent("topics") else {
            XCTFail("Could not generate url for topics folder")
            return
        }

        do {
            try copyDirectoryContents(topicsPathInTestBundle, to: tempDir.appendingPathComponent("topics"))
        }
        catch {
            XCTFail("Unable to copy sample topics: \(error.localizedDescription)")
        }
                        
    }

    @MainActor func testPopulatedTopicScreen() throws {
        
        //If we change the topic images (e.g. the fruits) then we need
        //top update the topic file and topic thumbnail. A better option
        //in future would be to create the topic from scratch, which we
        //are almost already doing.
        
        //We should already be on the topics screen.
        //navigateToTopicScreenFromMainMenu()
        
        snapshotIfNeeded(screenshotName)
    }

    
}
