//
//  PhotoItem.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import UIKit

class PhotoItem : Hashable, Equatable {
    
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.image == rhs.image &&
        lhs.assetId == rhs.assetId &&
        lhs.title == rhs.title &&
        lhs.fitzgeraldKey == rhs.fitzgeraldKey
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(image.hashValue)
        hasher.combine(assetId?.hashValue)
        hasher.combine(title?.hashValue)
        hasher.combine(fitzgeraldKey.hashValue)
    }
    
    
    var image: UIImage
    var assetId: String?
    var title: String?
    var fitzgeraldKey: FitzgeraldKey = .none
    
    init(image: UIImage, assetId: String? = nil, title: String? = nil) {
        self.image = image
        self.assetId = assetId
        self.title = title
    }
    
    func copy() -> PhotoItem {
        let photoItem = PhotoItem(image: self.image, assetId: assetId, title: self.title)
        return photoItem
    }
    
}
