import SwiftUI
import Combine
@preconcurrency import ARASAACSymbols

@MainActor
final class CardImportSession: ObservableObject {
    @Published var cards: [Card] = []
    @Published private(set) var failures: [String] = []
    @Published private(set) var completed = 0
    @Published private(set) var total = 0
    @Published private(set) var loading = false
    private var failedSources: [ImageImportSource] = []
    private var failedSymbols: [ARASAACSymbol] = []
    private var generation = UUID()
    private var progress: Progress?
    private var work: Task<Void, Never>?

    func cancel() { generation = UUID(); progress?.cancel(); work?.cancel(); loading = false }

    func importPhotos(_ sources: [ImageImportSource], storage: any LibraryStorage) {
        cancel(); failures = []; failedSources = []; completed = 0; total = sources.count
        guard !sources.isEmpty else { return }
        loading = true
        load(sources, index: 0, generation: generation, storage: storage)
    }
    func retry(storage: any LibraryStorage) {
        if !failedSources.isEmpty { importPhotos(failedSources, storage: storage) }
        else if !failedSymbols.isEmpty { importSymbols(failedSymbols, storage: storage) }
    }
    private func load(_ sources: [ImageImportSource], index: Int, generation: UUID, storage: any LibraryStorage) {
        progress = sources[index].load { [weak self] result in
            Task { @MainActor [weak self] in
                guard let self, self.generation == generation else { return }
                do {
                    let data = try result.get()
                    guard let image = UIImage(data: data), let png = image.pngData() else { throw ImageImportError.invalidImage }
                    let name = try await storage.storeAsset(png, extension: "png")
                    guard self.generation == generation else { return }
                    self.cards.append(Card(label: "", image: name, originalImage: name))
                } catch {
                    guard self.generation == generation else { return }
                    self.failures.append(L("Photo") + " \(index + 1): " + error.localizedDescription)
                    self.failedSources.append(sources[index])
                }
                self.completed = index + 1
                if index + 1 < sources.count { self.load(sources, index: index + 1, generation: generation, storage: storage) }
                else { self.loading = false; self.progress = nil }
            }
        }
    }
    func importSymbols(_ symbols: [ARASAACSymbol], storage: any LibraryStorage) {
        cancel(); failures = []; failedSymbols = []; completed = 0; total = symbols.count; loading = true
        let token = generation
        work = Task {
            for symbol in symbols {
                do {
                    let selection = try await ARASAACClient().download(symbol)
                    try Task.checkCancellation()
                    guard UIImage(data: selection.imageData) != nil else { throw ImageImportError.invalidImage }
                    let name = try await storage.storeAsset(selection.imageData, extension: "png")
                    guard token == generation else { return }
                    cards.append(Card(label: symbol.title, image: name, originalImage: name, attribution: .arasaac(symbol.id), originalAttribution: .arasaac(symbol.id)))
                } catch is CancellationError { return }
                catch { if token == generation { failures.append(symbol.title + ": " + error.localizedDescription); failedSymbols.append(symbol) } }
                guard token == generation else { return }; completed += 1
            }
            loading = false
        }
    }
    func addImage(_ image: UIImage, storage: any LibraryStorage) async {
        do {
            guard let data = image.pngData() else { throw ImageImportError.invalidImage }
            let name = try await storage.storeAsset(data, extension: "png")
            cards.append(Card(label: "", image: name, originalImage: name))
        } catch { failures.append(error.localizedDescription) }
    }
}
