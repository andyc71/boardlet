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

class PhotoBrowserData : ObservableObject, Codable {
    
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

    // MARK: - Codable
    
    private enum CoderKeys: String, CodingKey {
        case photoItems
    }
    
    // Used for persistent storing of products to disk.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(_photoItems, forKey: .photoItems)
        
        guard let baseURL = encoder.userInfo[.baseURL] as? URL else {
            let message = "JSON encoder userInfo does not contain base URL"
            logger.logError(.repo, message)
            throw ImageEncoderError(message: message)
        }
        
        var expectedFiles = [String]()
        for photoItem in photoItems {
            if let photoFile = photoItem.fileName {
                expectedFiles.append(photoFile)
            }
        }
        
        let filesInBaseURL = try FileManager.default.contentsOfDirectory(atPath: baseURL.path)
        for fileOnDisk in filesInBaseURL {
            let fileURL = baseURL.appendingPathComponent(fileOnDisk)
            if fileURL.pathExtension.uppercased() != "PNG" {
                continue
            }
            if !expectedFiles.contains(fileOnDisk) {
                try FileManager.default.removeItem(at: fileURL)
            }
        }
        
        

    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        _photoItems = try values.decode([PhotoItem].self, forKey: .photoItems)
    }
}
