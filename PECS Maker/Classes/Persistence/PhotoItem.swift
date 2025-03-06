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
import SharedSwiftUI

public struct PhotoItemError : Error {
    public var message: String
    public init(message: String) {
        self.message = message
    }
}

class PhotoItem : Hashable, Equatable, Identifiable, Codable {
    
    //The reason for having == and hash use the ID is
    //because we need our Swift UI list to allow duplicate items...
    //but that's the wrong way to implement Equatable so going back
    //to the proper way.
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        //lhs.id == rhs.id
        //lhs.image.hashValue == rhs.image.hashValue &&
        //If we have an assetID, use it for the comparison rather than
        //comparing the actual image becuase that's more processor intensive.
        if lhs.assetId != nil {
            if lhs.assetId != rhs.assetId {
                return false
            }
        }
        else {
            if lhs.image.pngData() != rhs.image.pngData() {
                return false
            }
        }
        if lhs.assetId != rhs.assetId {
            return false
        }
        if lhs.title != rhs.title {
            return false
        }
        if lhs.fitzgeraldKey != rhs.fitzgeraldKey {
            return false
        }
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        //hasher.combine(id.hashValue)
        //hasher.combine(image.hashValue)
        //hasher.combine(asset)
        hasher.combine(assetId)
        hasher.combine(title)
        hasher.combine(fitzgeraldKey)
    }
    
    var itemID = UUID()
    
    lazy var image: UIImage = loadImage() {
        didSet {
            needsSave = true
        }
    }
    
    private func loadImage() -> UIImage {
        
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
    }
    
    var asset: PHAsset?
    var assetId: String?
    
    @Published var title: String? {
        didSet { needsSave = true }
    }
    var fitzgeraldKey: FitzgeraldKey
    var needsSave: Bool
    
    //This is nil until the file is saved/loaded to/from disk
    var imageFileName: String?
    var imageURL: URL?
    
    //This is nil until the file is saved/loaded to/from disk
    var audioFileName: String?
    var audioURL: URL?
    
    init(image: UIImage, asset: PHAsset? = nil, assetId: String? = nil, title: String? = nil, fitzgeraldKey: FitzgeraldKey = .none) {
        self.needsSave = true
        self.fitzgeraldKey = fitzgeraldKey
        self.image = image
        if assetId == nil {
            self.assetId = asset?.localIdentifier
        }
        else {
            self.assetId = assetId
        }
        self.asset = asset
        self.title = title
        //print("image init: id = \(itemID)")
    }
    
    func copy() -> PhotoItem {
        let photoItem = PhotoItem(image: self.image, asset: asset, assetId: assetId, title: self.title)
        return photoItem
    }
    
    // MARK: - Codable
    
    private enum CoderKeys: String, CodingKey {
        case id, imageFileName, audioFileName, asset, assetId, title, fitzgeraldKey
    }
    
    public static var imageFilePrefix: String = "PhotoItem"
    
    private static func makeImageFileName(id: UUID) -> String {
        return "\(imageFilePrefix)-\(id.uuidString).png"
    }
    
    public static func isPhotoItem(at fileURL: URL) -> Bool {
        let pathExtension = fileURL.pathExtension.lowercased()
        if  pathExtension != "png" && pathExtension != "jpg" {
            return false
        }
        if !fileURL.lastPathComponent.starts(with: imageFilePrefix) {
            return false
        }
        return true
    }
    
    
    // Used for persistent storing of products to disk.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(itemID, forKey: .id)
        //try container.encode(asset, forKey: .asset)
        try container.encode(assetId, forKey: .assetId)
        try container.encode(title, forKey: .title)
        try container.encode(fitzgeraldKey, forKey: .fitzgeraldKey)
        
        //Save the image to external storage.
        imageFileName = PhotoItem.makeImageFileName(id: itemID)
        //try ImageEncoder.save(image: image, fileName: fileName)
        
        guard let baseURL = encoder.userInfo[.baseURL] as? URL else {
            let message = "JSON encoder userInfo does not contain base URL"
            logger.logError(.repo, message)
            throw PhotoItemError(message: message)
        }
        
        try container.encode(imageFileName, forKey: .imageFileName)
        
        try container.encode(audioFileName, forKey: .audioFileName)
        
        if needsSave {
            let imageURL = baseURL.appendingPathComponent(imageFileName!)
            try ImageEncoder.save(image: image, to: imageURL, format: .png)
            needsSave = false
        }
        
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        itemID = try values.decode(UUID.self, forKey: .id)
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
            throw PhotoItemError(message: message)
        }
        
        audioFileName = try values.decodeIfPresent(String.self, forKey: .audioFileName)
        
        guard let baseURL = decoder.userInfo[.baseURL] as? URL else {
            let message = "JSON decoder userInfo does not contain base URL"
            logger.logError(.repo, message)
            throw PhotoItemError(message: message)
        }
        
        let imageURL = baseURL.appendingPathComponent(imageFileName)
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw PhotoItemError(message: "Image \(imageFileName) does not exist at \(baseURL)")
        }
        self.imageURL = imageURL
        
        if let audioFileName = audioFileName {
            let audioURL = baseURL.appendingPathComponent(audioFileName)
            guard FileManager.default.fileExists(atPath: audioURL.path) else {
                throw PhotoItemError(message: "Audio \(audioFileName) does not exist at \(baseURL)")
            }
            self.audioURL = audioURL
        }
        

        self.needsSave = false
        
    }
    
    
    func save(to fileURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.userInfo[.baseURL] = fileURL.deletingLastPathComponent()
        
        do {
            let encoded = try encoder.encode(self)
            try encoded.write(to: fileURL)
        } catch {
            let message = "Could not save PhotoItem to \(fileURL.path)"
            logger.logError(.repo, message, error)
            throw PhotoItemError(message: message)
        }
    }
    
    
    static func load(from fileURL: URL) throws -> Self {
        let codedData = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = fileURL.deletingLastPathComponent()
        do {
            let decoded = try decoder.decode(Self.self, from: codedData)
            return decoded
        }
        catch{
            let message = "Could not load PhotoItem from \(fileURL.path)"
            throw PhotoItemError(message: message)
        }
    }
    
}
 
extension PhotoItem : ImagePickerItem {
    
    var id: String { itemID.uuidString }
    var debugInfo: [String]? { return nil }

    func loadImage(size: CGSize) -> UIImage {
        //print("loadImage: id = \(itemID)")
        return image
    }
    
}


