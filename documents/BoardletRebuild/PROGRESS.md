# Boardlet implementation progress

Implementation owner: this chat. Started 2 October 2026 in the existing checkout. See `VERIFICATION.md` for exact commands and current evidence; `UPGRADE-PATH.md` documents release migration boundaries.

## Implemented

- Fresh `Boardlet/Boardlet.xcodeproj`, source/test tree and XcodeGen definition. Both development variants retain iOS 16.6. Swift 6 strict concurrency. Existing production files, shared picker implementation, package versions and pre-existing dirty work are preserved.
- Boards library, search, pin/order, rename, covers, duplicate, recoverable deletion and functional Blank/First and Then/Routine starters.
- Editor with adaptive canvas, contextual controls, card details, bulk labels, accessible reorder actions, multi-selection, copy, remove, duplicate, undo/redo and autosave. Wide containers show a native SwiftUI control panel; narrow/accessibility layouts use a sheet. The system inspector failed native iPad tests in SDK 27.0, so it is not used.
- ARASAAC search/download with attribution; shared system Photos picker by source reference; real camera integration; optional text cards; cancellation, progress, partial success and retry. Native Photos presentation/cancellation is exercised without changing the library.
- Card labels, replacement, oriented crop, background removal on iOS 17+, retained originals, source credits, recording permissions/cancellation/persistence and voice preview. Blocking audio session work runs on an actor; late permission and old delegate callbacks cannot start/resume a cancelled request.
- Use mode with fixed row/column/page positions, scroll overflow, tap/speak/message settings, repeated message entries, stop/remove-last/clear and optional exit confirmation. Messages clear on leaving Use mode; rotation/pages preserve them.
- Independent print model; multi-page PDF renderer and faithful PDFKit preview; actual native Print, Share PDF and Save images. Paper sizes/orientation, margins, grids, borders/colour/font/label/title settings, fixed aspect ratio, Fitzgerald borders and repeat-single-card settings are preserved. Attribution is exported on credit pages. SF Symbols are rasterized before PDF drawing.
- English/Spanish and privacy localizations, plural card/page counts, native controls, Dynamic Type, visible accessible alternatives to drag and a high-contrast preference.
- Codable board/card IDs, atomic manifests with previous-save recovery, immutable content-addressed media, complete archives, read-only legacy importer and an identity-gated first-upgrade path. Real nine-card Fruit fixture, generated audio fixture, missing assets, failed writes, repeated import and recovery are covered by behavioral tests.

## Architecture and compatibility decisions

The only package in the new project is the existing local ARASAACSymbols. No new third-party framework or package upgrade was introduced. The legacy PhotoBrowserData source contains conflict markers and its decoder has side effects, so migration reads the format independently and retains original JSON. Card ordering comes directly from stored photoItems; boards use the audited legacy name order. The old originals remain untouched. Separate development IDs do not imply cross-sandbox access.

Immutable media is not automatically purged, including when undoing or deleting cards. Deleted boards and their media remain available for recovery. Save failure leaves current edits in memory and offers Retry; failed load blocks editing. Only a validated manifest publishes imported boards.

## External integration blockers

Dynavox Plus search remains unavailable: resolving the production-pinned revision `0ce55497c94ce7b41ce9d58017b35dc5906cb498` with production pins and `-skipPackageUpdates` fails because the remote Git LFS object `2cc0c398696192a74bb5679db6974e28c45b7917671701a136b84730245c1d9d` for `SymbolsPcsSignLanguage-svg.zip` is missing. The broken package is excluded from the working project; no dependency upgrade was substituted. Existing rasterized cards still migrate and work offline. Log: `Boardlet/.build/resolve-plus.log`.

AI creation is implemented behind an injectable HTTPS service and secondary Plus UI when `BoardletAIEndpoint` is configured. No application-owned endpoint was supplied, so live generation is unavailable. No provider secrets were copied. These are unfinished external integrations, not completed variant parity.

## Platform limits

Installed Xcode 27.0 (27A266a), iOS SDK 27.0. Existing iPhone 18 Pro: `BB33297D-F833-464B-B43D-14CBD0DA3021`; existing iPad Pro 13-inch (M5): `E4B44237-C067-4F3E-881A-58024523D11F`. No Duo runtime/device or SDK 27.1 is installed. iOS 16.6 deployment is compile-checked; no 16.6 runtime test was available. Physical camera/microphone, actual AirPrint output, Personal Voice, assistive-technology traversal and the real production upgrade sequence still need device validation.

Automatic approval review rejected a proposed test-only deployment increase to iOS 17. No target was raised. The installed test frameworks emit newer-runtime linker warnings; this is recorded rather than silently changing platform support.

## Final verified state

The final source state builds for Boardlet and BoardletPlus. `release-candidate-check.xcresult` passed 48 expanded cases across iPhone light and iPad dark, with no failures/skips/runtime warnings. Final native screenshots verify editor, contextual controls, landscape communication and PDF rendering. Exact commands, retained screenshots and still-unverified platform/device behavior are in `VERIFICATION.md`. The app is usable for local workflows; external Plus integrations and release/device verification remain incomplete.
