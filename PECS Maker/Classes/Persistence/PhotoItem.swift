//
//  PhotoItem.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import UIKit
import Photos
import LogFramework
import PersistenceFramework

class PhotoItem : Hashable, Equatable, Identifiable, Codable {

    //The reason for having == and hash use the ID is
    //because we need our Swift UI list to allow duplicate items...
    //but that's the wrong way to implement Equatable so going back
    //to the proper way.
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        //lhs.id == rhs.id
        //lhs.image == rhs.image &&
        lhs.asset == rhs.asset &&
        lhs.assetId == rhs.assetId &&
        lhs.title == rhs.title &&
        lhs.fitzgeraldKey == rhs.fitzgeraldKey
    }
    
    func hash(into hasher: inout Hasher) {
        //hasher.combine(id.hashValue)
        //hasher.combine(image)
        hasher.combine(asset)
        hasher.combine(assetId)
        hasher.combine(title)
        hasher.combine(fitzgeraldKey)
    }
    
    var id = UUID()

    lazy var image: UIImage = {
        guard let imageURL = self.imageURL else {
            //throw ImageEncoderError(message: "Unable to load image for key \(imageFileName)")
            logger.logError(.repo, "Unable to load image from because imageURL is nil")
            return UIImage()
        }
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            //throw ImageEncoderError(message: "Unable to load image for key \(imageFileName)")
            logger.logError(.repo, "Unable to load image because file does not exist at \(imageURL.path)")
            return UIImage()
        }
        do {
            guard let image = try ImageEncoder.load(from: imageURL) else {
                //throw ImageEncoderError(message: "Unable to load image for key \(imageFileName)")
                logger.logError(.repo, "Loaded empty image from \(imageURL)")
                return UIImage()
            }
            return image
        }
        catch {
            logger.logError(.repo, "Unable to load image from \(imageURL)")
            return UIImage()
        }
    }()
    
    var asset: PHAsset?
    var assetId: String?
    var title: String?
    var fitzgeraldKey: FitzgeraldKey = .none
    
    //This is nil until the file is saved/loaded to/from disk
    var imageFileName: String?
    var imageURL: URL?
    
    init(image: UIImage, asset: PHAsset? = nil, assetId: String? = nil, title: String? = nil, fitzgeraldKey: FitzgeraldKey = .none) {
        self.image = image
        if assetId == nil {
            self.assetId = asset?.localIdentifier
        }
        else {
            self.assetId = assetId
        }
        self.asset = asset
        self.title = title
        self.fitzgeraldKey = fitzgeraldKey
    }
    
    func copy() -> PhotoItem {
        let photoItem = PhotoItem(image: self.image, asset: asset, assetId: assetId, title: self.title)
        return photoItem
    }
    
    // MARK: - Codable
    
    private enum CoderKeys: String, CodingKey {
        case id, imageFileName, asset, assetId, title, fitzgeraldKey
    }
    
    public static var imageFilePrefix: String = "PhotoItem"
    
    private static func makeImageFileName(id: UUID) -> String {
        return "\(imageFilePrefix)-\(id.uuidString).png"
    }
    
    // Used for persistent storing of products to disk.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(id, forKey: .id)
        //try container.encode(asset, forKey: .asset)
        try container.encode(assetId, forKey: .assetId)
        try container.encode(title, forKey: .title)
        try container.encode(fitzgeraldKey, forKey: .fitzgeraldKey)

        //Save the image to external storage.
        imageFileName = PhotoItem.makeImageFileName(id: id)
        //try ImageEncoder.save(image: image, fileName: fileName)

        guard let baseURL = encoder.userInfo[.baseURL] as? URL else {
            let message = "JSON encoder userInfo does not contain base URL"
            logger.logError(.repo, message)
            throw ImageEncoderError(message: message)
        }
        
        let imageURL = baseURL.appendingPathComponent(imageFileName!)
        try ImageEncoder.save(image: image, to: imageURL)
        
        try container.encode(imageFileName, forKey: .imageFileName)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        //image = try values.decode(UIImage.self, forKey: .image)
        //asset = try values.decode(PHAsset.self, forKey: .asset)
        if let assetId = try? values.decode(String.self, forKey: .assetId) {
            self.assetId = assetId
            self.asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject
        }
        title = try? values.decode(String.self, forKey: .title)
        fitzgeraldKey = try values.decode(FitzgeraldKey.self, forKey: .fitzgeraldKey)
        
        imageFileName = try values.decode(String.self, forKey: .imageFileName)
        guard let imageFileName = self.imageFileName else {
            let message = "JSON does not contain a filename"
            logger.logError(.repo, message)
            throw ImageEncoderError(message: message)
        }
        
        guard let baseURL = decoder.userInfo[.baseURL] as? URL else {
            let message = "JSON decoder userInfo does not contain base URL"
            logger.logError(.repo, message)
            throw ImageEncoderError(message: message)
        }
        
        let imageURL = baseURL.appendingPathComponent(imageFileName)
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw ImageEncoderError(message: "Image \(imageFileName) does not exist at \(baseURL)")
        }
        self.imageURL = imageURL
        
    }
    
}


