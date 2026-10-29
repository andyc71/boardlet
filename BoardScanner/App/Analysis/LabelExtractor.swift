import Foundation

struct LabelExtractor {
    struct Result {
        var label: String
        var confidence: Float
        var picture: CGRect
        var needsReview: Bool
    }

    static func extract(in cell: CGRect, text: [TextRegion]) -> Result {
        let contained = text.filter {
            cell.contains(CGPoint(x: $0.bounds.midX, y: $0.bounds.midY))
            && $0.bounds.intersection(cell).width >= $0.bounds.width * 0.8
        }
        let top = contained.filter { $0.bounds.midY < cell.minY + cell.height * 0.32 }
        let bottom = contained.filter { $0.bounds.midY > cell.minY + cell.height * 0.63 }
        // Text in the picture itself is ambiguous. Prefer the consistent label bands.
        let candidates = !bottom.isEmpty ? bottom : (!top.isEmpty ? top : contained)
        let hasWords = candidates.contains { $0.text.contains { $0.isLetter || $0.isNumber } }
        // Tiny pictogram strokes may be recognized as a separate slash or punctuation mark.
        // Keep a symbol-only caption, and keep '&' between words, but do not prepend stray
        // punctuation to an otherwise readable caption. Retain a review flag for this case.
        let cleaned = candidates.map { region -> TextRegion in
            let words = region.text.split(whereSeparator: \.isWhitespace)
            guard hasWords, words.count > 1, let first = words.first,
                  ["/", "\\", "|", "•"].contains(String(first)) else { return region }
            return TextRegion(text: words.dropFirst().joined(separator: " "), confidence: region.confidence, bounds: region.bounds)
        }
        let caption = cleaned.filter {
            !hasWords || $0.text == "&" || $0.text.contains { $0.isLetter || $0.isNumber }
        }
        let discardedSymbol = caption.count != candidates.count || zip(cleaned, candidates).contains { $0.text != $1.text }
        let labels = caption.sorted {
            if abs($0.bounds.midY - $1.bounds.midY) < min($0.bounds.height, $1.bounds.height) * 0.5 {
                return $0.bounds.minX < $1.bounds.minX
            }
            return $0.bounds.minY < $1.bounds.minY
        }
        let inset = min(cell.width, cell.height) * 0.035
        var picture = cell.insetBy(dx: inset, dy: inset)
        var review = labels.isEmpty
        if let first = labels.first {
            let union = labels.dropFirst().reduce(first.bounds) { $0.union($1.bounds) }
            let padding = max(cell.height * 0.018, union.height * 0.15)
            if union.midY > cell.midY {
                picture.size.height = max(0, union.minY - padding - picture.minY)
            } else {
                let bottomEdge = picture.maxY
                picture.origin.y = max(picture.minY, union.maxY + padding)
                picture.size.height = max(0, bottomEdge - picture.minY)
            }
            // When a bottom caption exists, top text may be part of the symbol (e.g. "a",
            // "NHS" or "A-Z"). Retain that artwork; flag the ambiguity for human review.
            review = (top.isEmpty && bottom.isEmpty) || (!top.isEmpty && !bottom.isEmpty)
            if picture.height < cell.height * 0.15 {
                picture = cell.insetBy(dx: inset, dy: inset)
                review = true
            }
        }
        let confidence = labels.map(\.confidence).min() ?? 0
        return Result(label: labels.map(\.text).joined(separator: " "), confidence: confidence,
                      picture: picture, needsReview: review || discardedSymbol || confidence < 0.8)
    }
}
