import SwiftUI
import SharedSwiftUI
import ZLPhotoBrowser

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

    static func edit(_ image: UIImage, theme: SharedUITheme, onFinish: @escaping (UIImage) -> Void) {
        let editorColors = ZLPhotoUIConfiguration.default()
        editorColors.imageEditorToolIconTintColor = .mfVeryBrightBlue
        editorColors.imageEditorToolTitleTintColor = .mfVeryBrightBlue

        let editor = AnimatedPhotoEditorViewController(image: image)
        editor.modalPresentationStyle = .fullScreen
        editor.editFinishBlock = { editedImage, _ in onFinish(editedImage) }

        editor.mainScrollView.backgroundColor = theme.backgroundColor
        editor.mainScrollView.tintColor = .mfVeryBrightBlue

        // The editor overlays its controls on the photo, which can be white.
        let dark = UIColor.black
        let background = theme.backgroundColor.resolvedColor(
            with: presenter?.traitCollection ?? UITraitCollection.current
        )
        editor.topShadowLayer.colors = [
            dark.withAlphaComponent(0.9).cgColor,
            dark.withAlphaComponent(0.75).cgColor,
            background.cgColor
        ]
        editor.topShadowLayer.locations = [0, 0.45, 1]
        editor.bottomShadowLayer.colors = [
            background.cgColor,
            dark.withAlphaComponent(0.9).cgColor,
            dark.withAlphaComponent(0.9).cgColor
        ]
        // The adjustment row starts just 20 points below this layer's top edge.
        editor.bottomShadowLayer.locations = [0, 0.15, 1]

        editor.doneBtn.backgroundColor = .mfVeryBrightBlue
        editor.doneBtn.setTitleColor(.white, for: .normal)
        editor.doneBtn.accessibilityIdentifier = "photoEditorDone"

        let cancelButton = editor.cancelBtn
        cancelButton.accessibilityLabel = cancelButton.currentTitle
        cancelButton.setTitle(nil, for: .normal)
        if #available(iOS 26.0, *) {
            let closeSymbol = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .medium))
            var glass = UIButton.Configuration.glass()
            glass.image = closeSymbol
            glass.baseForegroundColor = .mfVeryBrightBlue
            glass.cornerStyle = .capsule
            glass.contentInsets = .zero
            cancelButton.configuration = glass
            cancelButton.contentHorizontalAlignment = .center
        } else {
            let closeSymbol = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 17, weight: .semibold))
            cancelButton.setImage(closeSymbol, for: .normal)
            cancelButton.contentHorizontalAlignment = .center
        }
        cancelButton.tintColor = .mfVeryBrightBlue
        cancelButton.accessibilityIdentifier = "photoEditorCancel"

        present(editor)
    }
}

private final class AnimatedPhotoEditorViewController: ZLEditImageViewController {
    private var legacyCloseMaterial: UIVisualEffectView?

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 26.0, *) {
            return
        }

        let material = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        material.isUserInteractionEnabled = false
        material.layer.cornerRadius = 22
        material.clipsToBounds = true
        topShadowView.insertSubview(material, belowSubview: cancelBtn)
        legacyCloseMaterial = material
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // ZLPhotoBrowser sizes this button for the old Cancel title on each layout.
        let originalFrame = cancelBtn.frame
        let side: CGFloat = 44
        let edgeInset: CGFloat = 16
        let x = originalFrame.midX > view.bounds.midX
            ? view.bounds.width - side - edgeInset
            : edgeInset
        cancelBtn.frame = CGRect(x: x, y: originalFrame.midY - side / 2, width: side, height: side)
        legacyCloseMaterial?.frame = cancelBtn.frame
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        // ZLPhotoBrowser's internal animation flag defaults to false for direct instances.
        super.dismiss(animated: true, completion: completion)
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
