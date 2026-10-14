import SwiftUI
import SharedSwiftUI
import ZLPhotoBrowser

extension View {
    /// Each visit adds new selections. Existing board images remain in the board,
    /// including duplicates and edited images; no PhotoKit authorization is needed.
    @MainActor
    func selectPhotos(pageLayoutState: PageLayoutState,
                      isAdditive: Bool = false, currentTheme: SharedUITheme,
                      from presenter: UIViewController) {
        let remaining = isAdditive
            ? AppSettings.maxSelectionsInPhotoPicker - pageLayoutState.photoBrowserData.photoCount
            : AppSettings.maxSelectionsInPhotoPicker
        guard remaining > 0 else { return }
        PhotoPresentation.present(SystemPhotoPickerPresenter(selectionLimit: remaining) { photos in
            let items = photos.map { PhotoItem(image: $0.image, preparedPNGData: $0.pngData) }
            if isAdditive {
                pageLayoutState.photoBrowserData.add(items)
            } else {
                pageLayoutState.setPhotos(items)
            }
        }, from: presenter)
    }

    @MainActor
    func selectTopicPhoto(currentTheme: SharedUITheme, from presenter: UIViewController,
                          onSelect: @escaping (UIImage) -> Void) {
        PhotoPresentation.present(SystemPhotoPickerPresenter(selectionLimit: 1) { photos in
            if let image = photos.first?.image { onSelect(image) }
        }, from: presenter)
    }
}

@MainActor
enum PhotoPresentation {
    static func present(_ controller: UIViewController, from presenter: UIViewController) {
        presenter.present(controller, animated: true)
    }

    static func edit(_ image: UIImage, theme: SharedUITheme, from presenter: UIViewController,
                     onFinish: @escaping (UIImage) -> Void) {
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
            with: presenter.traitCollection
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

        present(editor, from: presenter)
    }
}

/// Keeps UIKit presentations attached to the SwiftUI window that initiated them.
/// This avoids choosing an arbitrary foreground scene when the app later gains
/// additional windows or moves between Duo displays.
@MainActor
final class ScenePresentationContext: ObservableObject {
    weak var anchorViewController: UIViewController?

    var presenter: UIViewController? {
        guard var controller = anchorViewController?.viewIfLoaded?.window?.rootViewController
                ?? anchorViewController else { return nil }
        while true {
            if let presented = controller.presentedViewController, !presented.isBeingDismissed {
                controller = presented
            } else if let navigation = controller as? UINavigationController,
                      let visible = navigation.visibleViewController {
                controller = visible
            } else if let tabs = controller as? UITabBarController,
                      let selected = tabs.selectedViewController {
                controller = selected
            } else {
                return controller
            }
        }
    }
}

struct ScenePresentationReader: UIViewControllerRepresentable {
    let context: ScenePresentationContext

    func makeUIViewController(context: Context) -> ScenePresentationAnchorViewController {
        ScenePresentationAnchorViewController(presentationContext: self.context)
    }

    func updateUIViewController(_ uiViewController: ScenePresentationAnchorViewController,
                                context: Context) {
        self.context.anchorViewController = uiViewController
    }
}

final class ScenePresentationAnchorViewController: UIViewController {
    private weak var presentationContext: ScenePresentationContext?

    init(presentationContext: ScenePresentationContext) {
        self.presentationContext = presentationContext
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentationContext?.anchorViewController = self
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
        let safeFrame = view.safeAreaLayoutGuide.layoutFrame
        let side: CGFloat = 44
        let x = originalFrame.midX > view.bounds.midX
            ? safeFrame.maxX - side
            : safeFrame.minX
        cancelBtn.frame = CGRect(x: x, y: originalFrame.midY - side / 2, width: side, height: side)
        legacyCloseMaterial?.frame = cancelBtn.frame
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.setNeedsLayout()
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        // ZLPhotoBrowser's internal animation flag defaults to false for direct instances.
        super.dismiss(animated: true, completion: completion)
    }
}

extension View {
    @MainActor
    func takePhoto(from presenter: UIViewController, onSelect: @escaping (UIImage) -> Void) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return }
        let camera = PhotoCameraPresenter()
        camera.sourceType = .camera
        camera.onPhoto = onSelect
        PhotoPresentation.present(camera, from: presenter)
    }

    @MainActor
    func takeBoardPhoto(pageLayoutState: PageLayoutState, from presenter: UIViewController) {
        guard pageLayoutState.photoBrowserData.photoCount < AppSettings.maxSelectionsInPhotoPicker else { return }
        takePhoto(from: presenter) { image in
            pageLayoutState.photoBrowserData.add(photo: PhotoItem(image: image))
        }
    }
}
