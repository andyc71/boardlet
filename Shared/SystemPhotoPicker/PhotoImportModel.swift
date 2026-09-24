import Combine
import UIKit

/// Atomic replacement: a failed or cancelled batch leaves the previous images intact.
/// Loads sequentially to preserve ordered selection and bound in-flight provider work.
@MainActor
final class PhotoImportModel: ObservableObject {
    enum State: Equatable {
        case idle
        case loading(completed: Int, total: Int)
        case loaded
        case cancelled
        case failed(String)
    }

    @Published private(set) var photos: [ImportedPhoto] = []
    @Published private(set) var state: State = .idle
    private var generation = UUID()
    private var progress: Progress?

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    func importPhotos(from providers: [NSItemProvider]) {
        importPhotos(from: providers.map(ImageImportSource.init(provider:)))
    }

    func importPhotos(from sources: [ImageImportSource]) {
        invalidate()
        guard !sources.isEmpty else {
            state = .cancelled
            return
        }
        load(sources, index: 0, accumulated: [], generation: generation)
    }

    func cancel() {
        invalidate()
        state = .cancelled
    }

    private func invalidate() {
        generation = UUID()
        progress?.cancel()
        progress = nil
    }

    private func load(_ sources: [ImageImportSource], index: Int,
                      accumulated: [ImportedPhoto], generation: UUID) {
        state = .loading(completed: index, total: sources.count)
        progress = sources[index].load { [weak self] result in
            // Item-provider callbacks may arrive on any queue, including after cancellation.
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation else { return }
                self.progress = nil
                do {
                    let data = try result.get()
                    guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else {
                        throw ImageImportError.invalidImage
                    }
                    let updated = accumulated + [ImportedPhoto(image: image)]
                    if index + 1 == sources.count {
                        self.photos = updated
                        self.state = .loaded
                    } else {
                        self.load(sources, index: index + 1, accumulated: updated, generation: generation)
                    }
                } catch {
                    self.state = .failed("Photo \(index + 1) of \(sources.count): \(error.localizedDescription)")
                }
            }
        }
    }

    deinit { progress?.cancel() }
}
