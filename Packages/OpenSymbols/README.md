# OpenSymbols

An iOS 16+ Swift package for searching the [OpenSymbols API](https://www.opensymbols.org/api) and downloading raster results. It has no app target dependency and bundles no artwork.

```swift
let client = OpenSymbolsClient(accessTokenProvider: {
    // Ask your own trusted server for a short-lived OpenSymbols access token.
    try await tokenService.openSymbolsToken()
})
let symbols = try await client.search("cat", language: "en-US")
let selected = try await client.download(symbols[0])
```

OpenSymbols requires a shared secret to mint tokens. Keep that secret on a trusted server; never include it in an iOS app, repository, or client request. The token provider runs for each nonempty search. If the service reports `token_expired`, refresh the token through the server and retry. Handle `throttled` as a rate limit.

Search results include license, author, repository, and source metadata. Retain those fields when saving or exporting an image. The download method accepts PNG, JPEG, and GIF; SVG results are reported as unsupported because this package does not rasterize them. It only downloads HTTPS image URLs and never forwards the access token to image hosts.

Run `swift test` from this directory in the local checkout. Tests intercept requests with `URLProtocol` and do not need a live token or network connection.
