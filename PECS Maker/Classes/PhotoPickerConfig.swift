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
    let photoLibrary = PHPhotoLibrary.shared()
    var config = PHPickerConfiguration(photoLibrary: photoLibrary)
                        
    config.filter = photoPickerPattern.filter
    config.selectionLimit = AppSettings.maxSelectionsInPhotoPicker
    config.preferredAssetRepresentationMode = .current // required for video
    return config
}()


