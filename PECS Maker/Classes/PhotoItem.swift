//
//  PhotoItem.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import UIKit

class PhotoItem : Identifiable {
    
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
