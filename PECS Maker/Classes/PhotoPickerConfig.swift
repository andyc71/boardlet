//
//  PhotoPickerConfig.swift
//  PECS Maker
//
//  Created by Andy on 29/09/2021.
//

import Foundation
import PhotosUI

//let pickerPattern: PickerPattern = .any(of: [.images, .videos, .livePhotos])
let photoPickerPattern: PickerPattern = .any(of: [.images, .livePhotos])

let photoPickerConfig: PHPickerConfiguration = {
    var config = PHPickerConfiguration()
    config.filter = photoPickerPattern.filter
    config.selectionLimit = 0
    config.preferredAssetRepresentationMode = .current // required for video
    return config
}()


