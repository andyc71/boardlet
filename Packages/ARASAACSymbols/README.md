# ARASAACSymbols

An iOS 16+ Swift package for searching ARASAAC pictograms in English or Spanish. It contains `ARASAACClient` for search and image downloads and `ARASAACSymbolPicker` for search, multiple selection, and downloading selected images. The picker returns image bytes only after every selected download succeeds, so callers can save a complete selection.

```swift
import ARASAACSymbols

ARASAACSymbolPicker { selections in
    // Each selection contains its symbol metadata and 500 px PNG data.
}

let symbols = try await ARASAACClient().search("cat", language: "en")
```

Search terms are sent to `api.arasaac.org`; images are fetched from `static.arasaac.org`. An internet connection is required. The package does not bundle pictograms or use an API key. Searches use ARASAAC's public `/v1/pictograms/{language}/search/{term}` endpoint.

A search HTTP 404 means no matching pictograms and returns an empty result list, so the picker shows “No symbols found.” Other search failures and missing image downloads remain errors.

ARASAAC pictograms are credited to Sergio Palao / ARASAAC and distributed under CC BY-NC-SA. Review [ARASAAC's terms](https://arasaac.org/terms-of-use) before using this package in a commercial app or distributing boards containing pictograms. Callers are responsible for preserving attribution and license information in their saved and exported material.

## Contextual suggestions

Pass `suggestionContext: ARASAACSuggestionContext(boardName:cardLabels:)` to the picker to enable optional suggestions based on the current board. On iOS 26+, the picker uses Foundation Models' on-device `SystemLanguageModel` with guided generation. It checks model and language availability before making a request. Older systems, unavailable models, empty context, generation failures and failed validation show no suggestion chips; ordinary search remains available.

The model receives only the board title and existing card labels, with bounded prompt size. Guided generation first identifies the board’s purpose, then proposes other choices within that scope. Category boards stay within their category; activity boards use directly relevant steps or needs. The model may return fewer terms (or none) instead of filling a quota with loose associations. This inference stays on-device. Up to eight generated search terms are checked against ARASAAC over the network; up to six terms with results appear as chips. Exact existing labels and duplicate terms are removed, while the prompt also asks the model to avoid existing concepts and synonyms. Semantic relevance is model-dependent, not guaranteed by result validation.

Successful suggestions are cached only in memory for up to 24 board-context/language combinations. Changes to the title, card labels or language invalidate the cache key. Search text edits do not restart generation. Dismissing the picker cancels its suggestion task. No cloud model fallback or static suggestion list is used.

The regular package suite covers context filtering, prompt bounds, validation limits, cancellation and optional-feature failure behavior. The live integration test is opt-in because it requires both an available model and ARASAAC network access:

```sh
# Run from Packages/ARASAACSymbols, substituting an existing simulator ID.
TEST_RUNNER_ARASAAC_LIVE_MODEL_TESTS=1 xcodebuild \
  -scheme ARASAACSymbols -destination 'platform=iOS Simulator,id=SIMULATOR_ID' \
  -derivedDataPath .build \
  -only-testing:ARASAACSymbolsTests/ARASAACLiveSuggestionTests test
```
