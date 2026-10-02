import Foundation
import Combine

/// Main-actor state follows Dynavox's service boundary and ARASAAC's ordered selection semantics.
@MainActor
final class AACStandardPickerModel: ObservableObject {
    @Published private(set) var results: [AACStandardSymbol] = []
    @Published private(set) var selections: [AACStandardSymbol] = []
    @Published private(set) var isSearching = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var nextOffset: Int?
    @Published private(set) var searchError: String?
    @Published private(set) var downloadError: String?

    private let service: any AACStandardServing
    private let maxSelections: Int?
    private let debounceNanoseconds: UInt64
    private var revision = UUID()
    private var request = AACStandardSearchRequest(term: "")

    init(service: any AACStandardServing, maxSelections: Int?, debounceNanoseconds: UInt64 = 350_000_000) {
        self.service = service
        self.maxSelections = maxSelections
        self.debounceNanoseconds = debounceNanoseconds
    }

    func toggle(_ symbol: AACStandardSymbol) {
        if let index = selections.firstIndex(where: { $0.id == symbol.id }) {
            selections.remove(at: index)
        } else if maxSelections == 1 {
            selections = [symbol]
        } else if maxSelections == nil || selections.count < maxSelections! {
            selections.append(symbol)
        }
        downloadError = nil
    }

    func clearSelection() {
        selections = []
        downloadError = nil
    }

    func search(_ newRequest: AACStandardSearchRequest) async {
        let currentRevision = UUID()
        revision = currentRevision
        request = newRequest
        results = []
        nextOffset = nil
        searchError = nil
        isLoadingMore = false
        isSearching = !newRequest.term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        guard isSearching else { return }
        defer { if revision == currentRevision { isSearching = false } }
        do {
            if debounceNanoseconds > 0 { try await Task.sleep(nanoseconds: debounceNanoseconds) }
            let page = try await service.search(newRequest)
            try Task.checkCancellation()
            guard revision == currentRevision else { return }
            results = unique(page.symbols)
            nextOffset = page.nextOffset
        } catch {
            guard revision == currentRevision, !isCancellation(error) else { return }
            searchError = error.localizedDescription
        }
    }

    func loadMore() async {
        guard !isSearching, !isLoadingMore, let offset = nextOffset else { return }
        let currentRevision = revision
        var pageRequest = request
        pageRequest.offset = offset
        isLoadingMore = true
        searchError = nil
        defer { if revision == currentRevision { isLoadingMore = false } }
        do {
            let page = try await service.search(pageRequest)
            try Task.checkCancellation()
            guard revision == currentRevision else { return }
            results = unique(results + page.symbols)
            nextOffset = page.nextOffset
        } catch {
            guard revision == currentRevision, !isCancellation(error) else { return }
            searchError = error.localizedDescription
        }
    }

    func downloadSelection() async -> [AACStandardSelection]? {
        downloadError = nil
        do {
            let downloaded = try await service.download(selections)
            try Task.checkCancellation()
            return downloaded
        } catch {
            if !isCancellation(error) { downloadError = error.localizedDescription }
            return nil
        }
    }

    private func isCancellation(_ error: Error) -> Bool {
        Task.isCancelled || error is CancellationError || (error as? URLError)?.code == .cancelled
    }

    private func unique(_ symbols: [AACStandardSymbol]) -> [AACStandardSymbol] {
        var seen: Set<Int> = []
        return symbols.filter { seen.insert($0.id).inserted }
    }
}
