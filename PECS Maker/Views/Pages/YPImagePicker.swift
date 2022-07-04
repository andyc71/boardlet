//
//  ImagePickerYP.swift
//  PECS Maker
//
//  Created by Andy on 02/07/2022.
//

import SwiftUI
import YPImagePicker
import PhotosUI
import LogFramework

struct YPImagePickerWrapper: UIViewControllerRepresentable {
    
    @Binding
    public var photos: PhotoBrowserData


    private var configuration: PHPickerConfiguration

    private let pattern: PickerPattern
    
    @Environment(\.presentationMode)
    private var presentationMode

    
    public init(
        photos: Binding<PhotoBrowserData>,
        configuration: PHPickerConfiguration,
        pattern: PickerPattern
    )
    {
        self._photos = photos

        self.configuration = configuration
                
        self.pattern = pattern
        MFAnalytics.logScreenView(screenName: "PhotoPicker")
    }

    
    func makeUIViewController(context: Context) -> YPImagePicker {
        
        var config = YPImagePickerConfiguration()
        config.showsPhotoFilters = false
        config.startOnScreen = .library
        config.screens = [.library, .photo]
        config.library.maxNumberOfItems = self.configuration.selectionLimit
        config.library.defaultMultipleSelection = true
        config.library.skipSelectionsGallery = true
        config.library.preSelectItemOnMultipleSelection = false
        //config.showsCrop = .
        
        config.library.preselectedItems = self.photos.ypData
        
        
        let picker = YPImagePicker(configuration: config)
        
        picker.didFinishPicking { [unowned picker] (items: [YPMediaItem], _) in

            
            //            if let photo = items.singlePhoto {
//                print(photo.fromCamera) // Image source (camera or library)
//                print(photo.image) // Final image selected by the user
//                print(photo.originalImage) // original image selected by the user, unfiltered
//                print(photo.modifiedImage ?? "not modified !") // Transformed image, can be nil
//                print(photo.exifMeta ?? "no exif metadata") // Print exif meta data of original image."
//            }
            
            
            picker.dismiss(animated: true, completion: nil)
            
            DispatchQueue.main.async {
                self.photos.ypData = items
                self.presentationMode.wrappedValue.dismiss()
            }

            
        }
    
        return picker
    }
    
    func updateUIViewController(_ uiViewController: YPImagePicker, context: Context) {}
    
    typealias UIViewControllerType = YPImagePicker
    
}
