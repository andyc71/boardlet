//
//  View+pickPhoto.swift
//  PECS Maker
//
//  Created by Andy on 19/01/2023.
//

import SwiftUI
import ZLPhotoBrowser
import SharedSwiftUI

extension View {
    
    ///Show a photo picker popup and append the selected items in photoBrowserData.
    ///If preseelectItems is true then we start out with the items from photoBrowswerData as ticked.
    ///We used to turn on preselectItems by default, but now we've got the preselected items showing
    ///in the Select Photos view then this screen becomes more useful for appending new items.
    func selectPhotos(pageLayoutState: PageLayoutState, preselectItems: Bool = false, isAdditive: Bool = false, currentTheme: SharedUITheme) {
        let scene = UIApplication.shared.connectedScenes.first
        let root = (scene as? UIWindowScene)?.windows.first?.rootViewController
        guard let root else { return }

        let presenter = ZLPhotoPickerPresenterVC(
            preselectedAssets: preselectItems ? pageLayoutState.photoBrowserData.photoAssets : nil,
            maxSelections: AppSettings.maxSelectionsInPhotoPicker,
            currentTheme: currentTheme,
            completion: { results in
                DispatchQueue.global().async {
                    var photoItems = [PhotoItem]()
                    for r in results {
                        let image = r.image
                        let asset = r.asset
                        let photoItem = PhotoItem(image: image, asset: asset)
                        photoItems.append(photoItem)
                    }
                    DispatchQueue.main.async {
                        if isAdditive {
                            pageLayoutState.photoBrowserData.add(photoItems)
                        } else {
                            pageLayoutState.setPhotos(photoItems)
                        }
                    }
                }
            },
            cancel: { }
        )

        root.present(presenter, animated: true)
    }
    
    
    
    ///Show a photo picker popup and put the result into the topic photo
    func selectTopicPhoto(currentTheme: SharedUITheme, onSelect: @escaping (UIImage)->() ) {
        let scene = UIApplication.shared.connectedScenes.first
        let root = (scene as? UIWindowScene)?.windows.first?.rootViewController
        guard let root else { return }

        let presenter = ZLPhotoPickerPresenterVC(
            preselectedAssets: nil,
            maxSelections: 1,
            currentTheme: currentTheme,
            completion: { results in
                if let first = results.first {
                    let image = first.image
                    DispatchQueue.main.async {
                        onSelect(image)
                    }
                }
            },
            cancel: { }
        )

        root.present(presenter, animated: true)
    }
}
