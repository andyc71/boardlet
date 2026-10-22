import Foundation

/// Only display generated terms that have real pictogram search results.
struct ARASAACSuggestionValidator {
    static func validate(
        _ candidates: [String],
        search: (String) async throws -> Bool
    ) async throws -> [String] {
        var validated: [String] = []
        for candidate in candidates.prefix(8) {
            try Task.checkCancellation()
            if try await search(candidate) { validated.append(candidate) }
            try Task.checkCancellation()
            if validated.count == 6 { break }
        }
        return validated
    }
}
