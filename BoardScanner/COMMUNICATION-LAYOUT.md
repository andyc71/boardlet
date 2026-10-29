# Communication space and exported styling — 28 October 2026

The user supplied a TD Snap screenshot and requested more space for communication, accurate source colours and card sizing, and removal of the added black symbol backgrounds.

## Behaviour

- Page title, Back, Home and Pages occupy the navigation bar. Board options contains Edit board, the library, New board and communication settings. The app title, separate page heading and management buttons no longer occupy additional communication rows.
- The speech row starts with Speak (replaced by Stop during speech), followed by the message, Delete and Clear. Controls use the board-card dimensions in regular height. In compact vertical size class (iPhone landscape), the message and action cards are half a board card's height, with smaller icons and padding. The board uses the released vertical space. Compact mode hides the navigation toolbar and places the speech row in the left two-thirds, with the page title to its right. The empty message area has no visible placeholder. Keyboard remains available through its board card.
- Both board grids, the speech row and its message use size-based horizontal bounce behaviour: fitting content stays still, while overflowing content remains scrollable.
- Import/save status and management tools appear in Edit. The existing editor and welcome-screen tools remain available.
- The imported grid divides its available viewport using the source row and column count. The default minimum cell pitch is 64 points wide and 72 points high, scaled by Dynamic Type and the user's button-size setting. Eight-point gutters separate cards. Smaller screens scroll instead of compressing every card below usable sizes. Oversized merged cards are bounded so the selected card can fit in the viewport during scanning.
- Background, text and border ARGB colours are retained per button. Page backgrounds and the page-set background fallback are also retained. Artwork has its original transparency: no automatic black patches are added.

## Source evidence and limits

The Motor Plan 66 SQLite export specifies `GridDimension = 11,6`, page-specific `PageLayoutSetting`, per-card `GridPosition` and `GridSpan`, and `ElementReference.BackgroundColor` / `ForegroundColor`. The four left-hand action cards use background `#504E53`, foreground `#FDFBFA` and border `#888A8C`. The page-set background is `#28262A`. Signed 32-bit ARGB values are decoded without losing alpha.

These are grid units and colours, not fixed device pixel dimensions. The export also has relative font and margin settings; their TD Snap rendering semantics are not reproduced here. App fonts, corner shapes, spacing and navigation indicators remain native choices, so this is not a pixel-for-pixel clone of the screenshot. Source colours, placements and spans are no longer guessed.

Colour fields are optional in `.boardscan` archives. Older archives remain readable, but they cannot recover colour metadata that the previous importer discarded. Reimport the original `.sps` to get its source colours; preserve any existing edited board separately. New imports retain colours through saving/export/reopening. Inputs remain read-only.

## Verification

Artifacts are under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/`. Each result bundle has a same-named log.

| Run | Result and interpretation |
| --- | --- |
| `Models-1` | Nine model tests complete; one test has two failed assertions because its expected page-colour literal was mistyped (`28282A` instead of `28262A`). The process lingered after the recorded results and was terminated. The expectation was corrected. |
| `Phone-1` | All nine importer/artwork tests pass, including actual source colours, grid metadata, archive compatibility and transparent pixels. Subsequent UI checks were interrupted after exposing an identifier-propagation regression in the new message container and interference from another task using the same iPhone simulator. |
| `iPad-1` | All eight authoring model tests pass. UI portion interrupted before the message-identifier correction. |
| `iPad-2` | Six UI journeys pass: all four communication journeys and both native-authoring journeys. Three failures remain in this run: merged-card test's final orientation wait; large-text settings helper scrolling past its slider; supplied-file import/grid wait. The redundant identifier on the message container was removed before this run. |
| `iPad-Layout-3` | **Two passes, zero failures/skips, exit 0.** Actual Motor Plan import, portrait/landscape layout, all 66 cards visible in landscape, message selection/clear, menu-to-edit and Save pass. Maximum-text/maximum-button-size scanning and rotation pass after fixing the helper to return to the Access section when needed. App implementation is unchanged from `iPad-2`. |

The iPad grid occupies **88.3% of window height in portrait** and **83.2% in landscape** (820 × 1180 and 1180 × 820 points). All 66 landscape cards remain inside the viewport with targets at least 44 × 44 points. Retained screenshots were visually inspected; source-coloured backgrounds and white action symbols are visible without symbol backing patches.

The final actual-file check records elapsed import time and permits 90 seconds. It completed in **7.33 seconds** in the passing run. A separate manual import exceeded the earlier wait while still progressing: a process sample captured symbol recovery and JSON archive encoding, followed by successful display. That is evidence of slow import work, not proof of the exact cause of the earlier test timeout. The final test also locates the grid by identifier regardless of its accessibility element type.

The existing iPhone SE (3rd generation), iOS 18.2, provided the small-screen check while the default iPhone 18 Pro was occupied by other app work. `SE-1` passes merged-card scanning across orientations and the real-board layout/message assertions, then fails an immediate Save-hit-test assertion during the Edit transition. `SE-Editor-2` passes an isolated landscape Edit/Save journey with a bounded wait for the toolbar. `SE-Layout-3` passes the complete actual Motor Plan journey with that wait (**one pass, zero failures/skips, exit 0**). App implementation is unchanged across these runs. The SE grid occupies **75.4% in portrait and 74.4% in landscape**, with scrolling for content beyond the usable card sizes. Screenshots were reviewed. The SE was returned to its original shutdown state.

The focused passing coverage comprises 17 model tests, six communication/authoring UI journeys, the iPad grid and maximum-text scan journeys, and the SE merged-grid, editor-transition and real-board journeys. This does not relabel the earlier interrupted or failed runs as clean suite passes.

VoiceOver activation remains deferred. No physical-device operation was performed. The production PECS Maker targets and shared Photos picker sources were not changed for this work.

## Commands

Project membership was regenerated with `xcodegen generate --spec BoardScanner/project.yml`. The following are the exact Xcode command lines retained in each run log (run from the repository root); log redirection is omitted.

Models-1:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/DerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/Models-1.xcresult -parallel-testing-enabled NO "-only-testing:BoardScannerTests/TDSnapImporterTests" "-only-testing:BoardScannerTests/ArtworkImageTests" "-only-testing:BoardScannerTests/PageSetAuthoringTests" test CODE_SIGNING_ALLOWED=NO "TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps"
```

Phone-1:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/DerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/Phone-1.xcresult -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 -test-timeouts-enabled YES -collect-test-diagnostics never "-only-testing:BoardScannerTests/TDSnapImporterTests" "-only-testing:BoardScannerTests/ArtworkImageTests" "-only-testing:BoardScannerUITests/CommunicationLayoutUITests" "-only-testing:BoardScannerUITests/CommunicationUITests" "-only-testing:BoardScannerUITests/AccessUITests/testMaximumTextAndButtonSizeKeepLandscapeScanChoiceVisible" "-only-testing:BoardScannerUITests/NativeAuthoringUITests" test CODE_SIGNING_ALLOWED=NO "TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps" "TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3"
```

iPad-1:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/iPadDerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/iPad-1.xcresult -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 -test-timeouts-enabled YES -collect-test-diagnostics never "-only-testing:BoardScannerTests/AuthoringTests" "-only-testing:BoardScannerUITests/CommunicationLayoutUITests" "-only-testing:BoardScannerUITests/AccessUITests/testImportedMergedChoicesRemainVisibleAndSelectableAcrossRotation" test CODE_SIGNING_ALLOWED=NO "TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps" "TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3"
```

iPad-2:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/iPadDerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/iPad-2.xcresult -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 -test-timeouts-enabled YES -collect-test-diagnostics never "-only-testing:BoardScannerUITests/CommunicationLayoutUITests" "-only-testing:BoardScannerUITests/CommunicationUITests" "-only-testing:BoardScannerUITests/AccessUITests/testImportedMergedChoicesRemainVisibleAndSelectableAcrossRotation" "-only-testing:BoardScannerUITests/AccessUITests/testMaximumTextAndButtonSizeKeepLandscapeScanChoiceVisible" "-only-testing:BoardScannerUITests/NativeAuthoringUITests" test CODE_SIGNING_ALLOWED=NO "TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps" "TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3"
```

iPad-Layout-3:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/iPadDerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/iPad-Layout-3.xcresult -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 -test-timeouts-enabled YES -collect-test-diagnostics never "-only-testing:BoardScannerUITests/CommunicationLayoutUITests" "-only-testing:BoardScannerUITests/AccessUITests/testMaximumTextAndButtonSizeKeepLandscapeScanChoiceVisible" test CODE_SIGNING_ALLOWED=NO "TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps" "TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3"
```

SE-1:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/SEDerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/SE-1.xcresult -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 -test-timeouts-enabled YES -collect-test-diagnostics never "-only-testing:BoardScannerUITests/CommunicationLayoutUITests" "-only-testing:BoardScannerUITests/AccessUITests/testImportedMergedChoicesRemainVisibleAndSelectableAcrossRotation" test CODE_SIGNING_ALLOWED=NO "TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps" "TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3"
```

SE-Editor-2:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/SEDerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/SE-Editor-2.xcresult -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 -test-timeouts-enabled YES -collect-test-diagnostics never "-only-testing:BoardScannerUITests/CommunicationLayoutUITests/testLandscapeOptionsOpensEditor" test CODE_SIGNING_ALLOWED=NO
```

SE-Layout-3:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/SEDerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/SE-Layout-3.xcresult -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 -test-timeouts-enabled YES -collect-test-diagnostics never "-only-testing:BoardScannerUITests/CommunicationLayoutUITests/testMotorPlanUsesCommunicationSpaceAndSourceGrid" test CODE_SIGNING_ALLOWED=NO "TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps" "TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3"
```

## Speech-strip refinement

At the user’s request, card gutters increased from four to eight points. A labelled 64-point Speak card now precedes the bordered message area, changing in place to Stop while speech is active. Undo and Clear remain after the message. The pencil, standalone Stop, keyboard and speech-bubble buttons are removed. Imported Keyboard actions still open the typing sheet. The earlier six-action strip and its screenshots above are historical.

The focused `SpeechStripUITests` check covers absent redundant buttons, Speak preceding the message, the Keyboard card, automatic speech after adding words, manual speech, and returning from Stop to Speak. The first run used an incorrect assumption that adding text would leave speech idle; the corrected test accounts for speak-on-selection.

`Speech-Strip-2.xcresult`: **one UI test passed, zero failures, exit 0**, including real speech-engine state transitions. Build succeeded on the existing iPad simulator. Exact command:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/iPadDerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/Speech-Strip-2.xcresult -parallel-testing-enabled NO "-only-testing:BoardScannerUITests/SpeechStripUITests" test CODE_SIGNING_ALLOWED=NO
```

## Compact header follow-up — 28 October 2026

Compact vertical size class now halves speech-card height and width, scales down their icons, and reserves only half a grid row for the speech strip. The strip occupies two-thirds of the available width; the page title occupies the remainder. The navigation toolbar is hidden during compact communication and returns in regular height or editing. The message field is blank when empty. Size-based horizontal bouncing prevents movement when a grid or speech row fits, while retaining overflow scrolling.

Verification uses the existing iPhone SE (3rd generation), iOS 18.2, because the default iPhone 18 Pro was occupied by another task's production-app tests. `Compact-Strip-1` exposed an axis-switching sizing regression and an accessibility-frame assertion. `Compact-Strip-2` confirmed Speak/Stop after switching to size-based scrolling, but still failed the message accessibility-frame assertion; its completed test process was terminated after hanging during diagnostics collection. The message accessibility element now belongs to its sized field.

Final focused command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination 'platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/SEDerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/Compact-Strip-3.xcresult -parallel-testing-enabled NO -collect-test-diagnostics never '-only-testing:BoardScannerUITests/SpeechStripUITests' test CODE_SIGNING_ALLOWED=NO
```

Result: **build and both focused UI tests passed, exit 0**. Coverage includes half-height compact message/actions, half-width compact actions, title placement, hidden toolbar, no placeholder, fitting-grid sideways swipes, regular card-size controls, keyboard-card entry, and automatic/manual Speak–Stop transitions. Screenshots are retained in `compact-strip-3-attachments/`. VoiceOver activation remains deferred.

## Compact controls and scrolling revision

Compact controls now use two-thirds of the board-card size (one-third larger than the previous half-size controls). Message tokens display words only. The compact title is right-aligned. Grid scrolling axes are selected independently from padded content dimensions and the measured viewport; the grid container fills the available width before measurement. The message and speech strip also disable horizontal scrolling when their content fits.

`Compact-Strip-4` exposed a too-narrow grid viewport measurement; corrected before `Compact-Strip-5`. The exact verification command is the preceding compact-header command with result bundle `Compact-Strip-5.xcresult` (same scheme, destination, DerivedData, test selection and flags).

`Compact-Strip-5`: build and both focused UI tests passed (exit 0), including compact sizing, title placement, fitting-grid horizontal swipes, and keyboard/Speak/Stop behaviour. Vertical overflow is handled by the same axis calculation but was not separately exercised by this focused UI run.

## Rotation and header repair

Viewport measurements now come from independent containers so child card widths cannot retain the previous orientation. The outer speech strip no longer scrolls, keeping Speak anchored; only overflowing words scroll. The layout uses the parent safe-area proposal. `Rotation-2` passed both focused tests (exit 0), including repeat rotation and speech controls, with the same command as Compact-Strip-5 and result name Rotation-2. Notched-device safe-area verification remains outstanding; this run used the existing SE simulator.

`Rotation-Notched-1` also passed on the default iPhone 18 Pro (iOS 27), including first/repeated landscape sizing. Its retained screenshot was inspected: Speak and the grid start inside the left safe area, and the right-aligned title remains inside the right safe area. This supersedes the outstanding notched-device check above.

## Motor Plan landscape cropping and scrolling repair — 28 October 2026

The imported grid now measures its available scrolling height independently of its content. Compact minimum column pitch is 52 points (44-point cards plus the existing gutter), still scaled by text/button preferences. A scoped UIKit marker disables automatic content-inset adjustment for this scroll view only: the outer grid already lies inside the safe area, so automatic adjustment applied those insets twice after a swipe. The header remains fixed while the grid scrolls vertically.

`Motor-Scroll-1` and `Motor-Scroll-2` passed accessibility-frame assertions but retained visible inset/clipping defects in their screenshots. They are not accepted visual passes. `Motor-Scroll-3` passed the actual Motor Plan regression and its screenshot was inspected: all 11 columns and the complete bottom row are visible after scrolling, within both side safe areas. One test, zero failures/skips; build/test exit 0.

Exact final command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/SEDerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/Motor-Scroll-3.xcresult -parallel-testing-enabled NO -collect-test-diagnostics never '-only-testing:BoardScannerUITests/CommunicationLayoutUITests/testMotorPlanLandscapeFitsWidthAndScrollsToBottom' test CODE_SIGNING_ALLOWED=NO 'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' 'TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3'
```

## Landscape touch alignment follow-up

The cards remain native SwiftUI Buttons, positioned in a ZStack to preserve source positions and merged cells; there is no Canvas. Imported grids now use `GridViewport`, a bounded UIScrollView hosting those SwiftUI views with hosting safe-area regions disabled. The surrounding SwiftUI viewport still respects screen safe areas. This gives drawing, touch targets and scrolling one coordinate space and replaces the earlier inset-introspection workaround. Merged cards are bounded against the space remaining below scanning controls.

Regression coverage now taps screen coordinates aligned with the visible header/card pitch, checking “I”, “you”, and “make” after scrolling. Earlier element/frame-only assertions were insufficient. `Motor-Hit-1/2` exposed test-coordinate issues; `Motor-Hit-3` passed coordinate checks but its screenshot still showed a shift and was rejected. `Motor-Hit-4` passed with the bounded container and its screenshot was visually verified. `Motor-Hit-5` passed coordinate taps but exposed the merged-card height issue; that was corrected before `Motor-Hit-6`.

Final simulator command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/SEDerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/Motor-Hit-6.xcresult -parallel-testing-enabled NO -collect-test-diagnostics never '-only-testing:BoardScannerUITests/CommunicationLayoutUITests/testMotorPlanLandscapeFitsWidthAndScrollsToBottom' '-only-testing:BoardScannerUITests/AccessUITests/testImportedMergedChoicesRemainVisibleAndSelectableAcrossRotation' test CODE_SIGNING_ALLOWED=NO 'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' 'TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3'
```

`Motor-Hit-6`: both focused UI tests passed, zero failures/skips, exit 0. Final development-signed device build also passed using `xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -configuration Debug -destination platform=iOS,id=00008150-0004053636FB801C -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-device/DerivedData -allowProvisioningUpdates build`.
