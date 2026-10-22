#if canImport(FoundationModels)
import FoundationModels

@available(iOS 26.0, *)
@Generable
struct ARASAACGeneratedSuggestions {
    @Guide(description: "In the requested output language, one short sentence identifying what the user chooses or communicates with this board, and the category that new cards must belong to. Infer this from the title and existing cards before suggesting terms.")
    var boardPurpose: String

    @Guide(description: "Up to eight distinct, specific, everyday search terms in the requested output language that directly fit boardPurpose. No umbrella category labels or translations into other languages. Each must be a suitable new card, not an object merely associated with another card. Exclude existing concepts and synonyms. Return fewer terms rather than weak matches.", .maximumCount(8))
    var terms: [String]
}
#endif
