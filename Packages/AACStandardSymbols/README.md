# AACStandardSymbols

A dependency-free Swift package for searching [AAC Standard](https://aacstandard.com), selecting symbols, and downloading their original PNGs. The client and testable picker model support iOS 16+ and macOS 13+; the SwiftUI picker is available on iOS. Swift tools 5.8, compatible with the app's Swift 5 and iOS 16.6 settings.

## Use the picker

Add `Packages/AACStandardSymbols` as a local package dependency and link its `AACStandardSymbols` product to the app target. PECS Maker currently links this package only to the Boardlet+ (`Easy PECS Plus`) target. Its empty-board search button, Add menu, and topic-image chooser present this picker. The standard Boardlet target does not link or expose the provider.

```swift
import AACStandardSymbols
import SwiftUI

struct SymbolSearchExample: View {
    @State private var showingSymbols = false
    @State private var selected: [AACStandardSelection] = []

    var body: some View {
        Button("Choose symbols") { showingSymbols = true }
            .fullScreenCover(isPresented: $showingSymbols) {
                AACStandardSymbolPicker(maxSelections: 12) { selections in
                    if !selections.isEmpty { selected = selections }
                    showingSymbols = false
                }
            }
    }
}
```

Use `maxSelections: 1` for a topic image. `nil` allows multiple selections without a limit; zero or negative values allow none. Selecting another symbol in single-selection mode replaces the previous one. Cancel returns `[]`; the host owns dismissal. The completion runs on the main actor, only after every selected PNG has downloaded and decoded successfully. A failed download retains the selection so Add can retry. The picker disables edits during downloads and cancels work when it disappears.

Pass `language: "es"` or `ageGroup: .child` to configure a picker. Without a language override, it uses the SwiftUI environment locale for the service's currently advertised languages (pl, en, de, uk, fr, es, it, cs, sk), falling back to English. The UI has English and Spanish translations. `nil` age group omits the filter; `.all` sends the API's explicit `all` value rather than assuming those two options have identical semantics.

The grid uses WebP thumbnails, with the original PNG as fallback when a thumbnail URL is absent or unsafe. Search is debounced by 350 ms. Selections survive searches and pagination, retain tap order, and can be cleared independently of the visible results. Load More fetches one page at a time. VoiceOver selection traits, checkmarks, Dynamic Type text, and image-error placeholders are included.

## Use the client directly

```swift
let client = AACStandardClient()
let symbols = try await client.search("water", language: "en-GB")
let selected = try await client.download(Array(symbols.prefix(2)))
// Each selection has symbol metadata and imageData suitable for UIImage(data:).

var request = AACStandardSearchRequest(
    term: "water", language: "en", ageGroup: .child, limit: 50
)
let firstPage = try await client.search(request)
if let offset = firstPage.nextOffset {
    request.offset = offset
    let secondPage = try await client.search(request)
    // Append secondPage.symbols, deduplicating by id if maintaining a combined list.
}
let languages = try await client.supportedLanguages()
```

The convenience search returns the first page, up to 50 symbols. Use `AACStandardSearchRequest` for pagination. The client accepts page sizes 1–100 as a conservative package limit, nonnegative offsets, and valid offset arithmetic. Search terms are trimmed and encoded using URLComponents; blank terms cause no network request. Region suffixes are removed from language identifiers; syntactically valid two-letter codes pass through, allowing future service languages.

## Design and reuse

- Follows `ARASAACClient`'s `search`, `download`, metadata-plus-image-data result, and all-or-nothing ordered batch semantics. The picker uses the same completion and `maxSelections` conventions as ARASAAC and Dynavox.
- Follows Dynavox's injectable async search-service boundary, main-actor observable picker model, debounce, and request identity checks. `AACStandardServing` supports deterministic mocks or a host-owned service. A cancelled or superseded search/page cannot replace the latest results or surface a stale error.
- Keeps provider-specific transport and response decoding separate. It does not depend on Dynavox's database, `SharedSwiftUI.ImagePickerItem` synchronous renderer, ARASAAC's licensing, or app-specific `PhotoItem` persistence. Extracting a common provider UI would require changing existing packages and is outside this package's scope.
- `AACStandardSymbol` is Codable, Hashable, Identifiable, and Sendable. Save it alongside image data to retain provider ID, language, and original URLs. `sourceURL` points to the documented symbol metadata endpoint; the public search response does not include the website's human-readable slug.
- `AACStandardClient` accepts a URLSession, honors its cache configuration, and uses standard HTTP cache policy. It does not automatically retry HTTP 429 responses; `AACStandardError.throttled` preserves the raw Retry-After header (seconds or HTTP date) for host policy. No API key, credentials, catalog mirror, or bundled artwork is required.

## API contract and limits

Verified against the [developer documentation](https://aacstandard.com/developers) and live responses on 2026-10-02:

- `GET /api/v1/public/symbols/search`: `q`, `language`, optional `age_group`, `limit`, `offset`.
- Search envelope: `success`, `data` (symbols), `count` (page count, **not a total**).
- Symbol fields: integer `id`, `name`, `language_code`, `image_url`, optional `thumbnail_url`.
- `GET /api/v1/translations/languages`: `success`, `data` containing language codes.
- PNGs are downloaded from the returned image URL; there is no ARASAAC-style URL synthesis. Image URLs must be HTTPS without embedded credentials, and downloaded bytes must decode as PNG.

The service supplies no total or next-page token. A full page exposes `nextOffset`; a short/empty page stops pagination. An exactly full last page incurs one final empty request. Search results may overlap as the remote catalog changes; the picker deduplicates IDs. The service's full API reference is still in preparation, so request/response fixtures and explicit errors protect against silent contract changes. Network/decoding errors propagate; HTTP errors and `success: false` never masquerade as an empty result.

Search queries are sent to aacstandard.com. An internet connection is required. The package does not implement offline indexing, speech/audio, recoloring, character variants, or provider-wide search aggregation.

## Rights and integration

The [AAC Standard licence](https://aacstandard.com/license) distinguishes personal, therapeutic, and educational uses from commercial products. Commercial app use requires separate permission; library redistribution also requires a separate agreement. Public API availability is not a commercial licence. Confirm the applicable permission before shipping this provider in either production app.

The picker links to the terms and displays `AAC Standard · © aisay.co`. This is source identification, not a claim that attribution grants permission. Hosts are responsible for applicable licence terms and retaining provenance in saved/exported content. Boardlet+ maps downloaded images and titles to PhotoItem and persists a distinct `aacStandard` source with symbol ID, language, image URL, and metadata URL. Source metadata survives copying, saving, and topic-image editing. Printed boards include AAC Standard credit, and Settings links to the terms. The shared persistence model recognizes the provider in both app variants, so existing boards remain readable without exposing AAC Standard search in standard Boardlet.

## Verification

Run from this package directory:

```sh
swift test -Xswiftc -strict-concurrency=complete
xcodebuild -scheme AACStandardSymbols \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath .build/xcode \
  -resultBundlePath .build/AACStandardSymbols-ios-tests.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

Use a fresh result-bundle path for each Xcode run. All generated build artifacts belong in the ignored `.build` directory. Tests use an injected per-client transport and actor-based controlled responses; they do not require network access or touch Photos. Coverage includes the API envelope, escaping, language normalization, pagination, HTTP/rate-limit errors, malformed data, PNG validation, ordered batch failure, selection limits, cancellation, stale responses, and pagination retries.

Boardlet+ integration build and test commands, results, and coverage limits are recorded in [INTEGRATION.md](INTEGRATION.md).
