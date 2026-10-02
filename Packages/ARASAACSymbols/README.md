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

ARASAAC pictograms are credited to Sergio Palao / ARASAAC and distributed under CC BY-NC-SA. Review [ARASAAC's terms](https://arasaac.org/terms-of-use) before using this package in a commercial app or distributing boards containing pictograms. Callers are responsible for preserving attribution and license information in their saved and exported material.
