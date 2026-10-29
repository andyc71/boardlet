# VoiceOver communication and page navigation

The follow-up [input investigation and full regression](ACTIVATION.md) reproduces landscape touch-activation failures on the standard Create toolbar button at both default and maximum text sizes, on iPhone and iPad. A later orientation-checked control also fails in landscape and passes in portrait in the iPad simulator's Settings app. Its separate diagnostic scheme retains those failures. The 28 October ordinary iPhone suite passed all three functional VoiceOver journeys; full counts and the existing contrast-audit expected failure are recorded there. The focused results below describe the earlier development runs.

The composer’s short visible labels now have explicit spoken names: **Speak message**, **Stop speaking**, **Undo last word**, and **Clear message**. This distinguishes the speech command from the starter vocabulary word “Stop.” Its hint explains that it also stops scanning. Voice Control input labels retain the short visible names. Page titles are marked as headings.

## Page focus

After a linked-page, Back, or Home transition, VoiceOver focuses the new page heading. Compact scanning layouts use their page title, or the Pages control whose value includes the page title at accessibility text sizes. A different control supplies the page context when Start/Select already has focus. The request waits 300 ms for the activation gesture to finish. Immediate focus requests were lost during activation; the retained test evidence below demonstrates the difference.

The request runs in a view-scoped task. Navigation cancels older requests; the task checks that the requested page is still current. Modal presentation suspends the request, and page-browser/button-detail dismissal requests the current page context again after the sheet has closed. Each page change and relevant sheet dismissal creates a fresh request identity, so revisiting the same page can request focus again without cancelling its own task immediately after setting focus. It does not start scanning, speak the AAC message, or change its words. The focus binding is scoped to VoiceOver.

## Verification scope

`VoiceOverUITests` uses the iOS 27 `XCUIVoiceOverService` to traverse actual accessibility focus and retain spoken output as text attachments. It checks:

- All nine starter words, their row/column values and action hints, plus the distinct composer command names.
- A composed message, enabled speech controls, the message editor, and recall after Clear.
- Focus on the new page heading, linked-page vocabulary, preserving a message on return Home, and focus after choosing a page in the page browser.
- Maximum accessibility text in landscape with Space-key step scanning: the new page context is focused, its word is reachable, scanning remains stopped, and navigation adds no unintended words.

The tests use targeted XCTest double taps at known controls while VoiceOver is enabled. They verify those interactions, traversal, and speech strings. They do **not** establish location-independent double-tap activation of an arbitrary traversed focus, VoiceOver keyboard activation, physical speaker output, braille, physical switches, or iOS 16.6 runtime behavior. The public test service has no activation method in the installed SDK header. These limits are separate from the successful focus and traversal checks.

Each test uses isolated library/preferences data. XCTest teardown restores the original VoiceOver state even when a test assertion aborts. The new test file requires the Swift 6.4 toolchain and skips below iOS 27. Its compile guard keeps the rest of the project buildable with the supported earlier toolchains. The app retains iOS 16.6 deployment support.

## Evidence and iterations — 27–28 October 2026

Artifacts: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-voiceover/`.

| Result bundle | Outcome and interpretation |
| --- | --- |
| `Baseline` | Starter-word traversal succeeded, but `app.doubleTap()` selected the word at screen center (“No”) instead of the traversed “Toilet.” The activation assertion failed. Swift defer did not retain its transcript after XCTest aborted; final cleanup uses XCTest teardown. |
| `Keyboard-1` | Control–Option–Space left the message empty. Failed activation assertion; transcript retained; teardown disabled VoiceOver and asserted that it was off. |
| `Phone-1` | Single targeted taps changed VoiceOver focus without activating controls. Both interaction assertions failed. |
| `Phone-2` | Targeted double taps worked. Vocabulary/message/editor/recall passed. Forward-only linked-page traversal failed at the final status label. |
| `Phone-3`, `iPad-1` | Vocabulary/message/editor/recall and the existing speech-stop/background regression passed on each device. Searching both directions still read the old page’s link after opening Child; navigation failed. |
| `Phone-4`, `iPad-2` | Immediate SwiftUI heading focus did not solve stale traversal. Scanning navigation and vocabulary/message/editor/recall passed; linked-page VoiceOver traversal failed. |
| `Phone-5`, `Phone-6`, `Diagnostic-1`, `Diagnostic-2` | Immediate/deferred UIKit screen-change notifications and changing the page container’s identity did not fix traversal. Temporary diagnostics confirmed VoiceOver was running but the requested heading had no focus. All experimental notifications, container identity changes, and diagnostic values were removed. |
| `Diagnostic-3` | Touching the new-page Drink control changed VoiceOver’s speech immediately; navigation, composition, and return Home then passed. This isolated the remaining issue to focus following activation, rather than inaccessible child vocabulary. |
| `Phone-8`, `iPad-3` | Scanning navigation, ordinary VoiceOver linked-page/page-browser navigation, and vocabulary/message/editor/recall passed on each device. The new maximum-text landscape activation/focus test failed. |
| `Phone-9`, `iPad-4` | Explicitly focusing the landscape link first did not make targeted double taps navigate; Home remained selected. |
| `Phone-10`, `iPad-5` | Targeted double tapping Start did not begin scanning in the same maximum-text landscape setup. This is retained as an activation limitation, not reported as a page-focus pass. |
| `Phone-11` | Enabling VoiceOver before rotation also failed to activate Start with a targeted double tap. |
| `Phone-12`, `Phone-13` | Space-key scanning navigated to Child, but the compact control retained a spoken Home value. Binding focus after the other modifiers did not fix that. |
| `iPad-6` | Maximum-text landscape Space-key scanning and new-page focus passed. |
| `Phone-14` | Keeping the focus request alive instead of clearing it did not, by itself, fix the compact-header case. |
| `Phone-15`, `iPad-7` | The new request identity passed ordinary linked-page and page-browser navigation on both devices. iPad also passed maximum-text scanning. Phone’s compact check failed because the new Pages target had not yet received its focus modifier; the completed binding is checked separately. |
| `Phone-7` | The cancellable 300 ms post-gesture focus request passed the linked-page journey, including an explicit assertion that VoiceOver announced “Child” as a heading. This predates the final compact-layout and sheet-dismissal coverage. |

These exploratory failures are retained and are not counted as final passes. Apple documents [VoiceOver keyboard activation](https://support.apple.com/en-gb/guide/iphone/iph6c494dc6/27/ios/27), but the synthesized XCTest event did not reproduce that behavior here. The [VoiceOver test service](https://developer.apple.com/documentation/xcuiautomation/xcuivoiceoverservice) provides traversal and speech capture.

## Final results

- **Phone-16:** build and maximum-text landscape Space-key scanning test passed, exit 0. Retained speech is “Pages Child Button”, followed by “Return Row 1, column 1 Button Open linked page”. This verifies the completed compact Pages focus binding.
- **iPad-7:** both ordinary linked-page/page-browser navigation and maximum-text landscape Space-key scanning passed, exit 0. Both paths retain “Child Heading” as their focused context; the child vocabulary is reachable afterward.
- **Phone-15:** ordinary linked-page and page-browser navigation passed with the final request-identity implementation. Its maximum-text test failed before the compact Pages modifier was connected; Phone-16 is the subsequent focused pass.
- **Phone-8 / iPad-3:** vocabulary, composed-message reading, editor/recall, and the existing scanning navigation regression passed on each device. Their separate maximum-text failures are retained in those bundles. Later changes concern page-focus requests and the compact page context; these are not reported as full-suite passes.

VoiceOver teardown assertions passed in these completed runs. The final transcripts were exported and inspected. The landscape **targeted double-tap** experiments remain unresolved; the successful maximum-text journey uses the supported Space-key scan input. This milestone does not establish physical-device VoiceOver gesture behavior or full AAC completion. The AAC goal remains active.

## Commands

Run from the repository root. Source membership was regenerated using `xcodegen generate --spec BoardScanner/project.yml`.

Combined iPhone verification command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-voiceover/Phone-8.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/VoiceOverUITests \
  -only-testing:BoardScannerUITests/AccessUITests/testScanPageLinkAndReturnWithoutLosingMessage \
  test CODE_SIGNING_ALLOWED=NO
```

Combined iPad verification command selects the same tests with these replacements:

```sh
-destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0'
-derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData
-resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-voiceover/iPad-3.xcresult
```

Exploratory commands used the same device/build paths and their named result bundles. `Baseline`, `Keyboard-1`, `Phone-1`, and `Phone-2` selected only `VoiceOverUITests`. `Phone-3` and `iPad-1` selected that class plus `SpeechAccessUITests/testSpeechCanBeStoppedFromPhraseAndRecallSheetsAndAfterBackgrounding`. `Phone-4` and `iPad-2` used the final selectors. `Phone-5` through `Phone-7` and all diagnostic runs selected only `VoiceOverUITests/testVoiceOverReadsLinkedPagesAndPreservedMessage`.

The installed test frameworks produce the existing iOS 17 linkage warnings while the app keeps its iOS 16.6 deployment target. The simulator also logs a duplicate WebKit accessibility-loader class warning, and Xcode logs its existing SDK build-version parsing warnings. These are retained in the logs rather than presented as a warning-free build. No production PECS Maker targets or shared Photos picker code were changed in this work.

The focused maximum-text reruns (`Phone-9`, `iPad-4`, `Phone-10`, `iPad-5`, and `Phone-11`) use their named result bundles and replace both selectors with:

```sh
-only-testing:BoardScannerUITests/VoiceOverUITests/testVoiceOverFocusesNewPageAtMaximumTextInLandscapeScanning
```

Landscape VoiceOver touch activation at maximum text remains separate from the ordinary-layout targeted interactions and the earlier keyboard/scanning tests. It must not be inferred from those passing cases.

Final focus-request verification (`Phone-15` and `iPad-7`) uses the corresponding device/build paths above and these two selectors:

```sh
-only-testing:BoardScannerUITests/VoiceOverUITests/testVoiceOverFocusesNewPageAtMaximumTextInLandscapeScanning
-only-testing:BoardScannerUITests/VoiceOverUITests/testVoiceOverReadsLinkedPagesAndPreservedMessage
```

The final compact binding check uses `Phone-16.xcresult` / `phone-16.log` and only the maximum-text selector. `Phone-12` through `Phone-14` and `iPad-6` also use that single selector and their named result bundles. The app's ordinary-layout vocabulary/message/editor/recall and scan-navigation checks are the passes retained in `Phone-8` and `iPad-3`; those bundles also retain the subsequently revised maximum-text test failure. There is no claim of a current complete-suite pass.

Exact final iPhone command (`Phone-16`, exit 0):

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-voiceover/Phone-16.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/VoiceOverUITests/testVoiceOverFocusesNewPageAtMaximumTextInLandscapeScanning \
  test CODE_SIGNING_ALLOWED=NO
```

Exact final iPad command (`iPad-7`, exit 0):

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-voiceover/iPad-7.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/VoiceOverUITests/testVoiceOverFocusesNewPageAtMaximumTextInLandscapeScanning \
  -only-testing:BoardScannerUITests/VoiceOverUITests/testVoiceOverReadsLinkedPagesAndPreservedMessage \
  test CODE_SIGNING_ALLOWED=NO
```
