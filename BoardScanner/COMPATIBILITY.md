# Older-runtime and compact-screen verification — 28 October 2026

Testing on the existing iPhone SE (3rd generation), iOS 18.2, found and fixed two app defects:

- At maximum accessibility text size, the import row compressed Photos and Files into icons and wrapped On device into a tall column. `ImportBar` now preserves the labels in a horizontal scroll view whose content determines its height. The final screenshot shows the full Files control after scrolling, with the welcome content below it.
- The board Files button did not present its picker on iOS 18.2, even after the test proved the button was fully visible and tapped its centre. `ScannerView` had two `fileImporter` modifiers on the same view. It now uses one presenter, retaining the requested purpose to select allowed types and dispatch the selected URL to board import or symbol recovery. The previously failing Files activation/cancellation case passes with that change.

The iOS 16.6 minimum is unchanged. These results establish additional iOS 18.2 runtime coverage, not minimum-version coverage. Production PECS targets and shared Photos-picker sources were not edited.

## Test corrections and evidence

`WindowOrientation.swift` waits for the actual window's aspect ratio after requesting rotation. Access, authoring and speech tests use it before interacting. The original SE recordings showed taps sent while rotation was still settling; the two access failures passed with this test correction before any app source changed. The helper is included only in the standalone UI-test target through the regenerated Xcode project.

The new import-row check verifies bounded height, visible text labels, the entire Files button within the viewport, picker presentation and cancellation. XCTest reported the partly visible Files button as hittable, so that flag alone was insufficient. A slow drag with a hold stops scroll momentum before checking visibility. The earlier fast-drag failure remains retained. The test still failed after visibility was established; only consolidating the app's file-import presenters resolved activation.

On the smaller screen, authoring now scrolls the Destination row into view before choosing a page. The speech test accepts iOS 18's Cancel control to leave active search, while retaining the existing iOS 27 close control. These corrections preserve the same user journeys and assertions.

`testFilePickerSwitchesBetweenBoardAndSymbolImports` opens and cancels board, symbol-library, then board import in sequence and verifies the current page is preserved with no error alert. This tests presentation and cancellation, not selecting a symbol database. Native backup/restore separately verifies selection and loading of a `.boardscan` file through the consolidated presenter.

All artifacts are under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/`. Each named result has a matching `.log` and `.xcresult`. Authoritative summaries report zero runtime warnings in every run below; the usual XCTest minimum-version linker warnings remain in build logs.

| Bundle | Result | Scope |
| --- | --- | --- |
| `SE-18-2-1` | 77 passed, 5 failed, 3 skipped; exit 65 | 73 model tests passed; three optional supplied-file model tests skipped. Four UI journeys passed. Five UI failures exposed rotation sequencing; later runs progressed further into authoring and speech. |
| `SE-18-2-2` | 2 passed; exit 0 | Access-text and merged-choice journeys passed after window-orientation waits, before app changes. |
| `SE-18-2-3` | 7 passed, 3 failed; exit 65 | Import-row layout fixed. Communication, access and maximum-text speech passed. Remaining failures: Files activation, offscreen Destination row, search dismissal control. |
| `SE-18-2-4` | 2 passed, 1 failed; exit 65 | Native authoring/relaunch and phrase/recall/background speech passed after test corrections. Import test failed its full-visibility assertion because of scroll momentum. |
| `SE-18-2-5` | 1 failed; exit 65 | Full Files visibility established; activation still failed with the two app presenters. |
| `SE-18-2-6` | 1 passed; exit 0 | Same Files check passed after the single-presenter app fix. Retained before/after-scroll screenshots were visually inspected. |
| `SE-18-2-7` | 1 passed; exit 0 | Final app: alternating board/symbol/board picker cancellation preserved the current page. |
| `Phone-27-1` | 14 passed, 1 expected failure; exit 0 | Default iPhone 18 Pro/iOS 27.0: all access and authoring journeys plus speech controls. The existing contrast-audit discrepancy again names Edit, Undo, Clear, Type and Phrases. This run includes the import-row layout change and precedes the single-presenter change. |
| `Backup-27-1` | 1 passed; exit 0 | Final app on default iPhone: native Files export, restore into a separate library, second page, custom message, picture and relaunch. |

There is passing coverage for all ten selected SE UI journeys across the focused runs, plus the additional picker-switching journey. This is not a single clean full-suite run. The broad ordinary iOS 27 regression remains the dated result in [AAC.md](AAC.md); landscape VoiceOver activation is still unresolved. Neither these compatibility checks nor the ordinary touch/keyboard passes supersede that diagnostic.

The SE started shut down. After testing, a shutdown request reported it was already shut down, matching its initial state. The default iPhone was already booted and remains available. No physical device was installed to or changed.

## Commands

Run from the repository root. `xcodegen generate --spec BoardScanner/project.yml` added the shared UI-test helper to the generated project. Exact Xcode invocations below are retained from their logs; stdout and stderr were redirected to the corresponding `.log` files in the artifact directory. All commands use the existing checkout and external DerivedData.

### SE-18-2-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination "platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A" \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/SE-18-2-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  "-only-testing:BoardScannerTests" \
  "-only-testing:BoardScannerUITests/CommunicationUITests" \
  "-only-testing:BoardScannerUITests/NativeAuthoringUITests/testCreatePagePictureLinkAndCommunicateAfterRelaunch" \
  "-only-testing:BoardScannerUITests/SpeechAccessUITests/testSpeechCanBeStoppedFromPhraseAndRecallSheetsAndAfterBackgrounding" \
  "-only-testing:BoardScannerUITests/SpeechAccessUITests/testMaximumTextKeepsPhraseSpeechStopVisibleAcrossRotation" \
  "-only-testing:BoardScannerUITests/AccessUITests/testAccessibilityTextKeepsBoardAndActionsReachable" \
  "-only-testing:BoardScannerUITests/AccessUITests/testImportedMergedChoicesRemainVisibleAndSelectableAcrossRotation" \
  "-only-testing:BoardScannerUITests/AccessUITests/testScreenshotBoardAtMaximumSizeInLandscape" \
  test CODE_SIGNING_ALLOWED=NO
```

### SE-18-2-2

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination "platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A" \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/SE-18-2-2.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  "-only-testing:BoardScannerUITests/AccessUITests/testAccessibilityTextKeepsBoardAndActionsReachable" \
  "-only-testing:BoardScannerUITests/AccessUITests/testImportedMergedChoicesRemainVisibleAndSelectableAcrossRotation" \
  test CODE_SIGNING_ALLOWED=NO
```

### SE-18-2-3

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination "platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A" \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/SE-18-2-3.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  "-only-testing:BoardScannerUITests/CommunicationUITests" \
  "-only-testing:BoardScannerUITests/NativeAuthoringUITests/testCreatePagePictureLinkAndCommunicateAfterRelaunch" \
  "-only-testing:BoardScannerUITests/SpeechAccessUITests/testSpeechCanBeStoppedFromPhraseAndRecallSheetsAndAfterBackgrounding" \
  "-only-testing:BoardScannerUITests/SpeechAccessUITests/testMaximumTextKeepsPhraseSpeechStopVisibleAcrossRotation" \
  "-only-testing:BoardScannerUITests/AccessUITests/testAccessibilityTextKeepsBoardAndActionsReachable" \
  "-only-testing:BoardScannerUITests/AccessUITests/testImportedMergedChoicesRemainVisibleAndSelectableAcrossRotation" \
  "-only-testing:BoardScannerUITests/AccessUITests/testScreenshotBoardAtMaximumSizeInLandscape" \
  "-only-testing:BoardScannerUITests/AccessUITests/testImportActionsRemainReadableAtMaximumText" \
  test CODE_SIGNING_ALLOWED=NO
```

### SE-18-2-4

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination "platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A" \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/SE-18-2-4.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  "-only-testing:BoardScannerUITests/AccessUITests/testImportActionsRemainReadableAtMaximumText" \
  "-only-testing:BoardScannerUITests/NativeAuthoringUITests/testCreatePagePictureLinkAndCommunicateAfterRelaunch" \
  "-only-testing:BoardScannerUITests/SpeechAccessUITests/testSpeechCanBeStoppedFromPhraseAndRecallSheetsAndAfterBackgrounding" \
  test CODE_SIGNING_ALLOWED=NO
```

### SE-18-2-5

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination "platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A" \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/SE-18-2-5.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  "-only-testing:BoardScannerUITests/AccessUITests/testImportActionsRemainReadableAtMaximumText" \
  test CODE_SIGNING_ALLOWED=NO
```

### SE-18-2-6

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination "platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A" \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/SE-18-2-6.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  "-only-testing:BoardScannerUITests/AccessUITests/testImportActionsRemainReadableAtMaximumText" \
  test CODE_SIGNING_ALLOWED=NO
```

### SE-18-2-7

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination "platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A" \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/SE-18-2-7.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  "-only-testing:BoardScannerUITests/TDSnapUITests/testFilePickerSwitchesBetweenBoardAndSymbolImports" \
  test CODE_SIGNING_ALLOWED=NO
```

### Phone-27-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/Phone-27-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  "-only-testing:BoardScannerUITests/AccessUITests" \
  "-only-testing:BoardScannerUITests/NativeAuthoringUITests" \
  "-only-testing:BoardScannerUITests/SpeechAccessUITests" \
  test CODE_SIGNING_ALLOWED=NO
```

### Backup-27-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScannerFileBackup \
  -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/Backup-27-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
```

## Final-source regression and test-input corrections — 28 October 2026

Artifacts are in `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-completion-audit/`. App implementation is unchanged from the compatibility fixes above. This follow-up changes only UI-test input and synchronization.

The full ordinary iPhone run (`Phone-1`) completed with exit 65: **96 passed, three failed, five optional fixture skips and one expected contrast-audit failure**, 105 cases total, zero runtime warnings. It is not a clean full-suite pass. The three failures were import-row scrolling, a library rename tap and the first scan-selection label assertion. Passing coverage includes the 73 model cases, authoring, document URL launch, phrases, speech controls, generated imports and two functional VoiceOver journeys.

The import test now starts its bounded slow drag in the row's bottom padding, outside its buttons. It still requires the entire Files control within the viewport before tapping, and verifies picker presentation and cancellation. This passes on both SE/iOS 18.2 and iPhone 18 Pro/iOS 27.0; retained after-scroll screenshots were visually inspected. Intermediate standard-swipe and pointer-scroll experiments failed and were removed: the swipe overshot, and pointer events are unsupported on the SE. The old button-centred drag did not move the row on iOS 27.

The scanning assertion now waits up to five seconds for the expected label. In the failed run, the first label read failed while the immediately following diagnostic read already reported `Select: Go to café 🗣️`. The corrected journey passed, including keyboard selection and linked-page VoiceOver focus. This does not verify landscape touch activation.

The library failure's recording and event attachment show Rename was tapped at (275,506), while its post-keyboard frame was (205,335,140,48). The alert remained open with `Meals` entered. The test now verifies the entered value and resolves the button's current centre before tapping; it also stops on the first assertion failure to avoid cascaded errors.

| Bundle | Result | Scope |
| --- | --- | --- |
| `Phone-1` | 96 passed, 3 failed, 5 skipped, 1 expected failure; exit 65 | Complete ordinary suite on final app implementation, before test-input corrections. |
| `iPad-1` | 2 passed; exit 0 | Maximum-text import controls and board/symbol/board picker cancellation. |
| `SE-Swipe-1` | 1 failed; exit 65 | Full-visibility assertion failed after ordinary slow swipes. |
| `SE-Scroll-1` | 1 failed; exit 65 | XCTest pointer-scroll API rejected as unsupported by the phone simulator. |
| `SE-Padding-1` | 1 passed; exit 0 | Touch drag from padding, full Files visibility, picker opening and cancellation. |
| `Phone-Focused-1` | 2 passed; exit 0 | Corrected import drag and asynchronous scan-label assertion. |
| `Phone-Library-1` | 1 passed; exit 0 | Rename, duplicate, delete, restore, saved message and relaunch with corrected alert tap. |
| `VoiceOver-iPad-1` | 1 passed, 1 failed; exit 65 | Exact Create toolbar focus: portrait activation passed, landscape failed. |

All three ordinary-suite failures now have passing focused checks on the unchanged app implementation. This is not a newly passing full-suite run. Final focused runs and the iPad import checks report zero runtime warnings. The SE returned to its initial shutdown state; the existing iPhone and iPad remain available. No physical device was installed to or changed.

The final iPad diagnostic captured an actual 1180×820 landscape window and a hittable Create control at (1011,36,37,36), with exact speech `Create Button`; activation still failed. Portrait 820×1180 passed. Teardown restored the original VoiceOver setting and portrait orientation without failure. See [ACTIVATION.md](ACTIVATION.md) for the earlier matching system-app control and input alternatives. This remains unresolved and is not converted to an expected failure.

### Follow-up commands

Exact commands retained from each log follow. Stdout and stderr were redirected to each matching `.log` in the artifact directory. All runs use the existing source checkout and external DerivedData.

#### Phone-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-completion-audit/Phone-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  test \
  CODE_SIGNING_ALLOWED=NO
```

#### iPad-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-completion-audit/iPad-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/AccessUITests/testImportActionsRemainReadableAtMaximumText \
  -only-testing:BoardScannerUITests/TDSnapUITests/testFilePickerSwitchesBetweenBoardAndSymbolImports \
  test \
  CODE_SIGNING_ALLOWED=NO
```

#### SE-Swipe-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-completion-audit/SE-Swipe-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/AccessUITests/testImportActionsRemainReadableAtMaximumText \
  test \
  CODE_SIGNING_ALLOWED=NO
```

#### SE-Scroll-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-completion-audit/SE-Scroll-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/AccessUITests/testImportActionsRemainReadableAtMaximumText \
  test \
  CODE_SIGNING_ALLOWED=NO
```

#### SE-Padding-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-compatibility/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-completion-audit/SE-Padding-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/AccessUITests/testImportActionsRemainReadableAtMaximumText \
  test \
  CODE_SIGNING_ALLOWED=NO
```

#### Phone-Focused-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-completion-audit/Phone-Focused-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/AccessUITests/testImportActionsRemainReadableAtMaximumText \
  -only-testing:BoardScannerUITests/VoiceOverUITests/testVoiceOverFocusesNewPageAtMaximumTextInLandscapeScanning \
  test \
  CODE_SIGNING_ALLOWED=NO
```

#### VoiceOver-iPad-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScannerVoiceOverInput \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-completion-audit/VoiceOver-iPad-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testLandscapeDefaultTextDoubleTap \
  -only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testPortraitDefaultTextDoubleTap \
  test \
  CODE_SIGNING_ALLOWED=NO
```

#### Phone-Library-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-completion-audit/Phone-Library-1.xcresult -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 -test-timeouts-enabled YES -collect-test-diagnostics never "-only-testing:BoardScannerUITests/BoardLibraryUITests" test CODE_SIGNING_ALLOWED=NO
```
