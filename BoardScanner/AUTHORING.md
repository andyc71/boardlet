# Board and page authoring

Choice Board Scanner can create self-contained AAC boards without importing another file. This extends the [communication](AAC.md) and [recoverable library](LIBRARY.md) features.

## Workflow

- Choose **Create (+) → New board**, enter a name and grid size, and choose a blank grid or nine common starter words. New boards open in Edit and save automatically to the library.
- In Edit, **Options → Add page** creates another page and opens it. **Page settings** changes its name, grid and home-page status. Delete is available for pages other than Home, with confirmation. The last page cannot be deleted.
- Tap an empty cell or **Options → Add button**. Set the label, spoken message, picture, action, position, span and visibility. Empty spoken text uses the label. The starter “Stop” button speaks the word; assign **Stop speaking** if it should instead stop playback.
- **Choose picture** offers the shared system Photos picker, Files, and 24 built-in symbols. Selected images are normalized to PNG at up to 512 pixels. Generated symbols are embedded PNGs, so exported boards retain them.
- Choose the **Open page** action and a destination to make a navigation button. Home, Back, Speak, Clear, Delete, Stop, Type and immediate speech are also available. **Default behavior** follows the current links or supported imported command.
- **Remove from this layout** removes a placement, with confirmation. Shared instances on other pages/layouts remain available. Words, pictures and actions update all instances of the same button; position and visibility apply to the selected layout.
- For screenshots, choose **Edit → Create (+) → Make editable copy**. The original screenshot board stays in the library. Its copy has native editable buttons with the same pictures, labels, spoken messages, positions and visibility; it supports additional pages and buttons.
- Switch to **Communicate** to use the board. Relaunch opens the last saved board in communication mode. Export includes the entire page graph, actions and pictures.

## Preservation and validation

Changes are validated on a value copy before installation. Invalid destinations, colliding moves, out-of-range positions and invalid images leave the original unchanged. Hidden buttons, merged cells and imported message-window placements occupy their cells. Existing imported overlaps can receive words/artwork edits without moving their placements.

Grid resizing does not truncate existing buttons; positions beyond the declared grid stay scrollable. Small grids expose empty-cell add controls; larger grids use Add button. When a grid is full, Add button starts the next scrollable row, within the existing 256-position bounds.

Replacing artwork creates a new asset instead of overwriting an image shared by other buttons. Removing placements prunes only unreferenced native content; imported unreferenced content remains. Deleting a page removes its incoming destination references. A navigation button with no remaining destination becomes inactive; an explicitly assigned non-navigation action remains intact. Source command payloads are retained. Links deliberately edited or deleted by the author reflect those edits in exports.

The model saves changes through the existing revision library. Failed persistence keeps the edited document in memory marked Unsaved, with a retry path. The editor stays open when validation fails. Creation saves the new document before replacing the current screen.

## Verification

27 October 2026, Xcode 27.1, existing iPhone 18 Pro/iOS 27.0. Artifacts are in `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-authoring/`.

The standalone build passed (`Build-2.log`). Focused verification passed **8 unit tests and 1 UI journey**, zero failures/skips (`Tests-3.xcresult`, `Tests-3.log`, exit 0). The retained **Authored page and spoken message** screenshot was visually inspected: the saved water symbol, custom message, all conversation controls and page navigation are visible in portrait. The initial test run had an image-size assertion compile error; the next exposed a real new-page navigation handoff bug. Both were fixed before the successful run.

**Final iPhone regression: TEST SUCCEEDED**, exit 0, **66 passed, 5 optional supplied-file tests skipped, zero failures** (`Regression-1.xcresult`, `Regression-1.log`; 62 unit and 9 UI identifiers). This includes detection/OCR, document validation, TD Snap imports, metafile rendering, speech composition, library management and native authoring. **Final iPad authoring journey: TEST SUCCEEDED**, exit 0, **1 UI test passed** (`iPad-5.xcresult`, `iPad-5.log`, existing iPad A16/iOS 27.0). Initial iPad attempts exposed UI-test setup assumptions: a restored scene orientation, a keyboard that appears after typing and changes the sheet’s tap coordinates, and an action row virtualized below the sheet viewport. The test now normalizes the running scene, waits for/dismisses the keyboard, and scrolls the form. These adjustments do not change app behavior. Test coverage includes portable symbol artwork, transactional validation, hidden/merged cells, shared references, page deletion/home rules, screenshot-copy preservation, image normalization, and library relaunch. The UI journey creates a board, adds a page and pictured button, links a home button to it, relaunches, and composes the authored message.


Commands run from the repository root:

```sh
xcodegen generate --spec BoardScanner/project.yml
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  build CODE_SIGNING_ALLOWED=NO
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-authoring/Tests-3.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/AuthoringTests \
  -only-testing:BoardScannerUITests/NativeAuthoringUITests \
  test CODE_SIGNING_ALLOWED=NO
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-authoring/Regression-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-authoring/iPad-5.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/NativeAuthoringUITests \
  test CODE_SIGNING_ALLOWED=NO
```

The UI journey exercises built-in artwork; image normalization and invalid-image rejection are covered by unit tests. Photos/Files selection from the new artwork sheet, iOS 16.6 runtime and physical-device behavior are not established by this run. Shared picker sources and both production PECS Maker targets are unchanged. Remaining AAC work is tracked in AAC.md.

The iPad retains the existing orientation-declaration warning (upside-down portrait is not declared); Xcode also emits its existing XCTest minimum-OS and skipped App Intents metadata warnings. The successful authoring screenshots on both devices were visually reviewed. `git diff --check` and whitespace checks of new Swift files passed.

## Photo artwork follow-up — 28 October 2026

The focused native photo-artwork journey passed on the existing iPhone 18 Pro/iOS 27.0: **one UI test passed, exit 0**, in `board-scanner-activation/PhotoArtwork-4.xcresult` / `photo-artwork-4.log`. It creates an empty native board, cancels Photos and the artwork chooser without losing the draft, reopens Photos, selects only from the six supplied originals, saves the pictured button, relaunches the isolated library, composes its label and reopens its persisted artwork. The retained “Photo artwork retained after relaunch” screenshot was visually inspected and contains the supplied Food & Drink screenshot.

The first two attempts exposed a test selector that tapped the labelled switch row instead of its nested switch control. The third reached Photos but selected a Cancel button behind the picker. The final test uses the observed nested switch, asserts it is off, and scopes Cancel to the visible sheet's navigation bar. No app or shared picker changes were needed. The shared test driver remains unchanged; this nested-sheet journey scopes its cancellation locally.

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerRealPhotos \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-activation/PhotoArtwork-4.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/RealScreenshotUITests/testPhotoArtworkCancellationSelectionAndRelaunch \
  test CODE_SIGNING_ALLOWED=NO
```

Earlier attempts used the same command with `PhotoArtwork-1`, `PhotoArtwork-2`, and `PhotoArtwork-3` result paths. Files artwork selection, iPad photo-artwork interaction, physical-device behavior and iOS 16.6 runtime remain unverified. The full ordinary regression and physical-build preparation are recorded in [ACTIVATION.md](ACTIVATION.md).

## Files cancellation and artwork removal — 28 October 2026

The final focused journey passed on both existing simulators: iPhone 18 Pro (`board-scanner-activation/ArtworkChanges-5.xcresult`, `artwork-changes-5.log`) and iPad A16 (`ArtworkChanges-iPad-2.xcresult`, `artwork-changes-ipad-2.log`), each **one test passed, exit 0**. It opens and cancels the native Files picker, confirms that cancellation shows no import error, removes a picture and cancels the editor to prove the saved picture survives, then removes and saves it. Relaunch confirms the removal persisted and the word still composes a message. The retained iPhone removal screenshot was visually inspected.

The only app change is the `artworkImportError` accessibility identifier used to assert cancellation does not produce an error. Initial test attempts queried obscured Cancel buttons during remote-sheet presentation; the final test waits for the document manager navigation bar and uses its Cancel control on iPhone or the observed sidebar Cancel on iPad. `ArtworkChanges-1` through `-3` and `ArtworkChanges-iPad` retain these setup failures. `ArtworkChanges-4` is the earlier passing iPhone journey before the explicit error assertion.

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-activation/ArtworkChanges-5.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/NativeAuthoringUITests/testFilesCancellationAndArtworkRemovalCommitOnlyOnSave \
  test CODE_SIGNING_ALLOWED=NO
```

The iPad command is identical except for destination `platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0`, derived data `board-scanner-extreme-layout/DerivedData`, and result `board-scanner-activation/ArtworkChanges-iPad-2.xcresult` under the same external artifact root. This test belongs to the ordinary scheme. No existing Files documents were selected or modified.

## Actual Files artwork import — 28 October 2026

**One focused UI test passed, exit 0**, on iPhone 18 Pro/iOS 27.0 (`board-scanner-activation/FilesArtwork-1.xcresult`, `files-artwork-1.log`). The test uses the native Files picker to search for and select one uniquely named generated PNG, saves it on a button, relaunches its isolated library, composes the word and reopens the saved picture. The retained “Files artwork retained after relaunch” screenshot was visually inspected: it shows the fixture's cyan/purple halves, replacing the starter checkmark.

The opt-in **BoardScannerFileArtwork** scheme selects `FilesArtworkUITests`; the ordinary scheme excludes it. `Scripts/seed-artwork.py` discovers the existing simulator's local Files provider through `simctl listapps`, creates a 64×64 PNG with a UUID filename using exclusive file creation, and prints that filename. It does not replace or remove existing files, change Photos, or select existing documents. The generated image remains in the simulator's local Files storage for repeat runs; it is separate from app library data.

Exact preparation and test commands for the recorded run:

```sh
python3 BoardScanner/Scripts/seed-artwork.py BB33297D-F833-464B-B43D-14CBD0DA3021
# Printed: BoardScanner-Artwork-078be81c-1dd5-463a-ae48-42973e2c52ba.png
xcodegen generate --spec BoardScanner/project.yml
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerFileArtwork \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-activation/FilesArtwork-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO \
  BOARD_SCANNER_ARTWORK_FIXTURE=BoardScanner-Artwork-078be81c-1dd5-463a-ae48-42973e2c52ba.png
```

For a fresh seed, pass the newly printed filename and a new result-bundle path. Without a valid fixture filename, the opt-in test skips explicitly. This validates local Files image selection; cloud-provider downloads, iPad selection and physical-device file-provider behavior are not established by this run. The cancellation/removal tests above cover both iPhone and iPad. The earlier full ordinary regression predates these new tests and is not relabelled as a new full-suite pass. `git diff --check` and Python fixture-script syntax validation passed.
