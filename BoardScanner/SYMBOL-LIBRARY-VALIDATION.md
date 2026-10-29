# Symbol-library recovery — 27 October 2026

`SnapSymbolLibrary.supplement` reads a user-selected TD Snap SQLite symbol library with `SQLITE_OPEN_READONLY`, using the shared `SnapDatabase` wrapper. It requests only positive integer symbol IDs referenced by missing `SYM:` assets, in batches of 100. Existing embedded artwork, page IDs, labels, layouts, commands and links are unchanged. Successful previews use the existing bounded native renderer. Missing and unsupported symbols remain explicit. The library is not bundled, copied into a board, or required on reopen.

The worker runs with `@concurrent`, scopes file access for the operation, checks cancellation, validates the required SymbolId/Image schema, rejects duplicate rows, bounds the library to 1 GB and requested artwork/previews to 40 MB, and checks that the complete supplemented document can still export under the existing 80 MB limit before publishing it. Failure/cancellation leaves the current board unchanged. The UI exposes **Options → Import symbol library…**, then reports restored button artwork and the remaining unavailable count. Save/Export persists the result.

## Supplied-file result

Input page set: `/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps`.

Library: `/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3`, version 1.21.0.1, 23,507 symbols. This is a user-supplied resource, not a repository asset.

- 147 matching missing symbol IDs, all rendered: 145 WMFs and two EMFs.
- 418 buttons regain their original artwork; one unavailable image remains: **cupcake**, ID 57513.
- Total rendered assets: 2,911. Unsupported embedded assets: zero. Missing library references: one.
- 307 pages and 700 destination references remain; the same 165 destinations are absent from the original export.
- Export/reopen succeeds at **73,557,847 bytes**. Original embedded bytes and previews are unchanged. Recovered Home artwork survives reopening without the library.
- Ready-to-open result: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-symbol-library/Recovered.boardscan`.

## Verification

Generated fixtures test shared-asset recovery, preserving original artwork, ignoring unused library images, idempotence, archive round trips, unchanged source database bytes, malformed artwork, wrong schema and deterministic cancellation. The supplied-file test checks all 147 previews, the remaining missing ID, original-asset byte equality, graph inventory and filesystem export/reopen.

The UI test uses the debug-only `--symbol-library` argument with `--ui-testing` and `--import-test-document` to invoke the same worker. It checks the recovery count, the library menu action, import details, Save and relaunch without either source file argument. It retains a screenshot of the restored home page. This verifies the import pipeline and persistence; automated selection through the system Files picker and physical-device/iOS 16.6 runtime remain unverified.

Commands run from the repository root on Xcode 27.1, existing iPhone 18 Pro simulator, iOS 27.0:

```sh
xcodegen generate --spec BoardScanner/project.yml

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-symbol-library/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-symbol-library/Tests-3.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES test CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' \
  'TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3' \
  'TD_RECOVERED_OUTPUT=/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-symbol-library/Recovered.boardscan'
```

The initial focused run used the same project/destination/DerivedData/input settings, `Tests-1.xcresult`, `-only-testing:BoardScannerTests/SnapSymbolLibraryTests`, and omitted the timeout settings. **TEST SUCCEEDED: 3 tests, zero failures/skips** (`tests-1.log`). The optional `TD_RECOVERED_OUTPUT` setting retains the supplied-file result at the given path; omit it to use and delete a temporary export. Neither input file is modified.

The first full run (`Tests-2.xcresult`, `tests-2.log`) passed all 34 unit tests and the save/relaunch checks, but failed one UI assertion expecting an unformatted `2911` while SwiftUI displayed the locale-formatted count. The final UI check uses the `snapArtworkSummary` accessibility identifier and normalizes the thousands separator. No recovery or persistence failure occurred in that run.

Final full run: **TEST SUCCEEDED — 34 unit tests + 4 UI tests, zero failures/skips**, `Tests-3.xcresult` / `tests-3.log`. This command built the final app and tests with iOS 16.6 deployment settings. The earlier failed run stalled during post-test diagnostic collection and was interrupted after the final suite passed; use its text log for the original assertion failure, not its incomplete result bundle.

The final recovered home-page screenshot is `Attachments-3/C2F94A03-BF3F-4CFA-86D0-7BDAC87453B5.png`, exported with:

```sh
xcrun xcresulttool export attachments \
  --path /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-symbol-library/Tests-3.xcresult \
  --output-path /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-symbol-library/Attachments-3 \
  --test-id 'TDSnapUITests/testSuppliedLibraryRecoverySaveAndRestore()'
```

Visual inspection confirmed the previously missing “is” artwork appears on the home page, alongside the existing symbols and the one-unavailable-image count. Keyboard’s placeholder is removed, but its source symbol is white and blends into the current white tile background; the imported colors are preserved rather than substituted. The screenshot is after save/relaunch without a library argument. `git diff --check` passed. Xcode's existing XCTest minimum-version linker and App Intents metadata warnings did not prevent verification. No production targets or Photos databases were changed.

## Automatic recovery — 28 October 2026

Symbol-library imports now retain a private, content-hash-deduplicated database copy under the current board library's `SymbolLibraries` directory. Future `.sps` imports apply these libraries before saving or displaying the new board. The source remains read-only and is no longer needed after import. Existing boards remain self-contained; older app versions did not retain libraries, so those libraries must be imported once again. UI-test libraries use separate storage roots.

Copies are staged and validated with the existing bounded symbol renderer before publication. Cancellation and invalid databases leave no published copy. A failed remembered database does not discard the new board or successful recovery from other libraries; the completion status reports the failure. No symbol library is bundled in the app.

New unit coverage checks source deletion, a new store instance, content deduplication, failed-library reporting, invalid-library cleanup and cancellation. The supplied-file UI journey now imports Motor Plan again after restarting, without passing any symbol-library path, and asserts one remaining unavailable image.

Verification command (existing iPhone 18 Pro, iOS 27.0):

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-symbol-library/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-symbol-library/Automatic-2.xcresult \
  -parallel-testing-enabled NO \
  -only-testing:BoardScannerTests/SnapSymbolLibraryTests \
  -only-testing:BoardScannerUITests/TDSnapUITests/testSuppliedLibraryRecoverySaveAndRestore \
  test CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' \
  'TD_SYMBOL_LIBRARY=/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-symbol-library/Motor Plan 66 - Missing Symbols.db3'
```

The preceding `Automatic-1.xcresult` run used the same arguments with `-only-testing:BoardScannerUITests/TDSnapUITests` for all four page-set UI tests: **5 unit tests and 4 UI tests passed**. That run preceded the added cancellation assertion and fresh-reimport UI assertions.

The updated app was installed on the existing iPhone and iPad (A16) simulators. The user's 901,120-byte, 147-symbol subset was preloaded into each normal app library; SHA-256 and SQLite integrity were checked for both copies. No database is added to the app bundle or repository. Physical-device and iOS 16.6 runtime verification remain outstanding.

Final `Automatic-2.xcresult`: **5 unit tests + 1 UI test passed, zero failures**, including fresh import after relaunch with automatic restoration to one unavailable image. Console output: `automatic-2.log` beside the result bundle. The documentation diff check passed; the repository-wide check reports pre-existing trailing whitespace in the unrelated production `StartupWhatsNewView.swift`.

Result-collection limitation: after all six final tests reported passed, Xcode stalled in its child `simctl diagnose` collector. Only that run's diagnostic collector was terminated; `xcodebuild` then exited 65. The final test passes above are console evidence, not a successful overall command or a guaranteed complete result bundle. The earlier `Automatic-1` command finished with `TEST SUCCEEDED`. For subsequent runs, use `-collect-test-diagnostics never` to avoid this host diagnostic hang.
