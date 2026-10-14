import Combine
import PhotosUI
import SwiftUI

/// Owns both the system picker and the import, including after provider delivery.
@MainActor
final class SystemPhotoPickerPresenter: UIViewController {
    private let selectionLimit: Int
    private let completion: ([ImportedPhoto]) -> Void
    private let importer = PhotoImportModel()
    private var observation: AnyCancellable?
    private var pickerHost: UIViewController?
    private let status = UILabel()
    private let cancelButton = UIButton(type: .system)
    private var stackCenterX: NSLayoutConstraint?
    private var stackCenterY: NSLayoutConstraint?
    private var stackMaximumWidth: NSLayoutConstraint?

    init(selectionLimit: Int, completion: @escaping ([ImportedPhoto]) -> Void) {
        self.selectionLimit = selectionLimit
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        status.numberOfLines = 0
        status.textAlignment = .center
        status.accessibilityIdentifier = "photoImportStatus"
        cancelButton.setTitle("Cancel Import", for: .normal)
        cancelButton.addTarget(self, action: #selector(cancelImport), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [status, cancelButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        let safeArea = view.safeAreaLayoutGuide
        let centerX = stack.centerXAnchor.constraint(equalTo: safeArea.centerXAnchor)
        let centerY = stack.centerYAnchor.constraint(equalTo: safeArea.centerYAnchor)
        let maximumWidth = stack.widthAnchor.constraint(lessThanOrEqualToConstant: 400)
        stackCenterX = centerX
        stackCenterY = centerY
        stackMaximumWidth = maximumWidth
        NSLayoutConstraint.activate([
            centerX,
            centerY,
            maximumWidth,
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: safeArea.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: safeArea.trailingAnchor, constant: -16)
        ])
        observation = importer.$state.sink { [weak self] state in self?.update(state) }
        showPicker()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let safeFrame = view.safeAreaLayoutGuide.layoutFrame
        let usableFrame = largestUsableFrame(in: safeFrame)
        stackCenterX?.constant = usableFrame.midX - safeFrame.midX
        stackCenterY?.constant = usableFrame.midY - safeFrame.midY
        stackMaximumWidth?.constant = max(44, min(400, usableFrame.width - 32))
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        view.setNeedsLayout()
    }

    private func largestUsableFrame(in safeFrame: CGRect) -> CGRect {
        guard #available(iOS 27.1, *),
              let region = view.reservedRegions(kind: .division).first(where: \.isActive)
        else { return safeFrame }

        let blocked = region.frame.inset(by: UIEdgeInsets(
            top: -region.margins.top,
            left: -region.margins.left,
            bottom: -region.margins.bottom,
            right: -region.margins.right
        )).intersection(safeFrame)
        let candidates: [CGRect]
        if blocked.height >= blocked.width {
            candidates = [
                CGRect(x: safeFrame.minX, y: safeFrame.minY,
                       width: max(0, blocked.minX - safeFrame.minX), height: safeFrame.height),
                CGRect(x: blocked.maxX, y: safeFrame.minY,
                       width: max(0, safeFrame.maxX - blocked.maxX), height: safeFrame.height)
            ]
        } else {
            candidates = [
                CGRect(x: safeFrame.minX, y: safeFrame.minY,
                       width: safeFrame.width, height: max(0, blocked.minY - safeFrame.minY)),
                CGRect(x: safeFrame.minX, y: blocked.maxY,
                       width: safeFrame.width, height: max(0, safeFrame.maxY - blocked.maxY))
            ]
        }
        return candidates.max { $0.width * $0.height < $1.width * $1.height } ?? safeFrame
    }

    private func showPicker() {
        let picker = SystemPhotoPicker(selectionLimit: selectionLimit, onSelection: { [weak self] providers in
            guard let self else { return }
            self.removePicker()
            self.importer.importPhotos(from: providers)
        }, onCancel: { [weak self] in self?.cancelImport() })
        let host = UIHostingController(rootView: picker)
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
        pickerHost = host
    }

    private func removePicker() {
        pickerHost?.willMove(toParent: nil)
        pickerHost?.view.removeFromSuperview()
        pickerHost?.removeFromParent()
        pickerHost = nil
    }

    private func update(_ state: PhotoImportModel.State) {
        switch state {
        case let .loading(completed, total):
            status.text = "Loading photos: \(completed) of \(total)"
        case .loaded:
            completion(importer.photos)
            // Let SwiftUI render the updated board behind the full-screen picker
            // before the dismissal animation reveals it.
            DispatchQueue.main.async { [weak self] in
                self?.dismiss(animated: true)
            }
        case let .failed(message):
            let alert = UIAlertController(title: "Unable to Import Photos", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Choose Again", style: .default) { [weak self] _ in self?.showPicker() })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { [weak self] _ in self?.cancelImport() })
            present(alert, animated: true)
        case .idle, .cancelled: break
        }
    }

    @objc private func cancelImport() {
        importer.cancel()
        dismiss(animated: true)
    }
}

/// Camera capture is separate from library selection and never writes to Photos.
@MainActor
final class PhotoCameraPresenter: UIImagePickerController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var onPhoto: ((UIImage) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            dismiss(animated: true)
            return
        }
        dismiss(animated: true) { [onPhoto] in onPhoto?(image) }
    }
}
