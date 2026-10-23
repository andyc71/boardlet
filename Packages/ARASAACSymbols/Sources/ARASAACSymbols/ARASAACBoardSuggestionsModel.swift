import Foundation
import Combine

@MainActor
final class ARASAACBoardSuggestionsModel: ObservableObject {
    @Published private(set) var items: [ARASAACBoardSuggestion] = []
    @Published private(set) var isGenerating = true
    @Published private(set) var isRetrying = false
    @Published var selectedTerms: Set<String> = []

    var isResolving: Bool {
        items.contains { if case .loading = $0.status { return true }; return false }
    }

    var canAdd: Bool {
        !isGenerating && !selectedTerms.isEmpty && items.filter { selectedTerms.contains($0.term) }.allSatisfy {
            if case .ready = $0.status { return true }
            return false
        }
    }

    var selections: [ARASAACSelection] {
        var ids: Set<Int> = []
        return items.compactMap { item in
            guard selectedTerms.contains(item.term), case let .ready(selection) = item.status,
                  ids.insert(selection.symbol.id).inserted else { return nil }
            return selection
        }
    }

    func load(context: ARASAACSuggestionContext, language: String, client: ARASAACClient) async {
        await load(terms: {
            await ARASAACSuggestionService.shared.terms(context: context, language: language)
        }, resolve: { term in
            try await Self.resolve(term, language: language, client: client)
        })
    }

    /// Publish text first, then resolve up to three independent rows at a time.
    /// A single missing symbol or failed request must not discard successful rows.
    func load(terms: () async -> [String],
              resolve: @escaping @Sendable (String) async throws -> ARASAACSelection?) async {
        isGenerating = true
        selectedTerms = []
        let words = await terms()
        guard !Task.isCancelled else { return }
        items = words.map { ARASAACBoardSuggestion(term: $0) }
        selectedTerms = []
        isGenerating = false
        await resolveRows(words, resolve: resolve)
    }

    func retry(language: String, client: ARASAACClient) async {
        guard !isRetrying && !isResolving else { return }
        isRetrying = true
        defer { isRetrying = false }
        let words = items.filter { if case .failed = $0.status { return true }; return false }.map(\.term)
        for index in items.indices where words.contains(items[index].term) {
            items[index].status = .loading
        }
        await resolveRows(words) { term in
            try await Self.resolve(term, language: language, client: client)
        }
    }

    nonisolated static func resolve(_ term: String, language: String,
                                            client: ARASAACClient) async throws -> ARASAACSelection? {
        let results = try await client.search(term, language: language)
        guard let symbol = results.first(where: { $0.matchesSuggestion(term) }) else { return nil }
        return try await client.download(symbol)
    }

    private func resolveRows(_ words: [String],
                             resolve: @escaping @Sendable (String) async throws -> ARASAACSelection?) async {
        await withTaskGroup(of: (String, Result<ARASAACSelection?, Error>).self) { group in
            var remaining = words.makeIterator()
            func enqueue(_ word: String) {
                group.addTask {
                    do {
                        try Task.checkCancellation()
                        return (word, .success(try await resolve(word)))
                    } catch {
                        return (word, .failure(error))
                    }
                }
            }
            for _ in 0..<3 {
                if let word = remaining.next() { enqueue(word) }
            }
            for await (word, result) in group {
                guard !Task.isCancelled else { group.cancelAll(); return }
                if let index = items.firstIndex(where: { $0.term == word }) {
                    switch result {
                    case let .success(selection?): items[index].status = .ready(selection)
                    case .success(nil):
                        items[index].status = .unavailable
                        selectedTerms.remove(word)
                    case .failure:
                        items[index].status = .failed
                        selectedTerms.remove(word)
                    }
                }
                if let word = remaining.next() { enqueue(word) }
            }
        }
    }
}
