# ARASAAC symbol search implementation

## Scope and entry points

`Packages/ARASAACSymbols` is a repository-owned Swift package with an iOS 16 minimum. It supplies a Foundation networking client and a SwiftUI picker. The package has no Dynavox dependency and contains no pictogram artwork.

Only the **Easy PECS Plus** production target links the package. When a board has no selected photos, its Main Menu shows **Symbol Search** above **Take Photo**; Symbol Search presents the ARASAAC picker. After the board has photos, both shortcuts disappear from the Main Menu. The **Change Selections** screen keeps camera and ARASAAC actions in its **+** menu regardless of the board's photo count. The topic-image screen offers Dynavox and ARASAAC as well. Dynavox continues to use its existing `DVSymbolPicker`. The **PECS Maker** production target still compiles shared app files but does not link ARASAACSymbols.

Relevant files:

| File | Responsibility |
| --- | --- |
| `Packages/ARASAACSymbols/Sources/ARASAACSymbols/ARASAACClient.swift` | Search request, decoding, HTTP validation, image downloads. |
| `Packages/ARASAACSymbols/Sources/ARASAACSymbols/ARASAACSelectionState.swift` | Ordered selection, deselection, and selection limits. |
| `Packages/ARASAACSymbols/Sources/ARASAACSymbols/ARASAACSymbolPicker.swift` | Search UI, debouncing, thumbnails, selection, download progress, retry and attribution link. |
| `PECS Maker/Extensions/View+selectSymbols.swift` | Presents the picker and converts completed downloads to `PhotoItem`s. |
| `PECS Maker/Views/Pages/MainMenuView.swift` and `PECS Maker/Components/MainMenuButton.swift` | Empty-board Symbol Search and camera shortcuts. |
| `PECS Maker/Views/Pages/PhotoListView2.swift` | Selected-photos source menu. |
| `PECS Maker/Views/Pages/Subviews/TopicImageSelector.swift` | Topic-image source chooser. |
| `PECS Maker/Views/SettingsViews/CreditsView.swift` | Plus-only ARASAAC credit. |
| `PECS Maker.xcodeproj/project.pbxproj` | Local package reference and Plus target product membership. |

## Search and selection flow

1. The picker reads the SwiftUI locale and searches in Spanish for `es`; other locales use English. Text is trimmed and percent-encoded as one URL path segment. Empty text makes no request.
2. `ARASAACClient.search(_:language:)` requests `https://api.arasaac.org/v1/pictograms/{language}/search/{term}`. The response is a top-level JSON array. Each symbol uses `_id` and `keywords`; the first keyword is its title, with the numeric ID as fallback.
3. The grid loads 300 px thumbnails from `static.arasaac.org`. `ARASAACSelectionState` retains selections across searches in tap order. A one-symbol limit replaces the previous topic-image selection; a larger limit rejects additional selections until a slot is freed.
4. The picker downloads selected 500 px PNGs in order. An HTTP error or response without a PNG signature aborts the batch, leaving the picker open for retry. Its completion receives the complete `[ARASAACSelection]` only after every download succeeds. Cancel returns an empty array.
5. The app converts PNG bytes to `UIImage` and then `PhotoItem`, recording the ARASAAC provider and pictogram ID. For a photo list it appends or replaces according to `AppSettings.photoPickerIsAdditive`; for a topic image it sets the first item. This is the same persistence path used by the existing symbol picker.

## Attribution in saved boards and exports

`PhotoItem.symbolSource` is optional so older boards decode unchanged. Imported ARASAAC items save their provider, numeric pictogram ID, and an edit flag. `PhotoItem.copy()` keeps this source through duplication and copying between topics. Replacing an item's image marks it as modified; editing its title does not. Explicitly chosen topic images store the same source in `PECSRepo.topicImageSymbolSource`.

When any board item comes from ARASAAC, every printable page reserves a narrow footer for the creator, owner, source URL, and CC BY-NC-SA license URL. The type is approximately 6 points at the 300 dpi printable size, with 0.2 inches of clearance from the page edge. A short note is added if an imported pictogram was edited. `CollageFactory` calculates the footer's height from the text and retains the selected paper size by reducing only the grid area. The shared printable rendering path feeds both image sharing and PDF creation. PDFs also make the footer region a link to the license. Boards without ARASAAC items have no footer. The search picker and Plus acknowledgements show the credit and link to ARASAAC's terms.

The picker uses a cancellable `.task(id:)` for debounced search. Its explicit download task is cancelled when the picker disappears. `URLSession` is injectable through `ARASAACClient.init(session:)`, so automated tests intercept requests without internet access.

## Localization and target membership

The package owns its English and Spanish `Localizable.strings` resources. The app's source-choice strings live in `PECS Maker/Resources/en.lproj` and `es.lproj`; `PECS Maker/SwiftGen/Strings.swift` is generated from the English file. Keep the package's deployment minimum compatible with the production app's iOS 16.6 target and check both production schemes when changing shared app files. `.gitignore` makes a narrow exception for this repository-owned package under `Packages/` while still ignoring downloaded package sources and package build artifacts.

## Test suite

`Packages/ARASAACSymbols/Tests/ARASAACSymbolsTests` uses `URLProtocol` to test the client with deterministic responses. Coverage includes search path encoding and locale fallback, successful and malformed decoding, empty queries, transport and HTTP failures, PNG validation, ordered batch downloads, and a batch failure after an earlier successful image. Selection tests cover tap order across searches, deselection, one-symbol replacement, limits, freed slots, and title fallback.

Run the standalone package tests from `Packages/ARASAACSymbols` on an available iOS simulator:

```sh
xcodebuild -scheme ARASAACSymbols -configuration Debug \
  -destination 'platform=iOS Simulator,id=<SIMULATOR-UUID>' \
  -derivedDataPath /tmp/pecs-arasaac-package-tests \
  CODE_SIGNING_ALLOWED=NO test
```

For app verification, build both `Easy PECS Plus` and `PECS Maker`. `PhotoItemTests` covers source metadata through copy, save, edit, and topic-image persistence; conditional PDF attribution and paper size; and the existing image-save behavior. Do not run the historical `PECS MakerTests/SetupPhotos.swift` on a personal simulator; it deletes Photos database content directly. The production build scripts may increment plist build numbers and regenerate SwiftGen output, so review the working-tree diff after building.

For a manual UI check in Plus: on an empty board, choose **Symbol Search** from the Main Menu, search, select items, and verify the resulting photo list. Confirm Symbol Search and Take Photo disappear from the Main Menu once the board has photos, while **Change Selections → +** still offers Camera and ARASAAC. Then choose **Use Another Symbol → ARASAAC** for a topic image and verify single selection. A live connection is needed for this check; the automated package tests do not use ARASAAC's service.

## Release considerations

Search terms and image requests go to ARASAAC's public servers. ARASAAC distributes pictograms under CC BY-NC-SA. Attribution is included in saved metadata and printable exports, but attribution alone does not grant commercial rights. Resolve distribution rights with ARASAAC before shipping this feature in a commercial product.
