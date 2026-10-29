# Board library

The scanner now keeps multiple screenshot boards and TD Snap page sets. The Library toolbar button is available in communication and editing modes. Imports and completed card/button/artwork edits save automatically; Save provides an explicit save/retry. Rename, Duplicate, Delete and Restore are available in the library. Deletion moves the complete board folder to Recently deleted; there is no automatic purge.

## Durability and recovery

- `Documents/BoardScanner/Library/Boards/<UUID>/` contains independently encoded `.boardscan` revisions, an atomic `index.json`, and a backup index. Library titles are capped at 500 characters in the compact index; the document’s original full title remains in its data.
- A save writes a new document file first, then atomically replaces the index. The preceding revision remains referenced. Revision files referenced by either current or backup indices are retained; unreferenced older files are cleaned up only after commit. Cleanup failure cannot invalidate the new save.
- All operations run on one library actor without suspension within filesystem transactions. JSON/image validation runs away from the main actor. Saves and moves are not cancellable after commitment starts. Parsing remains cancellable; incoming Open In requests wait until an active operation finishes.
- Reopening validates the document and image data. If the current revision fails, the library tries earlier indexed revisions and reports **Recovered a previous saved version**. Failed recovery leaves files untouched and keeps the entry visible so users can choose another board or import an external backup.
- `selection.json` records the last selected board. A missing/corrupt selected document reports an error while keeping the library accessible. A new import is saved before it replaces the current board. A failed save retains edited data in memory and blocks replacement until the save can succeed.
- If an incoming URL starts importing before startup restoration, restoration waits for that operation. A successful import remains selected; a failed import leaves its error visible and reopens the previously selected board. A cancelled restoration task does not mark restoration complete.
- `latest.boardscan` from the previous app is copied into the library, never deleted or rewritten. A persisted empty selection after deleting all boards prevents old data from being migrated back on the next launch.
- `Deleted/<UUID>/` holds restorable boards. Moving a board out of or back into this directory preserves revisions and IDs.
- Export still creates a portable single-board/whole-page-set `.boardscan` file, not a library bundle. Keeping an external backup remains useful if the app or device is removed. The library is local and does not synchronize across devices.

The screenshot/page-set document formats remain versions 1 and 2. Production PECS Maker and shared Photos-picker sources are unaffected.

## Verification — 27 October 2026

Artifacts are under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-library/`; the existing `board-scanner-aac/DerivedData` build cache is reused. All tests use temporary roots or an isolated UI-test library, never a personal photo library. The library UI journey uses `--ui-testing --library-id <UUID>`; this override is Debug-only and requires a UUID.

The first focused run passed all eight persistence/model tests. Its UI test failed because native iOS alerts expose the Rename field by placeholder but drop the SwiftUI accessibility identifier. The corrected test selects the observed **Rename board → Board name** field; it retains all behavior assertions. The complete library UI journey subsequently passed in 49.8 seconds during the full regression run, including autosave without pressing Save, importing another board, rename, duplicate, deletion/restoration, switching, and relaunch with the custom spoken message intact.

An initial standalone build encountered a name collision with the preexisting symbol-library error enum; the new error type is named `BoardLibraryError`. Later test builds compiled successfully. Final results are recorded below.

Commands from the repository root:

```sh
xcodegen generate --spec BoardScanner/project.yml
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-library/Tests-2.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 120 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
```

## Final results

- `Tests-2.xcresult` / `test-2.log`: **TEST SUCCEEDED**, exit 0; **55 passed, 4 optional supplied-file tests skipped, zero failures/runtime warnings** (59 identifiers). This is the full scanner/import/metafile/communication/library suite at that point.
- `Tests-3.xcresult` / `test-3.log`: after the final startup guard, export naming and index-title bound changes, **10 passed, zero failures/skips/runtime warnings** (9 unit tests and the full library UI journey).
- `iPad-1.xcresult` / `ipad-1.log`: **TEST EXECUTE SUCCEEDED**, exit 0; **1 full library UI journey passed** on the existing iPad (A16), iOS 27.0. The existing missing-upside-down-orientation warning remains; this change did not alter orientation declarations. iPhone and iPad library screenshots were visually reviewed and show all entries and controls without clipping.
- `Supplied-1.xcresult` / `supplied-1.log`: **1 supplied-file test passed**, zero skips, in 7.466 seconds. All **307 pages**, every button message/destination list, original asset bytes and preview PNG bytes match after library save/reopen; all **2,764 embedded previews** remain available. The source `.sps` was read-only.
- `Startup-1.xcresult` / `startup-1.log`: **10 unit tests passed**, zero failures/skips, after the Open In startup-race fix. An import arriving before restoration now migrates the legacy save first, leaving both boards in the library and the original legacy file unchanged.

The nine-test persistence/model set, later expanded to ten, covers multiple boards and selection across instances, damaged document recovery, damaged-index recovery, unrecoverable entries remaining visible, invalid/cancelled saves, delete/restore, old-save migration without resurrection after deletion, autosaved edits across switching/relaunch, write failure retaining edits, malformed import preserving the current board, and Open In racing initial restoration.

Final focused command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-library/Tests-3.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 120 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/BoardLibraryTests \
  -only-testing:BoardScannerTests/ScannerLibraryTests \
  -only-testing:BoardScannerUITests/BoardLibraryUITests \
  test CODE_SIGNING_ALLOWED=NO
```

The iPad run used the same command with destination `50F3CC1E-D723-4494-B2B3-39CAD32244C0`, result `iPad-1.xcresult`, only the `BoardLibraryUITests` selector, and `test-without-building`. The final startup run used the iPhone command with result `Startup-1.xcresult` and the two unit selectors only.

Supplied-file command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-library/Supplied-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 120 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/LibrarySuppliedTests \
  test CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps'
```

`git diff --check` and whitespace checks for the new library sources passed. No production target, shared Photos-picker source, or personal photo library was changed. Tests exercise simulated file damage/cancellation/write failure; physical power loss and iOS 16.6 runtime remain unverified. Native board/page creation, artwork/link authoring, reusable phrases and access-method work remain in the broader [AAC checklist](AAC.md).

## Native Files backup and restore — 28 October 2026

The opt-in **BoardScannerFileBackup** scheme runs `FilesBackupUITests/testExportAndRestoreIntoSeparateLibrary`. It authors a two-page board, changes Water's spoken message to “I want water”, and exports through the native Files picker into **On My iPhone/iPad**. It then launches an explicitly fresh, separate test library and finds the unique backup through the native import picker. Assertions verify the board title, the second page and Home navigation, composed spoken message, retained picture, and persistence after relaunch. No debug document-import argument, preseeded backup, or direct filesystem copy substitutes for either picker.

The test is excluded from the ordinary suite because a successful run leaves one uniquely named `BoardScanner-Backup-<UUID>.boardscan` in local simulator Files. It does not select or overwrite existing documents. Initial creation and import use `--fresh-start` to exclude migration of historical UI-test saves; the final relaunch omits that flag to exercise real library restoration. Its test libraries use distinct UUIDs. No app implementation changed for this verification; the new test source and opt-in scheme are included in the generated standalone Xcode project.

Artifacts: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-files-backup/`.

The iPhone 18 Pro / iOS 27.0 run **Phone-5.xcresult** / **Phone-5.log** passed one complete journey, exit 0, with zero failures, skips or runtime warnings. The restored-button screenshot was reviewed and shows the Water picture and “I want water” message.

After the cross-device picker corrections, the final iPhone run **Phone-7.xcresult** / **Phone-7.log** also passed one complete journey, exit 0, with zero failures, skips or runtime warnings. Its restored-button screenshot was reviewed. Phone-6 was an intermediate passing iPhone run. Phone-7 and iPad-5 execute the same final test source.

The iPad A16 / iOS 27.0 run **iPad-5.xcresult** / **iPad-5.log** passed the complete journey, exit 0, with zero failures, skips or runtime warnings. Its retained search and restored-button screenshots were reviewed: the uniquely named file is selectable, and the restored board contains two pages plus the custom message and picture. The final test handles the iPad name-filter popover and validates the local storage root regardless of whether the navigation title is hidden by the expanded sidebar.

Earlier development runs are retained as failures: Phone-1 used an incorrect navigation-bar identifier for the destination title; Phone-2 exported successfully but did not suppress legacy test-save migration into its new library; Phone-3 and Phone-4 matched both the covered Files browse collection and its visible search collection. The final query scopes selection to `DOCSearchControllerContainerViewIdentifier` when present and requires exactly one hittable filename match. iPad-1 stopped before export with the button editor and keyboard still open after the attempted save; the follow-up dismisses the observed iPad keyboard before tapping Save. iPad-2 exported successfully but stopped at the name-suggestion popover; the final journey submits Search before looking for the result, accommodating iPad's inline results presentation.

iPad-3 showed that Return hides the keyboard but leaves the name-filter popover; the test now taps its observed **Name Contains…** option when present. iPad-4 was already in local storage but failed the navigation-title assertion with the sidebar expanded. Destination validation now uses the observed `com.apple.FileProvider.LocalStorage` browsing-root identifier. These were test-driver corrections; the application source was unchanged.

Commands run from the repository root:

```sh
xcodegen generate --spec BoardScanner/project.yml
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerFileBackup \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-files-backup/Phone-7.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
```

Phone-1 through Phone-6 used that command with their corresponding bundle names. Logs are lower-case `phone-1.log` through `phone-4.log`, then `Phone-5.log` and `Phone-6.log`. The final iPad command was:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerFileBackup \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-files-backup/iPad-5.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
```

iPad-1 through iPad-4 used this command with their corresponding bundle names and matching log names. Scoped whitespace checks for the new test, project specification and updated documentation passed. The repository-wide diff check reports unrelated trailing spaces in existing `StartupWhatsNewView.swift` edits; those were left untouched.

These journeys cover local native-board backup and restore through Files. They do not establish cloud-provider sync, cross-device transfer, system Open In routing, or physical-device behavior. The full-suite counts elsewhere remain historical and are not relabelled as results of this focused run.

## Document URL launch and failed startup import — 28 October 2026

`OpenDocumentUITests` uses `XCUIApplication.open(_:)` to deliver actual file URLs to the app, without `--import-test-document`. It opens a generated `.sps`, communicates through its linked page, cold-opens an external version-2 `.boardscan`, checks both library entries and their distinct messages, cold-opens malformed data, and verifies that the prior board and exactly two library entries remain available. A final ordinary relaunch verifies the native board's saved selection and message. UUID test libraries and temporary fixtures isolate this from ordinary app data. The test is included in the ordinary BoardScanner scheme.

The initial `Phone-1` UI journey passed. A separate deterministic model test then exposed an ordering gap that the UI run had not encountered: when the invalid incoming import began before `restore()`, the old startup guard marked restoration finished while the model was busy. The failure left `libraryID` and the active document nil, even though the saved board was intact. `Startup-Baseline` failed the selected-board, title and entry-count assertions. Restoration now awaits the active operation before marking itself complete; if no incoming document was installed, it restores the selected saved board while retaining the import error. Existing valid-import/legacy-migration coverage remains in the selected regression.

These URL tests exercise delivery to Board Scanner and its restoration/import behavior. They do not prove that every other app's share sheet chooses Board Scanner, default-handler selection, cloud-provider handoff, physical-device routing, or hot delivery while an editor is open.

Artifacts and matching logs are retained in `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-open-document/`.

Exact startup-fix iPhone regression command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-open-document/Phone-2.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/ScannerLibraryTests \
  -only-testing:BoardScannerTests/BoardLibraryTests \
  -only-testing:BoardScannerUITests/OpenDocumentUITests \
  -only-testing:BoardScannerUITests/BoardLibraryUITests \
  test CODE_SIGNING_ALLOWED=NO
```

`Phone-1` used this command with its result name and only `BoardScannerUITests/OpenDocumentUITests`. `Startup-Baseline` used its result name and only `BoardScannerTests/ScannerLibraryTests/testInvalidOpenBeforeStartupRestoreRetainsSelectedBoard`.

Exact iPad command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-open-document/iPad-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/OpenDocumentUITests \
  test CODE_SIGNING_ALLOWED=NO
```

Results:

- `Phone-2`: 13 passes (11 model/persistence tests and two UI journeys), no failures/skips/expected failures, exit 0. This verifies the startup fix. The URL journey reported a runtime warning when dismissing the error alert.
- `iPad-1`: one URL journey passed, exit 0, with the same dismissal warning. Its library screenshot was inspected and shows both retained entries.
- The alert's OK action already clears the published error. Its presentation binding now avoids publishing nil again when SwiftUI dismisses that already-cleared alert.
- `Phone-3` and `iPad-2`: the final URL journey passed on each device, exit 0, no failures/skips/expected failures or result-summary runtime warnings. The final iPhone screenshot was inspected and shows the two retained entries and the active imported board. These final focused runs follow the alert-binding change; they do not replace the wider `Phone-2` regression result.

The exact final iPhone command is the `Phone-2` command above with result bundle `Phone-3.xcresult` and only `-only-testing:BoardScannerUITests/OpenDocumentUITests` (remove the other three selectors). The exact final iPad command is the iPad command above with result bundle `iPad-2.xcresult`. Matching log names are `Phone-3.log` and `iPad-2.log`. Project generation was `xcodegen generate --spec BoardScanner/project.yml`; source membership includes the new UI test in the existing ordinary scheme. Scoped whitespace checks passed.
