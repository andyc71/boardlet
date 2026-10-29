# VoiceOver input investigation — 28 October 2026

**Deferred at the user’s request:** “Leave the verification of Voice Over activation for now.” The retained failures remain unresolved evidence; do not rerun this investigation as a completion gate unless the user resumes it.

The functional VoiceOver traversal and page-focus checks are described in [VOICEOVER.md](VOICEOVER.md). This investigation isolates a remaining landscape touch-activation failure without changing the app's hit areas speculatively.

## Reproduction and results

`VoiceOverInputDiagnostics` launches an empty, isolated library, enables VoiceOver, traverses to the standard Create toolbar button, captures its geometry and current speech, and attempts to open its New board menu. No board grid is present. Teardown restores the original VoiceOver setting and portrait orientation.

| Device / result bundle | Portrait maximum text, double tap | Landscape default text, double tap | Landscape maximum text, double tap | Landscape default text, single tap |
| --- | --- | --- | --- | --- |
| iPhone 18 Pro, iOS 27.0 (`Toolbar-1`, `Toolbar-2`) | Passed | Failed | Failed | Failed |
| iPad A16, iOS 27.0 (`Diagnostic-iPad`) | Passed | Failed | Failed | Failed |

The iPhone also failed a maximum-text landscape single tap in `Toolbar-2`. The iPad diagnostic completed with exit 65: one pass, three failures. All artifacts are under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-activation/`.

These results show the failure is broader than custom board controls and maximum text. They do not prove an Apple automation defect or establish physical VoiceOver gesture behavior. The successful keyboard-scanning journey remains separate evidence.

The opt-in **BoardScannerVoiceOverInput** scheme selects the toolbar probes, including a follow-up comparison of coordinate double taps at the screen centre. The ordinary **BoardScanner** scheme excludes this class and `RealScreenshotUITests`; functional `VoiceOverUITests` remain in the ordinary suite. Diagnostic failures are retained as failures, not converted to expected passes.

## Exact current diagnostic command

Run from the repository root after `xcodegen generate --spec BoardScanner/project.yml`:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerVoiceOverInput \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-activation/Diagnostic-iPad.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
```

The initial iPhone prototypes used the ordinary scheme with the same flags, the iPhone destination `BB33297D-F833-464B-B43D-14CBD0DA3021`, and `board-scanner-access/KeyboardDerivedData`. They selected the then-temporary `VoiceOverUITests/testVoiceOverToolbarActivationInLandscape`, `testVoiceOverToolbarActivationAtMaximumTextInLandscape`, and `testVoiceOverToolbarActivationAtMaximumTextInPortrait` methods. `Toolbar-2` selected only the two landscape methods using single taps. Those prototypes are now represented by the dedicated diagnostic class above.

## Physical-device preparation

The unsigned device build passed with exit 0 (`device-build.log`):

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -configuration Debug -destination 'generic/platform=iOS' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-activation/DeviceDerivedData \
  build CODE_SIGNING_ALLOWED=NO
```

The resulting app retains bundle identifier `com.brightblue.BoardScanner.development` and minimum iOS version 16.6. It has not been signed, installed, or launched on a physical device. The user answered the device request with **“Keep testing on simulators.”** No physical-device approval remains pending, and no physical installation is authorized. Simulator speech state alone does not confirm audible physical output. An earlier native UI comparison was unavailable while the Mac was locked; desktop access is available for the subsequent simulator investigation.

## Full ordinary regression

The ordinary iPhone suite finished **TEST SUCCEEDED**, exit 0, on 28 October 2026 (`Regression-1.xcresult`, `regression-1.log`). The result bundle reports 99 cases: **93 passed, five optional supplied-file tests skipped, one expected failure, zero unexpected failures**. The expected failure is the existing narrowly matched native contrast-audit disagreement described in [SPEECH-ACCESS.md](SPEECH-ACCESS.md), affecting `toggleEditing`, `undoMessage`, `clearMessage`, `typeMessage`, and `showPhrases` in this run. It is not a clean all-assertions pass.

All three functional VoiceOver journeys passed, alongside scanning, speech cancellation, authoring, phrases, library recovery, generated imports and model tests. The opt-in Photos tests and landscape input diagnostics were excluded by the scheme. No app code changed during this run; the new photo-artwork test belongs to the excluded class and is verified separately.

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-activation/Regression-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
```

## Simulator-only follow-up after user direction

The user chose **“Keep testing on simulators.”** The following investigation stays within that boundary; physical devices were not installed to, launched, or changed.

A direct Device Hub check used an isolated library on the existing iPad A16/iOS 27.0. With simulator VoiceOver enabled, a coordinate click on Create followed by a double-click opened New board in portrait. The retained `manual-voiceover/portrait-create-menu.png` shows its VoiceOver focus rectangle and was visually inspected. In landscape, the same sequence at the visible Create control and one double-click retry did not open the menu. These are Device Hub mouse interactions, not proof of physical gesture behavior or an app-specific defect. The direct check was stopped, and the separate `Manual-Restore.xcresult` check passed: simulator VoiceOver was disabled and orientation set to portrait. Its temporary restoration method was removed afterward.

`Coordinate-1.xcresult` / `coordinate-1.log` completed with exit 65: both screen-centre coordinate double-tap probes failed, in portrait and landscape at maximum text size. The recorded Create geometry was hittable in each case: landscape app 874×402, Create at approximately (658,28), 43×36; portrait app 402×874, Create at approximately (208,66), 43×36. The portrait post-tap speech referred to Files navigation, showing the coordinate event did not activate the previously focused Create control. This event route is not a reliable substitute for VoiceOver activation.

`System-Control-1.xcresult` completed with two passing Settings navigation checks, but both captured windows were 402×874 portrait. Those results are **not landscape controls** despite one test setting the device's orientation to landscape. The retained diagnostic now verifies actual interface dimensions and that its destination is absent before activation. It navigates to Accessibility and checks the VoiceOver row appears, without changing Settings values.

Exact coordinate-probe build and run:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerVoiceOverInput \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  build-for-testing CODE_SIGNING_ALLOWED=NO
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerVoiceOverInput \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-activation/Coordinate-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testLandscapeMaximumTextScreenCenterDoubleTap \
  -only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testPortraitMaximumTextScreenCenterDoubleTap \
  test-without-building CODE_SIGNING_ALLOWED=NO
```

The build succeeded (`coordinate-build.log`). The `System-Control-1` command used the same iPhone paths and flags with `test`, its named result path, and selectors `testSystemSettingsPortraitActivation` and `testSystemSettingsLandscapeActivation`. The cleanup command used the existing iPad destination and `board-scanner-extreme-layout/DerivedData`, `Manual-Restore.xcresult`, `test`, and the then-temporary `testRestoreManualSimulatorState` selector. Its log is `manual-restore.log`. All selectors are under `BoardScannerUITests/VoiceOverInputDiagnostics`.

### Orientation-checked system control

`System-Control-iPad.xcresult` / `system-control-ipad.log` completed with exit 65: **portrait passed; landscape failed**. The captured Settings windows are 820×1180 in portrait and 1180×820 in landscape. In each case the destination was absent before the attempt and the retained speech reached “Accessibility Button.” The landscape double tap did not reveal the VoiceOver row; the portrait double tap did. Teardown disabled VoiceOver, restored portrait and terminated the Settings app. No settings values were edited.

This reproduces the orientation-dependent activation failure outside Board Scanner. It supports investigating the simulator/input environment; it does not prove a particular Apple defect or justify speculative changes to the app's hit regions. The separate app traversal, keyboard scanning and page-focus passes remain valid within their stated scopes. Landscape VoiceOver touch behavior is still not verified as working.

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerVoiceOverInput \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-activation/System-Control-iPad.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testSystemSettingsPortraitActivation \
  -only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testSystemSettingsLandscapeActivation \
  test CODE_SIGNING_ALLOWED=NO
```

The diagnostic class now contains eight opt-in cases: the four original toolbar probes, two screen-centre comparisons, and two system Settings controls. The ordinary suite still excludes this class. No app implementation changed during this follow-up. `git diff --check` passed.

## Runtime and keyboard-input comparison — 28 October 2026

A fresh simulator inventory found an existing iPhone Duo running iOS 27.1. The installed VoiceOver testing API requires iOS 27, so installed iOS 18/26 runtimes cannot run this same service-based probe. The default iPhone 18 Pro/iOS 27.0 remains the ordinary test destination; the Duo was used only for this comparison. No simulator was created or erased.

The toolbar probe now asserts the actual interface aspect ratio before enabling VoiceOver. A default-text portrait control was added to match the existing default-text landscape control. Two further diagnostic cases use `app.typeKey(" ", modifierFlags: [.control, .option])` after VoiceOver focuses Create. Apple's [external-keyboard guidance](https://support.apple.com/en-ie/guide/iphone/iph6c494dc6/27/ios/27) specifies VO–Space for activation with Control–Option as one available modifier. This XCTest injection is not a physical keyboard test, and no system modifier preference was changed.

| Result bundle | Outcome | Meaning |
| --- | --- | --- |
| `Phone-27-0` | Portrait passed; landscape failed activation. Exit 65. | Same text setting and confirmed orientation. App frames were 402×874 and 874×402; Create was hittable in both, and landscape speech remained “Create Button” after the double tap. |
| `Duo-27-1` | Portrait passed; landscape failed the orientation prerequisite. Exit 65. | The existing device configuration did not provide a landscape window; activation was not attempted in that case. This is not evidence about iOS 27.1 landscape activation or a completed Duo layout audit. |
| `Keyboard-27-0` | Both portrait and landscape failed activation. Exit 65. | XCTest's injected VoiceOver keyboard command did not open the menu. It does not provide an alternative activation route in this setup, and it does not establish a physical keyboard defect. |

All three bundles report zero skips, expected failures and runtime warnings. Failures remain failures in the opt-in scheme. Teardown restored the original VoiceOver setting and portrait orientation; no teardown assertion failed. A subsequent shutdown request reported that the Duo was already shut down, matching its initial state. The diagnostic class now has eleven opt-in cases. No app implementation changed in this investigation.

Artifacts, matching logs, and exported focus/geometry attachments are under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-voiceover-runtime/`.

Exact iOS 27.0 comparison command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerVoiceOverInput \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-voiceover-runtime/Phone-27-0.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testLandscapeDefaultTextDoubleTap \
  -only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testPortraitDefaultTextDoubleTap \
  test CODE_SIGNING_ALLOWED=NO
```

The exact `Duo-27-1` command uses the same flags/selectors, destination `platform=iOS Simulator,id=A6BB8AD2-DBB8-4B88-BB65-C1850770A270`, DerivedData `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-voiceover-runtime/DerivedData`, and result bundle `board-scanner-voiceover-runtime/Duo-27-1.xcresult` under the same external root.

The exact `Keyboard-27-0` command uses the iPhone command above, result bundle `Keyboard-27-0.xcresult`, and replaces its selectors with `BoardScannerUITests/VoiceOverInputDiagnostics/testLandscapeDefaultTextVoiceOverKeyboardActivation` and `BoardScannerUITests/VoiceOverInputDiagnostics/testPortraitDefaultTextVoiceOverKeyboardActivation`.

The comparison does not resolve landscape VoiceOver activation. Together with the earlier orientation-checked Settings control, it still provides no basis for changing Board Scanner's hit areas. Functional traversal and ordinary keyboard scanning remain separately verified; neither is relabelled as a landscape VoiceOver touch pass.

## Duo display-pose and diagnostic corrections — 28 October 2026

Device Hub's existing iPhone Duo was started and its **Open** display control selected. No simulator was created or erased. This investigation found two defects in the toolbar diagnostic, both now corrected:

- On the open Duo, `app.frame` reported 669×951 while the actual application window and its hierarchy reported 951×669. The prerequisite now checks `app.windows.firstMatch.frame`, tries the two device orientations to establish the requested window aspect ratio, and captures both frames before asserting. A failed prerequisite still prevents activation; it is not a passing or skipped result.
- The prefix check for “Create” also matched the welcome screen's “Create a board Button,” which precedes the toolbar in the Duo's traversal order. The diagnostic now requires the exact utterance “Create Button” and retains the full focus traversal. The final Duo recordings explicitly traverse past “Create a board” before reaching the toolbar.

Only the diagnostic and documentation changed. The final controls use default text, isolated empty libraries, and the existing `createMenu` element's double tap. They still do not establish physical gesture behavior.

Artifacts and matching logs are in `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-duo-pose/`. All five bundles report zero skips, expected failures and runtime warnings. Build logs retain the existing test-framework minimum-version linker warnings.

| Bundle | Result | Evidence and scope |
| --- | --- | --- |
| `Open-1` | 0 passed, 2 failed; exit 65 | Before corrections: landscape failed the application-frame prerequisite; portrait-labelled activation used a wide window and focused “Create a board.” These are not valid orientation/toolbar comparisons. |
| `Open-2` | 0 passed, 2 failed; exit 65 | Window correction only: confirmed 951×669 wide window, but still stopped on the wrong Create prefix. The tall-window case could not establish its prerequisite. |
| `Open-3` | 0 passed, 1 failed; exit 65 | Both corrections: 951×669 window, exact “Create Button” focus, hittable toolbar at approximately (884,125), 38×38. Double tap did not open New board; subsequent speech was “Settings Double-tap to open.” |
| `Phone-1` | 1 passed, 1 failed; exit 65 | Corrected iPhone 18 Pro/iOS 27.0 control: 874×402 landscape failed activation with speech remaining “Create Button”; 402×874 portrait opened New board. Both application and window frames agreed. |
| `Closed-1` | 1 passed, 0 failed; exit 0 | After selecting Device Hub's **Closed** control, Duo portrait was 466×678. Exact toolbar focus and menu activation passed. |

The open-Duo result is now a valid wide-window activation attempt on iOS 27.1. The portrait control required the closed display; orientation assignment alone did not produce a tall open window in this setup. This is a narrow input comparison, not a completed Duo layout audit. The failure remains unresolved, with no evidence justifying a speculative app hit-area change.

Teardown restored the original VoiceOver state and set device orientation to portrait; no teardown assertion failed. The final portrait control ran after restoring the closed display, and `xcrun simctl shutdown A6BB8AD2-DBB8-4B88-BB65-C1850770A270` then completed with exit 0, restoring the simulator's initial shutdown state.

Final open-display command (run from the repository root after selecting **Open** in Device Hub):

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerVoiceOverInput \
  -destination 'platform=iOS Simulator,id=A6BB8AD2-DBB8-4B88-BB65-C1850770A270' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-voiceover-runtime/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-duo-pose/Open-3.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testLandscapeDefaultTextDoubleTap \
  test CODE_SIGNING_ALLOWED=NO
```

`Open-1` and `Open-2` used this same command with their respective result names and the additional selector `-only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testPortraitDefaultTextDoubleTap`. `Closed-1` used result name `Closed-1.xcresult` and replaced the landscape selector with that portrait selector, after selecting **Closed** in Device Hub. Each command redirected stdout and stderr to its matching `.log` file.

Exact corrected default-iPhone comparison:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerVoiceOverInput \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-duo-pose/Phone-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testLandscapeDefaultTextDoubleTap \
  -only-testing:BoardScannerUITests/VoiceOverInputDiagnostics/testPortraitDefaultTextDoubleTap \
  test CODE_SIGNING_ALLOWED=NO
```

## Final-source iPad comparison — 28 October 2026

`board-scanner-completion-audit/VoiceOver-iPad-1.xcresult` completed with one portrait pass and one landscape failure, exit 65, zero skips, expected failures or runtime warnings. The app source includes the final import-row and single-file-presenter fixes. Actual window geometry was 1180×820 in landscape and 820×1180 in portrait. Both controls were hittable; the landscape Create frame was (1011,36,37,36), and traversal reached exactly `Create Button`. Landscape double tap still did not open New board. Teardown restored VoiceOver and portrait without failure.

The exact invocation and result are retained in [the compatibility follow-up](COMPATIBILITY.md#final-source-regression-and-test-input-corrections--28-october-2026). This repeats the established blocker on current app implementation; it does not establish a new app defect or justify changing hit areas. Physical-device verification remains outside the user's simulator-only direction.
