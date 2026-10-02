/// Keeps selected pictograms in tap order, including across different searches.
struct ARASAACSelectionState {
    private(set) var ids: [Int] = []
    private var symbolsByID: [Int: ARASAACSymbol] = [:]

    var isEmpty: Bool { ids.isEmpty }

    var symbols: [ARASAACSymbol] {
        ids.compactMap { symbolsByID[$0] }
    }

    func contains(_ id: Int) -> Bool {
        symbolsByID[id] != nil
    }

    mutating func toggle(_ symbol: ARASAACSymbol, maxSelections: Int?) {
        if let index = ids.firstIndex(of: symbol.id) {
            ids.remove(at: index)
            symbolsByID.removeValue(forKey: symbol.id)
        } else if maxSelections == 1 {
            ids = [symbol.id]
            symbolsByID = [symbol.id: symbol]
        } else {
            if let maxSelections, ids.count >= maxSelections { return }
            ids.append(symbol.id)
            symbolsByID[symbol.id] = symbol
        }
    }
}
