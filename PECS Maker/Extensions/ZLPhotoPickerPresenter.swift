import UIKit
import Photos
import ZLPhotoBrowser
import SharedSwiftUI

final class ZLPhotoPickerPresenterVC: UIViewController {
    private let preselectedAssets: [PHAsset]?
    private let maxSelections: Int
    private let currentTheme: SharedUITheme
    private let completion: ([ZLResultModel]) -> Void
    private let cancel: () -> Void
    private var photoPicker: ZLPhotoPicker?
    private var hasPresentedPhotoPicker = false

    init(preselectedAssets: [PHAsset]?,
         maxSelections: Int,
         currentTheme: SharedUITheme,
         completion: @escaping ([ZLResultModel]) -> Void,
         cancel: @escaping () -> Void) {
        self.preselectedAssets = preselectedAssets
        self.maxSelections = maxSelections
        self.currentTheme = currentTheme
        self.completion = completion
        self.cancel = cancel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        view.backgroundColor = .clear
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !hasPresentedPhotoPicker else { return }
        hasPresentedPhotoPicker = true
        // Present the ZL photo sheet from this UIViewController so it adds
        // itself to our view, not the UIHostingController.view.
        presentPhotoSheet()
    }

    private func presentPhotoSheet() {
        configureZL(maxSelections: maxSelections, currentTheme: currentTheme)

        let picker = ZLPhotoPicker(selectedAssets: preselectedAssets)
        photoPicker = picker
        picker.selectImageBlock = { [weak self] results, _ in
            guard let self = self else { return }
            self.dismiss(animated: true) {
                self.completion(results)
                self.photoPicker = nil
            }
        }
        picker.cancelBlock = { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true) {
                self.cancel()
                self.photoPicker = nil
            }
        }

        picker.showPhotoLibrary(sender: self)
    }
}

// MARK: - ZL Configuration (duplicated from SwiftUI helper to keep UIKit isolated)
extension ZLPhotoPickerPresenterVC {
    func configureZL(maxSelections: Int, currentTheme: SharedUITheme) {
        ZLPhotoConfiguration.default().allowSelectImage = true
        ZLPhotoConfiguration.default().allowSelectVideo = false
        ZLPhotoConfiguration.default().allowEditImage = true
        ZLPhotoConfiguration.default().allowTakePhotoInLibrary = true
        ZLPhotoConfiguration.default().maxSelectCount = maxSelections
        ZLPhotoConfiguration.default().showPreviewButtonInAlbum = false
        ZLPhotoConfiguration.default().allowSelectOriginal = false
        ZLPhotoConfiguration.default().saveNewImageAfterEdit = false
        ZLPhotoConfiguration.default().showSelectedIndex = false
        ZLPhotoConfiguration.default().allowPreviewPhotos = false
        ZLPhotoConfiguration.default().showPreviewButtonInAlbum = false
        ZLPhotoConfiguration.default().useCustomCamera = false

        let theme = ZLPhotoUIConfiguration.default()
        let colorScheme = currentTheme.buttonStyle(for: .primary)

        // Thumbnail page & nav bar
        theme.thumbnailBgColor = currentTheme.backgroundColor
        theme.navViewBlurEffectOfAlbumList = nil
        theme.navTitleColor = currentTheme.headerStyle.textColor
        theme.navBarColor = currentTheme.headerStyle.backgroundColor
        theme.navCancelButtonStyle = .text

        // Bottom toolbar
        theme.bottomViewBlurEffectOfAlbumList  = nil
        theme.bottomToolViewBgColor = currentTheme.headerStyle.backgroundColor

        // Done button colors
        theme.bottomToolViewBtnNormalTitleColor = colorScheme.textColor
        theme.bottomToolViewBtnNormalBgColor = colorScheme.fillColor
    }
}
