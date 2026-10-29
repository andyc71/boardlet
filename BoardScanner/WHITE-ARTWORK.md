# White action artwork — 28 October 2026

**Historical fix, superseded:** the later screenshot comparison established that the source provides dark card backgrounds. The symbol backing described below has been removed at the user's request. The importer now retains source card colours; see [communication layout and source styling](COMMUNICATION-LAYOUT.md).

The supplied Motor Plan 66 page set reported one unavailable image after symbol-library recovery, yet QuickFires, Keyboard, Word Forms, Dashboard and the Home action card appeared blank. All five images were present and successfully rendered. Their source artwork is white on transparency, and the app displayed it on white cards.

The original page set and symbol library were inspected read-only. Rendering their WMFs with the app's renderer produced these results; every visible pixel in each preview was white:

| Action | Asset key | Preview size | Visible white pixels (alpha > 16) |
| --- | --- | --- | --- |
| QuickFires | `1495` | 224 × 158 | 17,024 |
| Word Forms | `1496` | 224 × 191 | 10,189 |
| Keyboard | `SYM:43561` | 224 × 158 | 13,540 |
| Dashboard | `SYM:43557` | 224 × 224 | 21,538 |
| Home | `SYM:43560` | 224 × 224 | 16,664 |

`ArtworkImage` detects near-white artwork with transparency using a bounded 32 × 32 sample, unpremultiplying alpha for edge-color comparisons. It gives that artwork a charcoal backing. Colored and black artwork, opaque images, and empty images keep their existing presentation. Cards, button details/editors, the message strip and message editors share the presentation. Original assets and cached previews remain unchanged, so existing saved boards gain the correction without reimporting or regenerating previews.

The missing-image count remains one: symbol `57513` (cupcake) is absent from the supplied sources. White artwork is available artwork and must not inflate that count. This corrects presentation; it does not claim exact reproduction of TD Snap's original card styling.

## Verification

The build succeeds on the existing iPhone 18 Pro simulator running iOS 27.0. Eight unit tests pass: three presentation tests (including rendered-pixel contrast assertions), and five symbol-library tests including all five real source assets, preservation of original data/previews and a complete export/reopen. Both native-authoring UI tests pass, covering picture editing, cancellation/removal, communication and persistence.

`White-Artwork-1.xcresult` records those ten passes and one failure in a newly added UI assertion: Dashboard was below the initial viewport, so expecting it to be immediately hittable was incorrect. `White-Artwork-2.xcresult` passes the supplied-file import/save/reopen/reimport journey after scrolling to Dashboard. Its screenshots confirm the white symbols' backing, including the Home card after reopening, but clip the top of Dashboard and catch a landscape transition. The final screenshot check additionally requires the entire Dashboard card inside the viewport and uses the display screenshot API. App implementation is unchanged between these runs.

VoiceOver activation remains deferred at the user's request; no physical-device operations are included.

`White-Artwork-3.xcresult` completes the final supplied-file UI journey with **one pass, no failures/skips, exit 0**. The full Dashboard glyph, Home card after reopening, and portrait/landscape action artwork were visually inspected in retained screenshots. Across the focused runs, all eight unit tests and all three selected UI journeys pass; the earlier incorrect viewport assertion remains recorded as a historical failure. The app still reports exactly one unavailable image and reuses the remembered symbol library on a subsequent fresh import.

Artifacts: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-white-artwork/`. Diagnostic WMFs and PNGs were rendered under `/tmp/board-scanner-artwork-audit/`.

Exact commands, from the repository root:

```sh
xcodegen generate --spec BoardScanner/project.yml
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-white-artwork/White-Artwork-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  '-only-testing:BoardScannerTests/ArtworkImageTests' \
  '-only-testing:BoardScannerTests/SnapSymbolLibraryTests' \
  '-only-testing:BoardScannerUITests/TDSnapUITests/testSuppliedLibraryRecoverySaveAndRestore' \
  '-only-testing:BoardScannerUITests/NativeAuthoringUITests' \
  test CODE_SIGNING_ALLOWED=NO \
  TD_SNAP_FIXTURE='/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' \
  TD_SYMBOL_LIBRARY='/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3' \
  > /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-white-artwork/White-Artwork-1.log 2>&1
```

The supplied-file UI follow-ups use the same build and input files, with only that test selected:

```sh
for run in 2 3; do
  xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
    -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
    -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/DerivedData \
    -resultBundlePath "/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-white-artwork/White-Artwork-$run.xcresult" \
    -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
    -test-timeouts-enabled YES -collect-test-diagnostics never \
    '-only-testing:BoardScannerUITests/TDSnapUITests/testSuppliedLibraryRecoverySaveAndRestore' \
    test CODE_SIGNING_ALLOWED=NO \
    TD_SNAP_FIXTURE='/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' \
    TD_SYMBOL_LIBRARY='/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3' \
    > "/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-white-artwork/White-Artwork-$run.log" 2>&1
done
```

The loop abbreviates two separately executed commands; the test-only screenshot refinements were applied between runs 2 and 3.
