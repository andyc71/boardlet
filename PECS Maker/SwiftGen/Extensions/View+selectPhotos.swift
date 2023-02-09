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
    func selectPhotos(pageLayoutState: PageLayoutState, preselectItems: Bool = false, isAdditive: Bool = false) {
        let scene = UIApplication.shared.connectedScenes.first
        let root = (scene as? UIWindowScene)?.windows.first?.rootViewController
        if root != nil {
            
            ZLPhotoConfiguration.default().allowSelectImage = true
            ZLPhotoConfiguration.default().allowSelectVideo = false
            ZLPhotoConfiguration.default().allowEditImage = true
            //ZLPhotoConfiguration.default().editImageTools = [.clip, .filter]
            ZLPhotoConfiguration.default().allowTakePhoto = true
            ZLPhotoConfiguration.default().maxSelectCount = AppSettings.maxSelectionsInPhotoPicker
            ZLPhotoConfiguration.default().showSelectedPhotoPreview = false
            ZLPhotoConfiguration.default().allowSelectOriginal = false
            ZLPhotoConfiguration.default().saveNewImageAfterEdit = false
            ZLPhotoConfiguration.default().showSelectedIndex = false
            ZLPhotoConfiguration.default().allowPreviewPhotos = false
            ZLPhotoConfiguration.default().showPreviewButtonInAlbum = false
            //ZLPhotoConfiguration.default().editImageClipRatios = [ZLImageClipRatio(title: "", whRatio: CGFloat(1) / aspectRatio)]
            //ZLPhotoConfiguration.default().frontFacingCamera = true
            //ZLPhotoConfiguration.default().supportedCameraOrientations = [.all]
            //ZLPhotoConfiguration.default().defaultCameraPosition = .front
            
            //Custom camera doesn't rotate properly on iPad, and I can't
            //see a good reason for using it anyway.
            ZLPhotoConfiguration.default().useCustomCamera = false
            
            
            let theme = ZLPhotoUIConfiguration.default()
            
            //Bottom toolbar theme
            let colorScheme = currentTheme.buttonStyle(for: .primary)
            
            //**Thunbnail page.
            theme.thumbnailBgColor = currentTheme.backgroundColor
            
            //Nav bar theme
            theme.navViewBlurEffectOfAlbumList = nil
            theme.navTitleColor = currentTheme.headerStyle.textColor
            theme.navBarColor = currentTheme.headerStyle.backgroundColor
            theme.navCancelButtonStyle = .text
            
            //Bottom toolbar
            theme.bottomViewBlurEffectOfAlbumList  = nil
            theme.bottomToolViewBgColor = currentTheme.headerStyle.backgroundColor
            
            //Done button
            theme.bottomToolViewBtnNormalTitleColor = colorScheme.textColor
            theme.bottomToolViewBtnNormalBgColor = colorScheme.fillColor
            
            /*
             //Preview button
             theme.bottomToolViewBtnNormalTitleColor = currentTheme.headerStyle.backButtonTextColor
             
             // Preview page
             theme.previewVCBgColor = currentTheme.backgroundColor
             
             //Preview page - nav bar
             theme.navViewBlurEffectOfPreview = nil
             theme.navTitleColorOfPreviewVC = currentTheme.headerStyle.backButtonTextColor
             theme.navBarColorOfPreviewVC = currentTheme.headerStyle.backgroundColor
             //theme.sheetBtnTitleColor = currentTheme.headerStyle.backButtonTextColor
             
             
             //theme.bottomViewBlurEffectOfPreview = nil
             */
            
            
            //                theme.bottomToolViewBtnNormalTitleColor = colorScheme.textColor
            //                theme.bottomToolViewBtnNormalBgColor = colorScheme.fillColor
            //                theme.bottomToolViewDoneBtnNormalTitleColor = colorScheme.textColor
            //                theme.bottomToolViewBtnNormalBgColorOfPreviewVC = colorScheme.fillColor
            //                theme.bottomToolViewDoneBtnNormalTitleColorOfPreviewVC = colorScheme.textColor
            //                theme.bottomToolViewBtnNormalTitleColorOfPreviewVC = colorScheme.textColor
            //                theme.bottomToolViewDoneBtnNormalTitleColor = colorScheme.textColor
            
            
            let ac = ZLPhotoPreviewSheet(selectedAssets: preselectItems ? pageLayoutState.photoBrowserData.photoAssets : nil)
            
            ac.selectImageBlock = { (images, assets, isOriginal) in
                
                DispatchQueue.global().async {
                    var photoItems = [PhotoItem]()
                    for i in 0..<images.count {
                        let image = images[i]
                        let asset = assets[i]
                        let photoItem = PhotoItem(image: image, asset: asset)
                        photoItems.append(photoItem)
                    }
                    DispatchQueue.main.async {
                        //Updating the photoBrowserData will automatically call save on the repo.
                        if isAdditive {
                            pageLayoutState.photoBrowserData.add(photoItems)
                        }
                        else {
                            pageLayoutState.setPhotos(photoItems)
                            //photoBrowserData.photoItems = photoItems
                            //self.save()
                        }
                    }
                }
            }
            
            ac.showPhotoLibrary(sender: root!)
        }
    }
}
