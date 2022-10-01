//
//  PhotoItem.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import UIKit
import Photos

class PhotoItem : Hashable, Equatable, Identifiable, Codable {

    //The reason for having == and hash use the ID is
    //because we need our Swift UI list to allow duplicate items
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }
    
    var id = UUID()
    var image: UIImage
    var asset: PHAsset?
    var assetId: String?
    var title: String?
    var fitzgeraldKey: FitzgeraldKey = .none
    
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
        case id, image, asset, assetId, title, fitzgeraldKey
    }
    
    private static func makeImageFileName(id: UUID, forKey key: String) -> String {
        return "\(id.uuidString)-\(key).png"
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
        let fileName: String = PhotoItem.makeImageFileName(id: id, forKey: CoderKeys.image.rawValue)
        try ImageEncoder().save(image: image, fileName: fileName)
        
        try container.encode(fileName, forKey: .image)
        
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        //image = try values.decode(UIImage.self, forKey: .image)
        //asset = try values.decode(PHAsset.self, forKey: .asset)
        assetId = try values.decode(String.self, forKey: .assetId)
        title = try values.decode(String.self, forKey: .title)
        fitzgeraldKey = try values.decode(FitzgeraldKey.self, forKey: .fitzgeraldKey)
        
        let fileName: String = try values.decode(String.self, forKey: .image)
        guard let image = try ImageEncoder().load(fileName: fileName) else {
            throw ImageEncoderError(message: "Unable to load image for key \(fileName)")
        }
        self.image = image
    }
    
}


