import PhotosUI
import SwiftUI

/// Shared presentation boundary. The caller owns dismissal and import lifetime.
/// No library authorization, PHAsset lookup, or preselection is required.
@MainActor
struct SystemPhotoPicker: UIViewControllerRepresentable {
    let selectionLimit: Int // 0 means unlimited, 1 means single selection.
    let onSelection: ([NSItemProvider]) -> Void
    let onCancel: () -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = max(0, selectionLimit)
        configuration.selection = .ordered
        configuration.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: PHPickerViewController, context: Context) {
        context.coordinator.parent = self
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: SystemPhotoPicker
        private var finished = false

        init(parent: SystemPhotoPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard !finished else { return }
            finished = true
            if results.isEmpty {
                parent.onCancel()
            } else {
                parent.onSelection(results.map(\.itemProvider))
            }
        }
    }
}
