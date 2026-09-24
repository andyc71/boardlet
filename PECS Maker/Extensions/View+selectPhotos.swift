import SwiftUI
import SharedSwiftUI

extension View {
    /// Each visit adds new selections. Existing board images remain in the board,
    /// including duplicates and edited images; no PhotoKit authorization is needed.
    @MainActor
    func selectPhotos(pageLayoutState: PageLayoutState,
                      isAdditive: Bool = false, currentTheme: SharedUITheme) {
        let remaining = isAdditive
            ? AppSettings.maxSelectionsInPhotoPicker - pageLayoutState.photoBrowserData.photoCount
            : AppSettings.maxSelectionsInPhotoPicker
        guard remaining > 0 else { return }
        PhotoPresentation.present(SystemPhotoPickerPresenter(selectionLimit: remaining) { images in
            let items = images.map { PhotoItem(image: $0) }
            if isAdditive {
                pageLayoutState.photoBrowserData.add(items)
            } else {
                pageLayoutState.setPhotos(items)
            }
        })
    }

    @MainActor
    func selectTopicPhoto(currentTheme: SharedUITheme, onSelect: @escaping (UIImage) -> Void) {
        PhotoPresentation.present(SystemPhotoPickerPresenter(selectionLimit: 1) { images in
            if let image = images.first { onSelect(image) }
        })
    }
}

@MainActor
enum PhotoPresentation {
    static var presenter: UIViewController? {
        let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
        var controller = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
        while let presented = controller?.presentedViewController, !presented.isBeingDismissed {
            controller = presented
        }
        return controller
    }

    static func present(_ controller: UIViewController) {
        presenter?.present(controller, animated: true)
    }
}

extension View {
    @MainActor
    func takePhoto(onSelect: @escaping (UIImage) -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let camera = PhotoCameraPresenter()
        camera.sourceType = .camera
        camera.onPhoto = onSelect
        PhotoPresentation.present(camera)
    }

    @MainActor
    func takeBoardPhoto(pageLayoutState: PageLayoutState) {
        guard pageLayoutState.photoBrowserData.photoCount < AppSettings.maxSelectionsInPhotoPicker else { return }
        takePhoto { image in pageLayoutState.photoBrowserData.add(photo: PhotoItem(image: image)) }
    }
}
