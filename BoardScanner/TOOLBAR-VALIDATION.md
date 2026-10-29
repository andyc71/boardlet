# Inactive editor toolbar — 28 October 2026

The broad iPhone run in `board-scanner-aac-audit/Phone-1.xcresult` exposed five failed interactions around the Create menu or vocabulary after relaunch. Its retained hierarchy showed an empty bottom `Toolbar` with a 402 × 874 frame, covering the entire window. XCTest could locate the intended controls but computed their hit point as `{-1, -1}`. The sixth failure timed out waiting for the supplied Motor Plan import.

`ScannerView` now creates the bottom toolbar's item group only while editing and explicitly hides the bottom bar otherwise. Editing still exposes Adjust grid, Save and Export. The correction uses the existing iOS 16 toolbar visibility API and does not alter board data, imports, speech, or access settings.

The first focused run showed that iOS still exposes a hidden toolbar node. New assertions requiring the node to be absent were therefore incorrect. They now require the actual Create and vocabulary controls to be hittable, followed by their existing taps and end-to-end assertions. No coordinate workaround, alternative navigation route, or relaxed journey result was added.

## Results

All artifacts are under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/`. Each result bundle has a same-named `.log`.

| Run | Result | What it proves |
| --- | --- | --- |
| `Toolbar-1` | Three passes, one expected contrast-audit failure, two failures; exit 65 | URL import, reusable phrases and supplied Motor Plan artwork recovery/save/relaunch/reimport complete. The accessibility journey reaches its existing audit, with only the previously documented contrast discrepancy. The two failures are the new, incorrect toolbar-node absence assertions. |
| `Toolbar-2` | Three passes, no failures/skips; exit 0 | Both complete native-authoring journeys pass after correcting those assertions: linked page/picture/message persistence, and Files cancellation/artwork removal committed only on Save. Maximum-text/button-size landscape scanning also passes. App implementation is unchanged from `Toolbar-1`. |
| `Toolbar-Backup-iPad` | One pass, no failures/skips; exit 0 | The editor's Export control still opens native Files, and a two-page backup restores into an independent library with its custom spoken message and picture intact. Retained screenshots were inspected. |
| `Toolbar-SE-1` | Two passes, no failures/skips; exit 0 | Native linked-page/picture/message authoring and document URL-launch communication pass on the existing iPhone SE (3rd generation), iOS 18.2. The simulator was returned to its initial shutdown state. |
| `Final-Phone-1` | 108 passes, one failure, one expected contrast finding, no skips; exit 65 | All 82 model tests and the ordinary AAC journeys complete. The sole unexpected failure is the old five-second wait for Files at maximum text size. All six previous failed journeys have no unexpected failures in this full run. |
| `Files-Max-iPad-1` | One pass, no failures/skips; exit 0 | Files' Cancel button appears after **7.17 seconds**, beyond the original five-second test allowance. Cancellation returns to the import controls. Screenshot inspected. |
| `Files-Max-Phone-1` | One pass, no failures/skips; exit 0 | The corrected wait passes on the iPhone, measuring **3.16 seconds**. Its screenshot catches the presentation transition, so a further check explicitly asserts the document browser and completed dismissal. |
| `Files-Max-Phone-2` | One pass, no failures/skips; exit 0 | Final strengthened check: the actual document-browser navigation bar appears, Cancel is hittable, cancellation removes the browser and restores import-button interaction. Cancel appears after **4.49 seconds**. The retained screenshot shows the native Files browser at maximum text size. |

The supplied import timeout did not reproduce in `Toolbar-1` or `Final-Phone-1`, with the same 40-second wait. No importer change was made in this correction, so that timeout's cause is not established. `final-source-manifest.json` records the 133 source/configuration hashes at the full run's start. VoiceOver activation remains excluded at the user's request.

The maximum-text import test now uses the same fifteen-second allowance as the native Files journeys and retains elapsed time, a screenshot and (on failure) the hierarchy. The measured iPad presentation demonstrates that five seconds is insufficient for a valid system-picker launch. It does not establish the exact timing of the earlier iPhone failure. This is a test-only correction after the full run's source snapshot; app implementation has not changed. The historical full run remains failed and is not relabelled as a clean pass.

All required follow-up checks are now complete. The native contrast finding remains the narrowly documented expected discrepancy in [SPEECH-ACCESS.md](SPEECH-ACCESS.md); VoiceOver activation remains deferred. See [the final acceptance review](ACCEPTANCE.md).

## Commands

Run from the repository root. The common arguments are identical to the executed commands; the variables below abbreviate the paths only.

```sh
audit=/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit
phone_build=/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/DerivedData

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath "$phone_build" -resultBundlePath "$audit/Toolbar-1.xcresult" \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  '-only-testing:BoardScannerUITests/NativeAuthoringUITests' \
  '-only-testing:BoardScannerUITests/OpenDocumentUITests' \
  '-only-testing:BoardScannerUITests/PhraseCommunicationUITests' \
  '-only-testing:BoardScannerUITests/SpeechAccessUITests/testCommunicationAccessibilityDescriptionsTargetsAndTraits' \
  '-only-testing:BoardScannerUITests/TDSnapUITests/testSuppliedLibraryRecoverySaveAndRestore' \
  test CODE_SIGNING_ALLOWED=NO \
  TD_SNAP_FIXTURE='/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' \
  TD_SYMBOL_LIBRARY='/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3'

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath "$phone_build" -resultBundlePath "$audit/Toolbar-2.xcresult" \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  '-only-testing:BoardScannerUITests/NativeAuthoringUITests' \
  '-only-testing:BoardScannerUITests/AccessUITests/testMaximumTextAndButtonSizeKeepLandscapeScanChoiceVisible' \
  test CODE_SIGNING_ALLOWED=NO

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerFileBackup \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath "$audit/iPadDerivedData" -resultBundlePath "$audit/Toolbar-Backup-iPad.xcresult" \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never test CODE_SIGNING_ALLOWED=NO

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath "$phone_build" -resultBundlePath "$audit/Final-Phone-1.xcresult" \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  '-skip-testing:BoardScannerUITests/VoiceOverUITests' \
  test CODE_SIGNING_ALLOWED=NO \
  TD_SNAP_FIXTURE='/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' \
  TD_SYMBOL_LIBRARY='/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3'

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A' \
  -derivedDataPath "$audit/SEDerivedData" -resultBundlePath "$audit/Toolbar-SE-1.xcresult" \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  '-only-testing:BoardScannerUITests/NativeAuthoringUITests/testCreatePagePictureLinkAndCommunicateAfterRelaunch' \
  '-only-testing:BoardScannerUITests/OpenDocumentUITests' test CODE_SIGNING_ALLOWED=NO
```

Maximum-text Files follow-ups used these commands (the first iPhone check used `Files-Max-Phone-1.xcresult` with the same selectors, before adding the browser/dismissal assertions):

```sh
audit=/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit
phone_build=/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/DerivedData

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath "$audit/iPadDerivedData" -resultBundlePath "$audit/Files-Max-iPad-1.xcresult" \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  '-only-testing:BoardScannerUITests/AccessUITests/testImportActionsRemainReadableAtMaximumText' \
  test CODE_SIGNING_ALLOWED=NO

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath "$phone_build" -resultBundlePath "$audit/Files-Max-Phone-2.xcresult" \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  '-only-testing:BoardScannerUITests/AccessUITests/testImportActionsRemainReadableAtMaximumText' \
  test CODE_SIGNING_ALLOWED=NO
```
