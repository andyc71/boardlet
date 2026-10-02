# OpenSymbols search implementation

## Scope and entry points

`Packages/OpenSymbols` is a repository-owned Swift package with an iOS 16 minimum. It contains a Foundation client and a deterministic XCTest suite. It has no dependency on Dynavox or ARASAAC, and contains no symbol artwork. Unlike the ARASAAC package, it is not linked into either production target and does not present a picker yet. OpenSymbols requires a private shared secret, and this checkout has no trusted token service from which the app can request short-lived access tokens.

| File | Responsibility |
| --- | --- |
| `Packages/OpenSymbols/Sources/OpenSymbols/OpenSymbolsClient.swift` | Search, response decoding, HTTP validation, raster downloads, and attribution metadata. |
| `Packages/OpenSymbols/Tests/OpenSymbolsTests/OpenSymbolsClientTests.swift` | Mock network tests for search, tokens, errors, and downloads. |
| `Packages/OpenSymbols/Package.swift` | Standalone iOS 16 compatible library and test target. |
| `Packages/OpenSymbols/README.md` | Short usage example and token requirement. |
| `.gitignore` | Narrow exception so repository-owned `Packages/OpenSymbols` is included. |

## Authentication and search flow

The [OpenSymbols API documentation](https://www.opensymbols.org/api) says a shared secret is used at `POST /api/v2/token` to obtain a short-lived access token. It explicitly says the shared secret must not be put in compiled application code. A trusted server must hold the secret and provide tokens to the app. `OpenSymbolsClient` accepts an async `accessTokenProvider` closure; it does not accept or store the shared secret and does not call the token endpoint. No credential is committed in this repository.

1. `search(_:language:)` trims whitespace. Empty text returns an empty array without asking for a token or making a request.
2. A region-specific locale such as `es-ES` becomes the two-letter `es`; invalid language strings fall back to `en`. `URLComponents` encodes the query as the `q` parameter, with `locale` as a separate parameter. Safe search remains enabled by the API default.
3. The client requests `GET https://www.opensymbols.org/api/v2/symbols`, supplying the short-lived token in the `Authorization` header. It never puts the token in a URL. The API returns a top-level JSON array.
4. `OpenSymbolsSymbol` decodes the documented `id`, `symbol_key`, `name`, `repo_key`, `extension`, `image_url`, `details_url`, and credit fields. The relative details path becomes a web URL. A missing display name falls back to the symbol key.
5. An expired-token response (`401` with `token_expired: true`) throws `OpenSymbolsError.tokenExpired`; callers should obtain a fresh token and retry. A `429` throws `throttled`, and other non-success statuses carry their HTTP code. Transport and JSON decoding errors propagate.

The token provider is called for each nonempty search. Its owner can cache tokens on a trusted service, but must refresh them after expiration. Requests use an injected `URLSession` to permit testing without service access.

## Image downloads and attribution

OpenSymbols aggregates libraries with different licenses and image types. The client retains each result's license, license URL, author, author URL, source URL, and repository key so future persistence or export code can preserve attribution. It uses the API's `image_url` directly; it does not invent an image URL from the ID. The returned detail path can link users to the source listing.

`download(_:)` supports PNG, JPEG, and GIF, checking both HTTP status and file signature. SVG results throw `unsupportedImageFormat` before making a request; converting SVG to a form `PhotoItem` can persist requires an explicit rasterization design. Image URLs must use HTTPS. The access token is never sent to image hosts. Ordered batch download throws if any item fails and never returns a partial selection. OpenSymbols notes that image URLs are currently long-lived but may change, so callers should save downloaded bytes instead of depending on the remote URL.

No production selection UI or `PhotoItem` conversion was added. Before exposing OpenSymbols in the Plus source menu or topic-image chooser, supply a trusted token service, decide how SVG symbols should be handled, and preserve per-symbol credit and license data in saved/exported boards. OpenSymbols includes libraries with commercial and noncommercial terms, so a single blanket credit is insufficient.

## Test suite and verification

`OpenSymbolsClientTests` uses `URLProtocol` with an ephemeral session. It covers query encoding, locale handling, authorization placement, empty input, token-provider failures, malformed JSON, transport errors, token expiry, throttling, other HTTP errors, image URL handling, raster signatures, unsupported SVG, and ordered atomic batch downloads. No test calls OpenSymbols over the internet.

From `Packages/OpenSymbols`:

```sh
swift test
```

If the package is later linked to app targets, add the local package product to the appropriate target in `PECS Maker.xcodeproj`, build both production schemes after changes to shared files, and run relevant app tests on a disposable or otherwise safe simulator. Do not run `PECS MakerTests/SetupPhotos.swift` against a personal Photos library. Production build scripts may change Info plist build numbers and regenerate SwiftGen output; review those diffs after building.
