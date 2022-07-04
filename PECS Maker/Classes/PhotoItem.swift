//
//  PhotoItem.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import UIKit
import Photos

class PhotoItem : Hashable, Equatable, Identifiable {

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
    
    init(image: UIImage, asset: PHAsset? = nil, assetId: String? = nil, title: String? = nil) {
        self.image = image
        if assetId == nil {
            self.assetId = asset?.localIdentifier
        }
        else {
            self.assetId = assetId
        }
        self.asset = asset
        self.title = title
    }
    
    func copy() -> PhotoItem {
        let photoItem = PhotoItem(image: self.image, asset: asset, assetId: assetId, title: self.title)
        return photoItem
    }
    
}
