//
//  PhotoBrowserData.swift
//  PECS Maker
//
//  Created by Andy on 31/07/2022.
//

import UIKit
import Combine
import SwiftUI
import PDFKit
import LogFramework
import YPImagePicker
import Photos
import PersistenceFramework

class PhotoBrowserData : ObservableObject, Codable, Hashable {
    
    static func == (lhs: PhotoBrowserData, rhs: PhotoBrowserData) -> Bool {
        if lhs.photoItems.count != rhs.photoItems.count {
            return false
        }
        for i in 0..<lhs.photoItems.count {
            if lhs.photoItems[i] != rhs.photoItems[i] {
                return false
            }
        }
        return true
    }

    func hash(into hasher: inout Hasher) {
        for photo in photoItems {
            hasher.combine(photo.hashValue)
        }
    }
    
    @Published var stockData: [_PhotoPickerData] = []
    
    @Published var ypData: [YPMediaItem] = [] {
        didSet {
            objectWillChange.send()
        }
    }

    @Published var images: [UIImage] = [] {
        didSet {
            objectWillChange.send()
        }
    }
    
    var photoCount : Int {
        get {
            return photoItems.count
        }
    }
    
    func removeAll() {
        photoItems = []
        
    }
    
    var _photoItems: [PhotoItem]?
    
    var photoItems: [PhotoItem] {
        get {
            if let ps = _photoItems {
                return ps
            }
            else if stockData.count > 0 {
                return createPhotoItemArray(from: stockData)
            }
            else {
                return createPhotoItemArray(from: ypData)
            }
        }
        set {
            self._photoItems = newValue
            self.objectWillChange.send()
        }
    }
    
    var photoAssets: [PHAsset] {
        get {
            let assets = photoItems.compactMap( {$0.asset } )
            return assets
        }
    }
    
    init() {
    }
    
    func copy(from other: PhotoBrowserData) {
        self.photoItems = other.photoItems
    }
    
    func add(photo: PhotoItem) {
        //Needs to be a copy so it gets a unique ID
        self.photoItems.append(photo.copy())
        self.objectWillChange.send()
    }

    func add(_ photosToCopy: [PhotoItem]) {
        var photosLocal = photoItems

        for photo in photosToCopy {
            //Needs to be a copy so it gets a unique ID
            let photoCopy = photo.copy()
            photosLocal.append(photoCopy)
        }
        
        self.photoItems = photosLocal
        //DispatchQueue.main.async {
            self.objectWillChange.send()
        //}
        
    }


    private func createPhotoItemArray(from photoData: [PhotoPickerData?]) -> [PhotoItem] {
            var photoItems = [PhotoItem]()
            for data in photoData {
                if let image = data?.image {
                    photoItems.append(PhotoItem(image: image, assetId: data?.assetIdentifier))
                }
            }
            return photoItems
    }
    
    private func createPhotoItemArray(from ypData: [YPMediaItem]) -> [PhotoItem] {
        var photoItems = [PhotoItem]()
        for data in ypData {
            switch data {
            case .photo(let photo):
                photoItems.append(PhotoItem(image: photo.image, assetId: photo.asset?.localIdentifier))
            case .video(_):
                continue
            }
        }
        return photoItems
    }
    
    func removePhoto(with assetID: String) {
        stockData.removeAll(where: {$0.assetIdentifier == assetID})

        ypData.removeAll(where: {
            switch $0 {
            case .photo(let photo):
                return photo.asset?.localIdentifier == assetID
            case .video(let video):
                return video.asset?.localIdentifier == assetID
            }
        })
        
        _photoItems?.removeAll(where: {$0.assetId == assetID})

    }
    
    
    
    func deletePhotos(_ photosToDelete: [PhotoItem]) {
        var photosLocal = photoItems
        for photo in photosToDelete {
            photosLocal.removeAll { $0.id == photo.id }
        }
        DispatchQueue.main.async {
            self.photoItems = photosLocal
            self.objectWillChange.send()
        }
    }
    
    func deletePhoto(at index: Int) {
        guard index < photoItems.count else {
            return
        }
        var photosLocal = photoItems
        photosLocal.remove(at: index)
        
        DispatchQueue.main.async {
            self.photoItems = photosLocal
            self.objectWillChange.send()
        }
    }
    
    func duplicatePhoto(at index: Int) {
        guard index < photoItems.count else {
            return
        }
        var photosCopy = photoItems
        
        //Needs to be a copy so it gets a unique ID
        let photoCopy = photosCopy[index].copy()
        
        photosCopy.insert(photoCopy, at: index + 1)
        DispatchQueue.main.async {
            self.photoItems = photosCopy
            self.objectWillChange.send()
        }
    }
    
    func duplicatePhotos(_ photosToDuplicate: [PhotoItem]) {

        var photosLocal = photoItems

        for photo in photosToDuplicate {
            //Needs to be a copy so it gets a unique ID
            let photoCopy = photo.copy()
            photosLocal.append(photoCopy)
        }
        
        DispatchQueue.main.async {
            self.photoItems = photosLocal
            self.objectWillChange.send()
        }
    }

    // MARK: - Codable
    
    private enum CoderKeys: String, CodingKey {
        case photoItems
    }
    
    // Used for persistent storing of products to disk.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encodeIfPresent(_photoItems, forKey: .photoItems)
        
        guard let baseURL = encoder.userInfo[.baseURL] as? URL else {
            let message = "JSON encoder userInfo does not contain base URL"
            logger.logError(.repo, message)
            throw ImageEncoderError(message: message)
        }
        
        var expectedFiles = [String]()
        for photoItem in photoItems {
            if let photoFile = photoItem.imageFileName {
                expectedFiles.append(photoFile)
            }
        }
        
        let filesInBaseURL = try FileManager.default.contentsOfDirectory(atPath: baseURL.path)
        for fileOnDisk in filesInBaseURL {
            let fileURL = baseURL.appendingPathComponent(fileOnDisk)
            if fileURL.pathExtension.uppercased() != "PNG" {
                continue
            }
            if !fileURL.lastPathComponent.starts(with: PhotoItem.imageFilePrefix) {
                continue
            }
            if !expectedFiles.contains(fileOnDisk) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
        
        

    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        _photoItems = try values.decodeIfPresent([PhotoItem].self, forKey: .photoItems)
    }
}
