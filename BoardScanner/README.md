# Board Scanner

The app’s display name is **Board Scanner**. Its app icon is the supplied artwork in `App/Assets.xcassets/AppIcon.appiconset`; `project.yml` selects this asset for the standalone app target.

A standalone iPhone/iPad SwiftUI AAC app that creates communication boards and converts a screenshot of a regular choice board into separate picture crops and editable labels, and imports TD Snap `.sps` page sets with their full page hierarchy, and provides AAC speech and message composition. Open `BoardScanner.xcodeproj` and run the **BoardScanner** scheme. The development bundle ID is `com.brightblue.BoardScanner.development`; it coexists with PECS Maker and Boardlet.

Requires Xcode 26 or later for Swift's `@concurrent` support. The app retains **iOS 16.6** deployment support and uses Swift 6 strict concurrency. No packages, network services, API keys or production project changes are required. Device builds use automatic signing with the same development team as PECS Maker (`633764X8QU`). Simulator builds disable signing through an SDK-specific setting. To run on your phone, open `BoardScanner.xcodeproj`, select the BoardScanner scheme and your phone, and run. Xcode must be signed into an Apple account with access to that team; it may need to create or refresh the development provisioning profile.

## Communication

Boards open in **Communicate** mode. Page navigation and the page title share one compact bar. A black Speak card with white artwork and text leads the message area and changes to Stop during speech. Speak, Delete and Clear share the active imported/native board’s cell dimensions and column spacing; narrow layouts keep the strip horizontally scrollable. Delete and Clear follow the message; the redundant pencil, keyboard and phrase buttons are removed from this strip. Imported Keyboard cards still open typing. Board management and communication settings are in **Board options**; save/import status is shown in Edit. Tap a screenshot card or an imported vocabulary button to add its spoken message (or its label when no message is supplied) to the picture sentence strip. **Speak** reads the entire message; **Stop**, **Undo**, **Clear**, and **Type** support conversation and correction. The message stays intact while navigating pages. Hidden screenshot cards and hidden imported placements are inactive in communication mode. Opening another document clears the current conversation.

Use **Board options → Edit board** to access imports, crop review, grid adjustment, saving and export. Screenshot cards support a separate spoken message. Imported buttons support label/message editing and an explicit communication action; the original command payload remains preserved; explicit link edits update the saved destinations. Tap **Communicate** to return to speaking. Saving/exporting retains these edits with the board.

**Communication settings** controls voice, speed, speaking each selection, and clearing after pressing Speak. Settings are saved on the device. Speech uses AVSpeechSynthesizer and the installed system voices; no app speech service is required. Speech stops when the app becomes inactive. The conversation and last-message recall are session-only. **Phrases** saves common text messages across boards and app launches; the pencil beside the sentence strip edits individual selections, with Organize for removal/reordering and Add last message for reuse. See [phrases and message correction](PHRASES.md).

Use **Communication settings → Access** for step/automatic scanning, repeat filtering and larger buttons. Scanning includes page navigation and message commands; Space selects, Command–Left/Right steps, Command–S speaks and Command–period stops. See [access controls and adaptive layouts](ACCESS.md) for behavior, keyboard scope and verification, and [maximum-size layouts](EXTREME-LAYOUT.md) for the combined text/button-size and rotation checks.

Speaking sheets keep **Stop speaking** visible and support Command–period. Opening an editor or settings stops the previous utterance. A speech request that cannot be cancelled is discarded before accepting another message. See [speech cancellation and accessibility checks](SPEECH-ACCESS.md), including the opt-in `BoardScannerSpeechEngine` integration scheme.

An isolated **I** uses an English pronunciation hint so it is spoken as the pronoun rather than expanded to “capital I”. The displayed and composed text stays unchanged; full sentences and non-English voices keep normal synthesis. See [pronunciation verification](PRONUNCIATION.md).

The imported schema-4.20 single-command mappings cover add message, speak this button, Speak, Clear, Delete last selection, Stop, Home, Back, and Keyboard. Page links keep their existing navigation/choice behavior. Unknown or compound commands show button details rather than speaking a control label. These mappings are based on the supplied file; they do not claim full TD Snap runtime compatibility. An explicit action in Edit overrides imported behavior without deleting it.

See [AAC acceptance](ACCEPTANCE.md) for the completed implementation review, verification evidence and explicitly deferred checks, and [AAC history](AAC.md) for the retained milestones and results.

## Create boards and pages

Choose **Create (+) → New board** for a blank grid or common starter words. New boards open in Edit. Use **Options** to add pages or change page settings, and tap empty cells to add buttons. The button editor supports Photos, Files and built-in symbols, spoken messages, page destinations, actions, position, span and visibility. Changes autosave. For screenshots, **Edit → Create (+) → Make editable copy** creates a native board while keeping the original in the library. See [the authoring guide](AUTHORING.md) for shared-button behavior and validation.

## Use

1. Choose **Photos** or **Files** to import a PNG, JPEG or HEIC screenshot. Photos uses the repository's shared system picker and importer by source reference; it does not request access to the whole library.
2. Choose **Edit** to inspect **Choice board** and **Detection**. Blue outlines mark card boundaries; green outlines mark picture crops. The reconstructed board uses SwiftUI image and text views, keeping original grid positions.
3. Choose **Edit**, then tap any card to edit its label or spoken message, clear it, adjust its four crop margins or hide it. Hidden cards retain their position and can be restored by tapping their placeholder. A review flag means missing/low-confidence OCR or ambiguous text placement; it is not a guarantee that unflagged content is correct.
4. If detection fails, choose **Adjust grid**, set rows/columns and board margins, and align the preview. Cell inset removes narrow gutters. **Rebuild** reruns OCR and replaces current card edits.
5. Imports and completed edits save automatically to the **Board library**. Open the library from the top toolbar to switch boards, rename, duplicate, or move a board to **Recently deleted**; deleted boards can be restored. The last selected board reopens on launch. **Save** remains available for an explicit save/retry, and **Export** writes the current board or whole page set as a self-contained `.boardscan` document to Files. Open that document using Files in the app or the system’s Open In action.

The Photos and Files import controls keep their text labels at large text sizes. Swipe their row horizontally when it is wider than the screen.

The library keeps previous saved revisions and can recover an earlier version if the current file is damaged. Failed imports leave the current board available; a failed edit save keeps the edit in memory, reports **Unsaved**, and prevents switching away until saving succeeds. The old single-slot save is copied into the library on first launch and retained unchanged. See [library storage and verification](LIBRARY.md).

**Try a sample board** generates a screenshot locally and runs the same parser as an imported image. It is not a precomputed reconstruction.

## TD Snap page sets

Choose **Files** and select a `.sps` file, or use Open In from Files. Import reads the SQLite database on a background task with a read-only connection. Nothing is uploaded and the original file is not modified. The importer is verified against the supplied **Motor Plan 66 - Napa 2026 - V1** export, schema **4.20**; other TD Snap schemas with different table structures are rejected with an import error.

- Opens the default home page. Tap a linked button to follow its destination, use **Back** to retrace the path and **Home** to return to the root. Multiple destinations, including conditional links, appear as a choice in button details.
- **Pages** searches every imported page, including disconnected pages, keyboards and message-bar pages. The model is a graph, retaining shared children, cycles and missing destination IDs without duplicating pages or recursively expanding them.
- Keeps every stored layout, grid position, merged cell span and hidden placement. **Options** switches layouts and shows hidden buttons. The default layout matches the page or page-set grid where available. Content beyond the declared viewport remains scrollable. In Edit, long-press a button for its full label, message and destinations.
- Imports all button labels and messages directly; no OCR is performed. TD Snap action payloads are preserved as data. Supported single commands are translated into native communication actions; arbitrary payloads are never executed. Speech and button editing are available. Dynamic vocabulary, conditional-expression evaluation and other TD Snap runtime commands are not implemented.
- Embedded PNG/JPEG artwork and supported Windows WMF/EMF artwork are displayed. A bounded native Swift/Core Graphics renderer generates transparent, sRGB previews up to 224 pixels for metafiles on the background import worker. Original vector bytes are retained. Unknown drawing operations, malformed images and library-only symbols absent from the file remain explicit placeholders. **Import details** separates rendered/failed embedded assets from buttons referencing absent assets. See [metafile support and verification](METAFILE-VALIDATION.md) for the supported subset and limits.
- Card background, text and border colours are imported from the source, along with page backgrounds. Symbols keep their original transparency with no added black patches. The grid sizes itself to the exported rows, columns and spans, retaining scrolling when larger text or small screens require it. Earlier saved imports need reimporting from the original `.sps` to recover colours that were not previously stored. See [communication layout and source styling](COMMUNICATION-LAYOUT.md).
- **Save** and **Export** retain the **whole page set**, regardless of the currently displayed page. Reopening restores the home page and all pages, layouts, links and assets. Opening an older version-2 document regenerates missing metafile previews from its preserved originals on the background worker; the imported copy saves the regenerated previews automatically. Screenshot cropping and grid rebuilding are available only for screenshot imports.

### Restore artwork from a symbol library

After opening a TD Snap page set, choose **Edit → Options → Import symbol library…** and select the original TD Snap `.db3` symbol database in Files. The app reads only missing `SYM:` IDs, renders matching images in the background, and reports restored button images and remaining unavailable images. Recovery saves automatically; use **Export** to make an external backup. The saved board includes the recovered original artwork and PNG previews; it does not need the library again when reopened. The original library remains read-only. A private copy is remembered on this device and applied automatically to future `.sps` imports, including after restarting the app. Import each library once on each device; libraries imported by older app versions need importing once again. Identical files are deduplicated. Repeat for another library if needed; already displayed artwork is preserved. Saved boards remain self-contained. If a remembered library cannot be read, the board still imports and the status asks you to import the library again.

The supplied `SymbolsSnapCoreFoundation.db3` restores **147 symbols used by 418 buttons**. Only **cupcake (symbol 57513)** remains absent. The recovered document is **73,557,847 bytes**, below the unchanged 80 MB limit. See [symbol-library verification](SYMBOL-LIBRARY-VALIDATION.md).

The example has **307 pages, 428 layouts, 6,687 placements, 5,382 buttons and 700 destination references**. Of those references, 698 come from `ButtonPageLink` and two additional destinations occur in serialized conditional commands. **165 stored references point to just two absent IDs**: 164 belong to single Home commands and one to a single Keyboard command. These commands now take precedence over their historical page references: Home returns to the imported home page, and Keyboard opens Type a message. They therefore do not represent 165 broken navigation links. Genuine unavailable page destinations remain reported. Original IDs and command payloads are preserved, including when reopening existing saved boards. The file includes 2,764 assets: 26 PNG/JPEG images, 2,730 WMF images and eight EMF assets. All 2,764 embedded assets now have previews in this example. The remaining 419 unavailable-artwork buttons reference assets absent from the export; 165 historical page references remain preserved without appearing as broken navigation. Source artwork is always retained. See [the role-command correction and verification](ROLE-LINKS.md).

The implementation uses the supplied database as format evidence; it does not assume that `.sps` is a ZIP archive. [Tobii Dynavox's page-set overview](https://www.tobiidynavox.com/blogs/support-articles/understanding-backups-page-sets-syncing-and-page-bundles-in-td-snap) describes page sets as containing all pages and page-set preferences; it is not a public SQLite schema specification.

## Detection and image processing

- ImageIO normalizes EXIF orientation, bounds decoding to 2,560 pixels on the longest edge and produces an upright PNG.
- Filled card surfaces are detected against the surrounding background first. Repeated-size surfaces establish a sparse grid, preserving genuinely empty positions without inventing cards. Toolbar controls with different geometry are excluded.
- Horizontal and vertical dark-pixel projections identify repeated long grid edges when filled surfaces do not establish a grid. Similar-size candidates form a regular row/column lattice. Narrow gaps and nested symbol rectangles are filtered; missing cells within a sufficiently supported lattice retain their positions.
- If repeated edges do not establish a grid, `VNDetectRectanglesRequest` provides candidate rectangles. `VNDetectContoursRequest` adds approximately rectangular contours if rectangles alone are insufficient. These are the Vision request classes available at the deployment target; the newer Swift `DetectRectanglesRequest` naming would require newer OS availability.
- `VNRecognizeTextRequest` uses accurate recognition and automatic language detection. Text is assigned to cells by geometry. Top/bottom label bands are preferred; multiline labels are ordered into a single editable string. Confidence is retained per card. Missing/low-confidence captions are retried on an enlarged individual card; if accurate OCR returns nothing, the fast recognizer can recover short words such as “is” and “it”, using the board's inferred language when supported.
- Label bounding boxes determine the picture crop, including padding. When a bottom caption exists, text in the upper picture (such as “NHS”, “a” or “A-Z”) is retained as artwork and flagged for review. Isolated stray punctuation before a readable caption is excluded and also flagged. Ambiguous center text and insufficient remaining picture area also trigger review.
- The pipeline uses normalized **top-left** coordinates throughout. Vision coordinates are flipped once at the request boundary. Image cropping, the overlay and document coordinates use that same convention.
- Vision and image processing run off the main actor with `@concurrent`. Cancellation is checked between requests and in loops; an in-flight Vision request may finish before cancellation takes effect. Cancelled or superseded work cannot publish a result.

Relevant Apple references: [rectangle detection](https://developer.apple.com/documentation/vision/vndetectrectanglesrequest), [contour detection](https://developer.apple.com/documentation/vision/vndetectcontoursrequest), and [text recognition](https://developer.apple.com/documentation/vision/vnrecognizetextrequest).

## Files and boundaries

A version-1 `.boardscan` file is JSON containing board dimensions, per-card row/column, editable label, OCR confidence, review/visibility flags, an optional `isEmpty` marker for unoccupied positions, original cell bounds, picture crop bounds, individual PNG data and the source PNG. `Data` fields use JSONEncoder's Base64 representation. Keeping the source allows later crop correction. The file is self-contained; it is **not** a production PECS Maker board archive. Geometry, counts, positions, unique IDs, version and decoded images are validated when reopening. Files above 80 MB are rejected.

Version-2 `.boardscan` JSON stores a page-set graph and a shared asset dictionary. Optional per-button `communicationAction` and per-screenshot-card `message` fields preserve AAC edits while keeping earlier documents readable. Version-1 screenshot files remain readable and continue to export as version 1. Both formats have an 80 MB file limit; page sets also have bounded page, layout, placement and asset counts, with IDs, home-page references and geometry validated on import/reopen. Missing destination IDs are retained intentionally, rather than rejected or silently discarded. Unsupported image formats remain original data, with validated PNG previews only for supported artwork.

Screenshot detection scope is straight, axis-aligned screenshots with a regular grid of up to 12 × 12 cells. There is no perspective correction, irregular/merged-cell screenshot detection or production app integration. Symbol replacement is available in a native editable copy. Text inside artwork can be mistaken for a label. Very faint borders, dense boards and low-resolution text may need manual grid/crop correction. Full missing rows/columns cannot reliably be inferred automatically. Card styling and typography are recreated in the app's own style rather than copied pixel-for-pixel.

Six supplied screenshots were imported through the real Photos picker on 27 October 2026. See [real-screenshot validation](VALIDATION.md) for the exact commands, per-board counts, label comparisons, retained crop sheets and limitations. The originals remain in the existing iPhone 18 Pro simulator’s Photos library. Cloud-photo downloads and physical-device behavior remain unverified.

## Build and test

Run from the repository root. `project.yml` is the XcodeGen source; the generated project and shared scheme are checked in. After adding sources or changing settings:

```sh
xcodegen generate --spec BoardScanner/project.yml
```

Build/test on the existing iPhone 18 Pro, iOS 27.0, with artifacts on the external SSD:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/DerivedData \
  build CODE_SIGNING_ALLOWED=NO

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/Tests-2.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 90 \
  -test-timeouts-enabled YES test CODE_SIGNING_ALLOWED=NO
```

The **BoardScannerRealPhotos** scheme separately runs the six Photos-import UI tests and the native photo-artwork authoring journey. These require the supplied originals in the simulator library; the tests deliberately scope selection to the observed six-photo timestamp. The ordinary **BoardScanner** scheme excludes that class and needs no seeded library. See [the validation guide](VALIDATION.md) before repeating the real-photo run.

The **BoardScannerVoiceOverInput** scheme runs isolated toolbar and system Settings input probes, including element-targeted and screen-centre coordinate taps, excluded from the ordinary suite. The landscape activation failure also reproduces in the iPad simulator's Settings app; see [the input investigation](ACTIVATION.md). Functional VoiceOver traversal and page-focus tests remain in the ordinary suite.

The **BoardScannerFileArtwork** scheme verifies native Files image selection and saved artwork after relaunch. Seed one uniquely named generated PNG with `python3 BoardScanner/Scripts/seed-artwork.py <simulator-UUID>` and pass its printed filename as the `BOARD_SCANNER_ARTWORK_FIXTURE` build setting. This opt-in class is excluded from the ordinary suite. Exact commands and evidence are in [the authoring guide](AUTHORING.md#actual-files-artwork-import--28-october-2026).

The **BoardScannerFileBackup** scheme exercises export and restore through the native Files pickers using a newly authored two-page board. It creates a unique `BoardScanner-Backup-<UUID>.boardscan` in the simulator's local Files location and restores into a separate test library. It is excluded from the ordinary suite because it leaves a generated backup in Files. See [backup verification](LIBRARY.md#native-files-backup-and-restore--28-october-2026) for commands, results and scope.

Choose a new result-bundle path for subsequent runs. Unit tests exercise actual Vision recognition, image crop OCR, top/bottom labels, gutters, fallback detection, missing cells, orientation, manual grids, malformed documents and cancellation. UI tests scan/edit/save screenshots and import/navigate/save/restore a generated TD Snap fixture, using an isolated test library (and unique per-test libraries for library-management journeys). It does not seed/delete the simulator's Photos library.

Production schemes and the picker harness are unaffected by this separate project's source membership.

## Verification on 26 October 2026

The test command above completed with **TEST SUCCEEDED** on Xcode 27.1 and the existing iPhone 18 Pro running iOS 27.0: **12 unit tests and 1 UI test, zero failures**. The standalone build command above also completed with **BUILD SUCCEEDED**; its log is `build-final.log`. Results and the retained reconstructed-board screenshot are in `Tests-2.xcresult`; console output is `test-2.log` beside it in the external build directory. `git diff --check` passed.

The first build exposed a Swift type-inference issue between `CGFloat` key paths and `Double` arrays; explicit conversions fixed it. The initial UI test inserted text at the beginning of a label and stalled waiting for its incorrect expected result. That run was stopped; an accessible clear-label action and corrected test passed on the complete rerun. These initial runs are not counted as passes.

Xcode emitted test-framework minimum-OS linker warnings (its XCTest libraries require iOS 17 while the app targets 16.6), App Intents metadata-skip warnings, and simulator OS-build-version diagnostic messages. They did not prevent the iOS 27 run. At that point, runtime behavior on iOS 16.6, physical hardware, actual Photos/Files picker selection and the unavailable example screenshots had not been verified. The subsequent Photos validation is recorded separately below. The contour fallback is implemented but is not separately forced by the fixture suite; the small-board test exercises the Vision fallback path.

## Verification on 27 October 2026

All six Photos-import UI tests passed, followed by the corrected Descriptors check and **14 unit tests + 1 UI test** on the final code. All 296 labels match ignoring capitalization, with four case differences recorded. See [VALIDATION.md](VALIDATION.md) for validation using all six supplied screenshots, fixes for dark backgrounds and sparse grids, the complete label comparison, and the latest unit/UI test results. This supersedes the earlier generated-fixture-only coverage for screenshot import.

## TD Snap verification — 27 October 2026

The local test fixture is generated by `TestSupport/SnapTestFixture.swift`; the supplied personal page set is not bundled in the app or committed to the repository. `TD_SNAP_FIXTURE` is an optional test build setting propagated through the shared scheme. Without it, the two supplied-file integration tests skip; the generated-fixture tests still run. Debug builds accept `--ui-testing --import-test-document <path>` solely for UI-test import setup; release builds omit this entry point.

Commands run from the repository root:

```sh
xcodegen generate --spec BoardScanner/project.yml

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-import/DerivedData \
  build CODE_SIGNING_ALLOWED=NO

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-import/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-import/Tests-3.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 90 \
  -test-timeouts-enabled YES test CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps'
```

Initial standalone build: **BUILD SUCCEEDED** (`build.log`). **Full suite: TEST SUCCEEDED — 21 unit tests and 3 UI tests, zero failures or skips**, in `Tests-3.xcresult` / `test-3.log`. The supplied page set round-trips to a 21,224,745-byte document; all 307 pages and 700 destination references survive. The importer reports 3,742 buttons with unavailable artwork. Tests cover cycles, shared/disconnected pages, conditional and missing links, hidden/merged/scrolling placements, malformed SQLite/geometry, invalid IDs/home/version, cancellation, unchanged source bytes, and complete export/save/reopen. Supplied-file tests assert the full inventory and image counts, search all 307 pages in the UI, and navigate to Food & Drink. Screenshot recognition and screenshot save/reopen regressions run in the same suite.

All build logs and result bundles are under the external `td-snap-import` directory above. Xcode 27.1, existing iPhone 18 Pro simulator, iOS 27.0. Physical devices, iOS 16.6 runtime, and Files-picker/Open In routing have not been exercised in this run. The UI tests use the real importer through a debug launch argument; they do not operate the document picker. No production app or shared picker source was changed.

After the final card-label layout, document identity reset and registered `.sps` type selection refinements, the focused suite passed again: **7 unit tests + 2 UI tests, zero failures or skips** (`Tests-4.xcresult`, `test-4.log`):

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-import/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-import/Tests-4.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 90 \
  -test-timeouts-enabled YES \
  -only-testing:BoardScannerTests/TDSnapImporterTests \
  -only-testing:BoardScannerUITests/TDSnapUITests \
  test CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps'
```

Test screenshots are retained in the result bundles. Xcode emitted its existing XCTest iOS 17 minimum-version linker and skipped App Intents metadata warnings; neither prevented the iOS 27 tests. `git diff --check` passed.

## Native metafile verification — 27 October 2026

The native renderer displays **2,730 WMFs + 8 EMFs**, alongside the **26 PNG/JPEG assets** in the supplied page set. **No embedded assets are unsupported in this file.** Unavailable button artwork falls from 3,742 to **419**, all due to absent source assets. The complete graph, raw assets and generated previews survive export/reopen in a **71,576,343-byte** document (under the unchanged 80 MB limit).

The expanded suite passed **30 unit tests + 3 UI tests**, including synthetic pixel assertions, malformed/cancellation cases, screenshot regressions, the supplied-file round trip, and page-set navigation. Final record-length and logical-pen-position refinements were followed by another **17 unit tests**, covering all metafile/import tests. Exact commands, result bundles, representative visual inspection, format references and remaining limits are recorded in [METAFILE-VALIDATION.md](METAFILE-VALIDATION.md). Earlier verification sections above describe historical runs.

VoiceOver traversal and explicit spoken command names are covered in [VOICEOVER.md](VOICEOVER.md), including the distinction between traversal evidence and unverified VoiceOver activation.

## Message action card verification — 28 October 2026

Speak/Stop, Delete and Clear now use black backgrounds with white symbols and labels. Imported/native page sets share one cell pitch between the action strip and vocabulary grid, including layout changes, Dynamic Type and the button-size setting. The whole available container is measured with `onGeometryChange`, so the message height does not feed back into its own measurement. Screenshot-board controls also receive the black labelled styling.

The following command built BoardScanner and passed `SpeechStripUITests` on the existing iPhone 18 Pro (iOS 27.0): one test, zero failures. It checks equal action/vocabulary cell sizes, row alignment, leading-column alignment, typing and Speak/Stop transitions.

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/message-card-alignment/DerivedData -parallel-testing-enabled NO '-only-testing:BoardScannerUITests/SpeechStripUITests' test CODE_SIGNING_ALLOWED=NO
```

Log: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/message-card-alignment/final-test.log`. Result: `DerivedData/Logs/Test/Test-BoardScanner-2026.10.28_18-07-58-+0000.xcresult` beneath that output directory. Production targets were unaffected and were not built. This focused run does not verify the full accessibility or rotation matrix.

## App icon verification — 28 October 2026

The supplied 1024 × 1024 opaque PNG is retained unchanged. Project generation and this simulator build passed (exit 0):

```sh
xcodegen generate --spec BoardScanner/project.yml
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-icon/DerivedData build CODE_SIGNING_ALLOWED=NO
```

The built app reports `Board Scanner` as its display name and `AppIcon` as its primary icon for both iPhone and iPad. The compiled asset catalog is present. Build log: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-icon/build.log`. No runtime code changed; no additional UI tests were run for this asset change.

## Native launch screen

`App/LaunchScreen.storyboard` displays the supplied icon at 160 points with the Board Scanner name underneath. Safe-area constraints centre the group on iPhone and iPad, including landscape; system background and label colours adapt to light/dark appearance. There is no launch timer or intermediate SwiftUI splash. `UILaunchStoryboardName` in `project.yml` selects it instead of the generated empty launch screen.

Verified on 28 October 2026: project generation and the following simulator build passed (exit 0), including Interface Builder compilation without storyboard warnings. The built app contains `LaunchScreen.storyboardc` and names it in its Info.plist. The transient launch display has not been visually captured on the simulator.

```sh
xcodegen generate --spec BoardScanner/project.yml
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-icon/DerivedData build CODE_SIGNING_ALLOWED=NO
```

Build log: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-icon/launch-build.log`.

## Device signing fix — 28 October 2026

Replaced the global signing disable with automatic device signing for team `633764X8QU`; only simulator SDKs now disable signing. Regenerated the Xcode project. The following device build passed (exit 0), and `codesign --verify --deep --strict` passed for the resulting app. No phone installation was performed.

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination 'generic/platform=iOS' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-icon/DeviceDerivedData build
```

Log: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-icon/device-signing-build.log`.
