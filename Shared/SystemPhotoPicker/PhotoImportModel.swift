import Combine
import UIKit

/// Atomic replacement: a failed or cancelled batch leaves the previous images intact.
/// Loads a bounded number concurrently and commits results in selection order.
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
    private let maximumConcurrentLoads: Int
    private var activeProgress: [Int: Progress] = [:]
    private var batch: Batch?

    private struct Batch {
        let generation: UUID
        let sources: [ImageImportSource]
        var nextIndex = 0
        var completed = 0
        var photos: [ImportedPhoto?]
    }

    init(maximumConcurrentLoads: Int = 3) {
        self.maximumConcurrentLoads = max(1, maximumConcurrentLoads)
    }

    var isLoading: Bool {
        if case .loading = state { return true }
        return false
    }

    func importPhotos(from providers: [NSItemProvider]) {
        importPhotos(from: providers.map { ImageImportSource(provider: $0) })
    }

    func importPhotos(from sources: [ImageImportSource]) {
        invalidate()
        guard !sources.isEmpty else {
            state = .cancelled
            return
        }
        batch = Batch(
            generation: generation,
            sources: sources,
            photos: Array(repeating: nil, count: sources.count)
        )
        state = .loading(completed: 0, total: sources.count)
        startAvailableLoads()
    }

    func cancel() {
        invalidate()
        state = .cancelled
    }

    private func invalidate() {
        generation = UUID()
        activeProgress.values.forEach { $0.cancel() }
        activeProgress.removeAll()
        batch = nil
    }

    private func startAvailableLoads() {
        guard var batch else { return }
        while activeProgress.count < maximumConcurrentLoads,
              batch.nextIndex < batch.sources.count {
            let index = batch.nextIndex
            batch.nextIndex += 1
            self.batch = batch
            let batchGeneration = batch.generation
            let progress = batch.sources[index].load { [weak self] result in
                // Item-provider callbacks may arrive on any queue, including after cancellation.
                Task { @MainActor [weak self] in
                    self?.finishLoad(result, at: index, generation: batchGeneration)
                }
            }
            guard self.batch?.generation == batchGeneration else {
                progress.cancel()
                return
            }
            activeProgress[index] = progress
        }
        self.batch = batch
    }

    private func finishLoad(
        _ result: Result<Data, any Error>,
        at index: Int,
        generation: UUID
    ) {
        guard self.generation == generation,
              activeProgress.removeValue(forKey: index) != nil,
              var batch,
              batch.generation == generation else { return }

        do {
            let data = try result.get()
            guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else {
                throw ImageImportError.invalidImage
            }
            batch.photos[index] = ImportedPhoto(image: image, pngData: data)
            batch.completed += 1
            self.batch = batch

            if batch.completed == batch.sources.count {
                photos = batch.photos.compactMap { $0 }
                self.batch = nil
                state = .loaded
            } else {
                state = .loading(completed: batch.completed, total: batch.sources.count)
                startAvailableLoads()
            }
        } catch {
            let total = batch.sources.count
            invalidate()
            state = .failed("Photo \(index + 1) of \(total): \(error.localizedDescription)")
        }
    }

    deinit { activeProgress.values.forEach { $0.cancel() } }
}
