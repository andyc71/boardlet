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
            imageNeedsSave = true
            needsSave = true
        }
    }

    private var imageNeedsSave = true
    
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
        self.imageFileName = Self.makeImageFileName(id: itemID)
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
    
    static func makeImageFileName(id: UUID) -> String {
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
        
        let persistedImageFileName = imageFileName ?? Self.makeImageFileName(id: itemID)
        try container.encode(persistedImageFileName, forKey: .imageFileName)
        
        try container.encode(audioFileName, forKey: .audioFileName)
        
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
        guard self.imageFileName != nil else {
            let message = "JSON does not contain a filename"
            logger.logError(.repo, message)
            throw PhotoItemError(message: message)
        }
        
        audioFileName = try values.decodeIfPresent(String.self, forKey: .audioFileName)
        
        self.needsSave = false
        self.imageNeedsSave = false
        
    }
    
    
    func save(to fileURL: URL) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let imageFileName = self.imageFileName ?? Self.makeImageFileName(id: itemID)
        self.imageFileName = imageFileName
        let imageURL = directory.appendingPathComponent(imageFileName)
        if imageNeedsSave || !FileManager.default.fileExists(atPath: imageURL.path) {
            try ImageEncoder.save(image: image, to: imageURL, format: .png)
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let encoded = try encoder.encode(self)
            try encoded.write(to: fileURL, options: .atomic)
            didPersist(to: directory)
        } catch {
            let message = "Could not save PhotoItem to \(fileURL.path)"
            logger.logError(.repo, message, error)
            throw PhotoItemError(message: message)
        }
    }
    
    
    static func load(from fileURL: URL) throws -> Self {
        let codedData = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        do {
            let decoded = try decoder.decode(Self.self, from: codedData)
            try decoded.bindAssets(to: fileURL.deletingLastPathComponent())
            return decoded
        }
        catch{
            let message = "Could not load PhotoItem from \(fileURL.path)"
            throw PhotoItemError(message: message)
        }
    }

    func bindAssets(to directory: URL) throws {
        let imageFileName = imageFileName ?? Self.makeImageFileName(id: itemID)
        let imageURL = directory.appendingPathComponent(imageFileName)
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw PhotoItemError(message: "Image \(imageFileName) does not exist at \(directory.path)")
        }
        self.imageFileName = imageFileName
        self.imageURL = imageURL

        if let audioFileName {
            let audioURL = directory.appendingPathComponent(audioFileName)
            guard FileManager.default.fileExists(atPath: audioURL.path) else {
                throw PhotoItemError(message: "Audio \(audioFileName) does not exist at \(directory.path)")
            }
            self.audioURL = audioURL
        }
    }

    func persistenceAssets() throws -> [String: Data] {
        let imageFileName = imageFileName ?? Self.makeImageFileName(id: itemID)
        guard let imageData = image.pngData() else {
            throw PhotoItemError(message: "Could not encode image \(imageFileName)")
        }

        var assets = [imageFileName: imageData]
        if let audioFileName, let audioURL {
            assets[audioFileName] = try Data(contentsOf: audioURL)
        }
        return assets
    }

    func didPersist(to directory: URL) {
        let imageFileName = imageFileName ?? Self.makeImageFileName(id: itemID)
        self.imageFileName = imageFileName
        imageURL = directory.appendingPathComponent(imageFileName)
        if let audioFileName {
            audioURL = directory.appendingPathComponent(audioFileName)
        }
        imageNeedsSave = false
        needsSave = false
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
