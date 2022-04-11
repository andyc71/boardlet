//
//  SetupPhotos.swift
//  PECS Maker
//
//  Created by Andy on 26/03/2022.
//

import Foundation

import XCTest
import Photos
import MediaCore
import Carpaccio

class SetupPhotos: XCTestCase {
    
    override func setUpWithError() throws {
#if !targetEnvironment(simulator)
        XCTFail("Only run this on the simulator because it will delete photos")
        return
#endif
    }
    
    func testDeleteAllPhotos() {
        deleteAllPhotos()
    }
    
    func testAddPhotos() {
//        Task {
//            await setupPhotoLibrary()
//        }
        
        
        setupPhotoLibrary2()
        
    }
    
    
    func setupPhotoLibrary2() {
        

        //Note the photos must be typed as "Data", otherwise XCode will do some image processing on
        //them and lose the EXIF data.
                let photoNames = [
                    "001-apple.png",
                    "016-pear.png",
                    "015-peach.png",
                    "012-lemon.png",
                    "023-strawberry.png",
                    "009-grapes.png",
                    "017-pineapple.png",
                    "003-banana.png",
                    "005-cherry.png",
                ]
                
                let bundle = Bundle(for: type(of: self))
                
                for photoName in photoNames {
                    guard let imageFromBundle = UIImage(named: photoName, in: bundle, with: nil) else {
                        XCTFail("Unable image for \(photoName)")
                        //continuation.resume(returning: false)
                        return
                    }
                    
                    guard let imageURL = bundle.url(forResource: photoName, withExtension: "") else {
                        XCTFail("Unable image for \(photoName)")
                        //continuation.resume(returning: false)
                        return
                    }

                    let loader = ImageLoader(imageURL: imageURL, thumbnailScheme: ImageLoader.ThumbnailScheme.decodeFullImage)
                    let (image, imageMetadata) = try! loader.loadBitmapImage(maximumPixelDimensions: nil, colorSpace: nil, allowCropping: true, cancelled: nil)
                    print(imageMetadata.cameraMaker)
                    
                }
    }
    
    
    func deleteAllPhotos() {
        
        let allPhotos = Media.Photos.all
        if allPhotos.count > 30 {
            XCTFail("Too many photos to delete")
            
            return
        }
        
        
        let bundle = Bundle(for: type(of: self))
        //print(bundle.bundlePath)
        
        var bundleURL = bundle.bundleURL
        
        var foundDataFolder = false
        while(!foundDataFolder) {
            if bundleURL.lastPathComponent == "data" {
                foundDataFolder = true
                break
            }
            bundleURL.deleteLastPathComponent()
        }
        var isOK = false
        if foundDataFolder {
            var checkURL = bundleURL
            checkURL.deleteLastPathComponent()
            checkURL.deleteLastPathComponent()
            if checkURL.lastPathComponent == "Devices" {
                isOK = true
            }
        }
        
        if isOK {
            let mediaFolder = bundleURL.appendingPathComponent("Media")
            let dcimFolder = mediaFolder.appendingPathComponent("DCIM")
            let photoDataFolder = mediaFolder.appendingPathComponent("PhotoData")
            
            do {
                if FileManager.default.fileExists(atPath: dcimFolder.path) {
                    try FileManager.default.removeItem(at: dcimFolder)
                }
                if FileManager.default.fileExists(atPath: photoDataFolder.path) {
                    try FileManager.default.removeItem(at: photoDataFolder)
                }
            }
            catch {
                print("Failed to remove photo folder. \(error.localizedDescription)")
            }
        }
        
    }
    
    func setupPhotoLibrary() async  -> Bool {
        
        //        if alertHandler == nil {
        //            alertHandler = addUIInterruptionMonitor(withDescription: "alert handler") { (alert: XCUIElement) -> Bool in
        //                print("alert label => \(alert.label)")
        //                print("alert => \(alert)")
        //                alert.buttons["Delete"].tap()
        //                return false
        //            }
        //        }
        
        return  await withCheckedContinuation { continuation in
            
            Media.requestPermission { _ in
                
                if Media.currentPermission !=  PHAuthorizationStatus.authorized {
                    XCTFail("Not authorized to access media library")
                    continuation.resume(returning: false)
                    return
                }
                
                //Media.Photos.all[]
                
                //Media.Photos.
                
                //let photoNamesAndDates = "001-apple.png"
                //                let photoNamesAndDates : [String: Date] = [
                //                    "001-apple.png" : Date(),
                //                    "016-pear.png" : Date(),
                //                    "015-peach.png" : Date(),
                //                    "012-lemon.png" : Date(),
                //                    "023-strawberry.png" : Date(),
                //                    "009-grapes.png" : Date(),
                //                    "017-pineapple.png" : Date(),
                //                    "017-banana.png" : Date(),
                //                    "005-cherry.png" : Date(),
                //                ]
                
                let photoNames = [
                    "001-apple.png",
                    "016-pear.png",
                    "015-peach.png",
                    "012-lemon.png",
                    "023-strawberry.png",
                    "009-grapes.png",
                    "017-pineapple.png",
                    "003-banana.png",
                    "005-cherry.png",
                ]
                
                let bundle = Bundle(for: type(of: self))
                
                for photoName in photoNames {
                    guard let imageFromBundle = UIImage(named: photoName, in: bundle, with: nil) else {
                        XCTFail("Unable image for \(photoName)")
                        continuation.resume(returning: false)
                        return
                    }
                    
                    guard let imageURL = bundle.url(forResource: photoName, withExtension: "") else {
                        XCTFail("Unable image for \(photoName)")
                        continuation.resume(returning: false)
                        return
                    }

                    let loader = ImageLoader(imageURL: imageURL, thumbnailScheme: ImageLoader.ThumbnailScheme.decodeEmbeddedThumbnail)
                    let (thumb, imageMetadata) = try! loader.loadBitmapImage(maximumPixelDimensions: nil, colorSpace: nil, allowCropping: true, cancelled: nil)
                    print(imageMetadata.cameraMaker)
                    
                    do {
                        
                        Photo.save(imageFromBundle) { result in
                            print("Done")
                        }
                    }
                    catch {
                        XCTFail("Failed to add photo \(photoName). \(error.localizedDescription)")
                        continuation.resume(returning: false)
                        return
                    }
                }
                continuation.resume(returning: true)
                
            }
            
            
        }
        
        
    }
    
}
