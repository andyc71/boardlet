# Maximum-size communication layouts

## Behavior

Communication grids measure their own width and flexible scrolling viewport height with `onGeometryChange`. Tile dimensions follow Dynamic Type and the user's Button size setting, up to the space available to display a complete choice. Imported layouts retain original rows, columns, hidden gaps and spans; the largest span determines the per-cell limit. A 44-point minimum target remains. Larger boards still scroll in both axes. Editing retains its existing size behavior.

For merged imported buttons, the minimum target is calculated from the smallest displayed button span, rather than treating every underlying cell as a separate target. Hidden placements do not constrain communication sizing. Short tiles bound their artwork, use the horizontal picture/label arrangement, and allow labels to scale down to half their preferred Dynamic Type size when necessary. The scan marker is also bounded by the tile height. Original positions and spans remain unchanged.

Native/imported pictures move beside their labels when the vertical arrangement will not fit. Screenshot communication tiles choose the vertical picture/label arrangement when it fits, otherwise center a horizontal group. Pictures retain explicit dimensions; centering keeps them clear of the scan marker in short cells. Screenshot communication grids now also use `SourceGridLayout`: real cell coordinates allow scrolling to reveal the whole highlighted tile in both dimensions. The focused choice is brought back into view after a viewport resize or rotation.

In compact-height scanning, screenshot board titles share the scan-control row instead of consuming a separate row. At accessibility text sizes the scan row prioritizes the choice name, omitting the visible “Select:” prefix and page-title text. Start and command choices use short visible labels (Start, Back, Home, Stop, Speak, Undo, Clear) in either orientation. The Select accessibility label still identifies the action and choice; its value carries the page title. Page navigation and keyboard operation remain available.

The speech status bar uses a horizontal arrangement when it fits and stacks its status above a full-width Stop button in narrow layouts. Its accessible name remains “Stop speaking”. Large-text message and phrase entry fields show two to three lines at once and scroll internally, keeping the rest of the sheet reachable while retaining the complete text.

## Verification — 27 October 2026

Artifacts live in `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/`.

The new journeys combine the largest accessibility text size, 2× Button size, step scanning, the last board choice and landscape. They compare the highlighted tile's full frame with its intersection in the scroll viewport in both dimensions, rotate to portrait and back while retaining focus, and select the word into the message. Separate coverage exercises speech cancellation in Phrases with the largest text size across rotation. Screenshots are retained using `XCUIScreen.main.screenshot()`.

The baseline capture showed oversized, clipped native tiles. That initial test also failed its expected last-choice label after a rapid sequence of synthesized keyboard events. The layout journey now uses the visible Next button; dedicated keyboard regression remains separate. The first screenshot-board height-only assertion passed but visual review exposed horizontal clipping and a missing picture. The final test checks both dimensions; explicit cell coordinates and reserved image dimensions correct those defects. Later image review showed the compact picture could still sit beneath the large scan marker. The final tile centers its picture/label group and chooses its arrangement with ViewThatFits.

The default and maximum-size native layout journeys passed in `Fit-1.xcresult`. Screenshot maximum-height and ordinary communication/edit journeys passed in `Fit-2.xcresult`; the limited height-only capture from that run is not evidence of full visibility.

The rotation checks wait up to five seconds for the full target to be inside the viewport before making their final frame assertions. iPhone orientation notifications arrived while the measured frames were still partway through the rotation animation; the first immediate assertions failed on those transient frames.

The first large-text speech-sheet test passed its hittability check, but visual inspection exposed the portrait Stop label wrapping into a tall column. A control-height assertion now guards that defect, alongside screenshot review. The first iPad attempt timed out while entering a long message. The adaptive entry viewport allowed that stage to finish on the next run, which then exposed a phrase-save setup problem with the onscreen keyboard. The bounded phrase editor still showed the save problem in iPad-Speech-3; the intended keyboard-dismissal test change had not been applied to that method. iPad-Speech-4 explicitly dismisses the keyboard and verifies that the phrase editor closed.

## Completed runs

| Run | Result and scope |
| --- | --- |
| Phone-1 | 11 UI journeys passed, exit 0. Precedes the final complete-frame, compact-picture and speech-bar refinements. |
| Phone-2 | Four journeys passed, including keyboard stepping through all nine choices. Two immediate rotation frame assertions failed during the animation. |
| Phone-3 | Four passed, exit 0: native/screenshot full-frame rotation and maximum/default-text speech cancellation. Zero runtime warnings. Screenshot review then prompted the final compact-picture and portrait-label refinements. |
| iPad-1 | Both full-frame grid journeys passed. Maximum-text speech journey timed out during long text entry. |
| iPad-Speech-2 | Default-text phrase/recall/background journey passed; maximum-text phrase saving failed. |
| iPad-Speech-3 | Maximum-text phrase saving still failed; keyboard-dismissal setup was absent. |
| iPad-Speech-4, Phone-Speech-4 | One maximum-text speech journey passed on each device, exit 0, including the final bounded phrase editor and keyboard-dismissal setup. |
| Phone-Grid-5, iPad-Grid-5 | Three / two passed, exit 0: native and screenshot full-frame rotation on both devices, plus keyboard stepping on iPhone. Final portrait scan labels were visually reviewed; screenshot-picture placement receives the follow-up below. |

Final screenshot-picture results: **Phone-Cards-6: 2 passed; iPad-Cards-6: 1 passed; both exit 0**. The final iPhone landscape capture visibly contains the full Help tile, hand picture, label and focus marker; the normal portrait capture retains all six pictures and labels. The final grid, speech and screenshot result summaries (`Phone-Grid-5`, `iPad-Grid-5`, `Phone-Speech-4`, `iPad-Speech-4`, `Phone-Cards-6`, `iPad-Cards-6`) each report zero unexpected failures and zero runtime warnings.

The iPhone stacked Stop bar and iPad portrait/landscape Stop captures were visually reviewed. The original native contrast-audit discrepancy is unchanged and remains recorded in SPEECH-ACCESS.md; these functional runs do not replace that audit.

## Commands

All commands run from the repository root. Final rotation/speech focused command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/Phone-3.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/AccessUITests/testMaximumTextAndButtonSizeKeepLandscapeScanChoiceVisible \
  -only-testing:BoardScannerUITests/AccessUITests/testScreenshotBoardAtMaximumSizeInLandscape \
  -only-testing:BoardScannerUITests/SpeechAccessUITests/testMaximumTextKeepsPhraseSpeechStopVisibleAcrossRotation \
  -only-testing:BoardScannerUITests/SpeechAccessUITests/testSpeechCanBeStoppedFromPhraseAndRecallSheetsAndAfterBackgrounding \
  test CODE_SIGNING_ALLOWED=NO
```

`Baseline` used the native maximum-size selector only. `Fit-1` added `AccessUITests/testLandscapeScanScrollsFocusedTileIntoView`. `Fit-2` selected the screenshot maximum-size journey and `CommunicationUITests/testScreenshotCommunicationAndEditingAreSeparate`. `Phone-1` selected all `AccessUITests`, all `CommunicationUITests`, and the maximum-text speech rotation journey. `Phone-2` selected the two maximum-size grid journeys plus `AccessUITests/testKeyboardStepsThroughEveryChoiceAtMaximumText`, `AccessUITests/testAccessibilityTextKeepsBoardAndActionsReachable`, `AccessUITests/testScanPageLinkAndReturnWithoutLosingMessage`, and `CommunicationUITests/testScreenshotCommunicationAndEditingAreSeparate`. Each uses its matching result-bundle name in the same artifact directory.

`iPad-1` used destination `platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0`, DerivedData `board-scanner-extreme-layout/DerivedData` on the same external SSD, and only the two maximum-size grid tests plus the maximum-text speech rotation test. `iPad-Speech-2` used that same destination/build path and only the two SpeechAccessUITests selectors listed above. `iPad-Speech-3` and `iPad-Speech-4` selected only the maximum-text speech test with the same iPad command settings. `Phone-Speech-4` selected that test with the iPhone command settings.

The final grid runs use the command above with result names `Phone-Grid-5` / `iPad-Grid-5`, only the two AccessUITests maximum-size grid selectors, plus `AccessUITests/testKeyboardStepsThroughEveryChoiceAtMaximumText` on iPhone. The iPad run uses the iPad destination and separate DerivedData path described above. All use `test CODE_SIGNING_ALLOWED=NO` and the same timeout/diagnostics flags. The screenshot-picture follow-up uses `Phone-Cards-6` with `AccessUITests/testScreenshotBoardAtMaximumSizeInLandscape` and `CommunicationUITests/testScreenshotCommunicationAndEditingAreSeparate`; `iPad-Cards-6` uses the same maximum-size screenshot selector only. Destination, DerivedData, flags and `test` action follow the corresponding phone/iPad commands above.

These result names describe separate runs, not repeats overwriting previous evidence.

## Scope

The earlier simulator journeys exercise the built-in native starter board and sample screenshot board; the follow-up below adds sparse imported merged buttons. They do not establish every arbitrary imported spanning layout, every label length or every resizable-window dimension. In particular, retaining source proportions and a minimum target size can still require scrolling when a layout combines very large spans with single-cell buttons. Existing VoiceOver/physical switch traversal, physical speech routing/offline voices, and iOS 16.6 runtime gaps remain tracked in AAC.md and SPEECH-ACCESS.md. This work does not change production PECS Maker targets or the shared Photos picker.


Final repository diff and standalone whitespace checks passed. No source files were added to app/test targets in this follow-up, so existing Xcode source membership remains sufficient. The existing XCTest deployment and skipped App Intents metadata warnings remain; iOS 16.6 runtime coverage is not implied.

## Imported merged-button follow-up — 28 October 2026

Artifacts: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-merged-access/`.

The new `AccessUITests/testImportedMergedChoicesRemainVisibleAndSelectableAcrossRotation` imports a generated TD Snap database with a 3×3 button at row/column 5 and a 2×2 button at row/column 9, beyond its declared initial viewport. A hidden single-cell placement must neither appear nor constrain the visible button sizes. The journey uses maximum Dynamic Type and 2× button size, scans to both choices, asserts complete frame visibility and at least 44-point targets, rotates while retaining focus, and composes “I want water Please help me”. Its final fixture embeds a blue drop image in both choices.

`Baseline.xcresult` failed: the three-row button was 148 points high inside a 131.3-point landscape viewport. Its retained screenshot confirms clipping. `Fit-1.xcresult` passed after changing the minimum cell calculation, but image review exposed the smaller button's label and scan indicator overflowing its bounds. `Fit-2.xcresult` passed with embedded artwork, bounded picture/label content and an indicator height limit. All three Fit-2 screenshots were reviewed. The final marker uses a bounded font glyph rather than a resizable symbol; subsequent runs below include this refinement.

The existing iPad A16 / iOS 27.0 run, `iPad-Merged.xcresult` / `iPad-Merged.log`, passed **3/3** journeys with zero failures, skips or runtime warnings: imported merged choices, the maximum-size native starter board, and the maximum-size screenshot board. Retained merged, native and screenshot landscape captures were reviewed for picture, label and focus-marker visibility.

The final existing iPhone 18 Pro / iOS 27.0 run, `Phone-Regression.xcresult` / `Phone-Regression.log`, passed **12/12** journeys, exit 0, with zero failures, skips or runtime warnings in its result summary. It covers all nine access journeys and all three communication journeys, including keyboard scanning, automatic/manual scan suspension, linked-page navigation, screenshot/native layouts, separate editing and communication, and spoken-message save/relaunch. The final merged, native and screenshot landscape captures were visually reviewed. The iPad run also exited 0. These are focused regressions, not a rerun of the entire suite.

Exact iPhone regression command from the repository root:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-merged-access/Phone-Regression.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/AccessUITests \
  -only-testing:BoardScannerUITests/CommunicationUITests \
  test CODE_SIGNING_ALLOWED=NO
```

`Baseline`, `Fit-1` and `Fit-2` used the same iPhone command and flags with their respective result-bundle names and only the new merged-choice selector. Their logs are `baseline.log`, `fit-1.log` and `fit-2.log`.

Exact iPad command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-merged-access/iPad-Merged.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/AccessUITests/testImportedMergedChoicesRemainVisibleAndSelectableAcrossRotation \
  -only-testing:BoardScannerUITests/AccessUITests/testMaximumTextAndButtonSizeKeepLandscapeScanChoiceVisible \
  -only-testing:BoardScannerUITests/AccessUITests/testScreenshotBoardAtMaximumSizeInLandscape \
  test CODE_SIGNING_ALLOWED=NO
```

No source files were added, so target membership remains unchanged. App edits are confined to the standalone scanner's grid, tile and focus-marker views. This does not resolve the separate cross-app landscape VoiceOver activation failure in ACTIVATION.md or establish physical-device behavior.

Changed-file whitespace checks passed. Repository-wide `git diff --check` reported trailing spaces in unrelated existing edits to `PECS Maker/Views/Startup/StartupWhatsNewView.swift` (lines 13 and 16); those edits were left untouched.
