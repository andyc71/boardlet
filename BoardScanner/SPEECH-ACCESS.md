# Speech cancellation and communication accessibility

## Behavior

Every sheet that can start speech now provides a bottom speech bar while speaking: Phrases, Edit message (recall), and Communication settings (voice preview). **Stop speaking** stays reachable while the list scrolls or the search keyboard is open. **Command–period** also stops speech in these sheets. Voice errors appear in the same visible bar.

Opening a board library, settings, page browser/details, phrase library, sentence editor or typing sheet stops the previous utterance. Opening a nested phrase/token editor or deletion dialog also stops it. New speech initiated inside a speaking sheet is allowed and has its own Stop control. Closing that sheet leaves the main composer’s Stop available. The conversation is retained; cancellation does not erase words or recall. Backgrounding/inactivating the app stops speech without resuming automatically.

**Command–S** speaks the current message from the board. Command–Return was found unreliable by the actual keyboard UI journey and has been replaced in the app and help. Board shortcuts stay suspended behind editing sheets; the modal Stop shortcut remains available on the speaking screen.

The communication interface uses a stronger indigo tint, primary-colored ordinary action labels/status text, and explicit contrasting foregrounds for prominent buttons in light and dark appearance. Scan Select has stable Voice Control input labels (Select/Choose or Start scan), independent of its changing choice label.

## Verification scope

The UI journey enters a long message, starts/stops speech by keyboard, speaks a saved phrase while searching, stops it both by keyboard and by touch, reuses a sentence in the editor, stops recalled speech there, opens settings during speech, and backgrounds/reactivates the app. It asserts the observable speech state and preserved message. This exercises the actual synthesizer controls but does not establish what a person hears through a physical device’s speaker, Bluetooth routing, or audio interruptions from other apps.

XCTest’s native accessibility audit checks **hit regions, descriptions and traits** on the communication board with a message present. A separate contrast audit preserves an explicit expected-failure record for five exact controls where its result disagrees with sampled rendered pixels (Edit, Undo, Clear, Type and Phrases). Every other enabled contrast finding remains a normal failure. Contrast findings inside actually disabled controls are excluded. Missing descriptions, traits and hit-region failures remain normal failures. Inactive controls are exempt from the contrast requirement in [W3C’s explanation of WCAG 1.4.3](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html#inactive-user-interface-components). This scoped automated audit is not a claim of full WCAG conformance or VoiceOver/Switch Control traversal testing.

The first audit found genuine low contrast in enabled controls/status text as well as expected inactive-control findings. Those enabled controls were corrected. The first speech UI run exposed the ineffective Command–Return shortcut; Command–S passed the same workflow.

## Results — 27 October 2026

Artifacts are in `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-speech-access/`. Build products are in `board-scanner-access/KeyboardDerivedData` on the same external SSD.

- `Tests-1`: ten communication/message-editing unit tests passed. The accessibility audit and speech keyboard UI journey failed for the issues described above.
- `Tests-2`: the speech-sheet and background UI journey passed after changing to Command–S; three enabled contrast findings remained and were subsequently corrected.
- `Tests-3`: the final speech journey, existing phrase save/correct/relaunch journey and automatic-scan suspension journey passed on iPhone. The native contrast audit still failed despite the measured rendered values below.
- `iPad-1`: the same final speech journey passed on iPad. Its native contrast audit also reported the same discrepancy.
- `Audit-Light` and `Audit-Dark`: exit 0, zero unexpected failures, **one expected contrast discrepancy each**. Result-bundle summaries classify these as Expected Failure, not native contrast passes. Hit-region, description and trait checks completed without findings. The simulator’s original light appearance was restored and queried after the dark run.

Exact focused regression command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-speech-access/Tests-3.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/SpeechAccessUITests \
  -only-testing:BoardScannerUITests/PhraseCommunicationUITests \
  -only-testing:BoardScannerUITests/AccessUITests/testAutomaticScanningPausesForTypingAndBackground \
  test CODE_SIGNING_ALLOWED=NO
```

`Tests-1` used the same command shape with that result name, the SpeechAccessUITests selector, and unit selectors `BoardScannerTests/CommunicationSessionTests` and `BoardScannerTests/MessageEditingTests`. `Tests-2` selected only `BoardScannerUITests/SpeechAccessUITests`.

The iPad run uses the command above with destination `platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0`, result path `iPad-1.xcresult`, only `BoardScannerUITests/SpeechAccessUITests`, and `test-without-building`.

## Remaining device evidence

An inventory check found connected physical iPhone/iPad devices and iOS 18/26/27 simulator runtimes. No iOS 16.6 simulator runtime is installed. Current checks continue on the instructed iPhone 18 Pro/iOS 27 simulator and existing iPad simulator. No physical device was modified. Installed-voice/offline audibility, accessory routing, real VoiceOver/switch traversal and the 16.6 runtime remain unverified. Extreme combined text/button-size/landscape layouts remain tracked in ACCESS.md.

## Native audit discrepancy and rendered samples

The audit continued reporting “Contrast failed for SwiftUI.AccessibilityNode” even after its own captured PNG showed black labels on light backgrounds. For the exact element crops from Tests-3, representative foreground/background samples gave:

| Control | Foreground RGB | Dominant background RGB | Ratio |
| --- | --- | --- | --- |
| Edit | 0, 0, 0 | 246, 246, 248 | 19.46:1 |
| Undo, Clear, Type, Phrases | 8, 8, 9 | 207, 204, 224 | 12.74:1 |

Each foreground sample appears in more than 100 pixels; each background sample in more than 1,000. Crops were visually reviewed to identify text and background. The retained `contrast-samples.py` / `contrast-samples.json` calculate sRGB relative luminance and the light/dark ratio from the native audit’s element screenshots. This checks these rendered samples, not every pixel, appearance, or possible screen. The expected-failure annotation keeps the unresolved native result visible; it is not reported as a native contrast pass. Revisit it after SDK or styling changes.

Isolated light audit uses the Tests-3 command with result path `Audit-Light.xcresult` and only `BoardScannerUITests/SpeechAccessUITests/testCommunicationAccessibilityDescriptionsTargetsAndTraits`.

Dark appearance used the isolated light-audit command with `Audit-Dark.xcresult` and `test-without-building`, after `xcrun simctl ui BB33297D-F833-464B-B43D-14CBD0DA3021 appearance dark`. An EXIT trap ran the same command with `light` afterward; a final query returned `light`. Both audits recorded zero runtime warnings. The dark screenshot was visually inspected for readable text and prominent-action foregrounds; numerical ratios above apply only to the explicitly sampled light captures.


Maximum-text follow-up: the status/Stop bar now stacks when its horizontal arrangement cannot fit. Large-text message and phrase entry use a shorter scrollable text viewport. See [EXTREME-LAYOUT.md](EXTREME-LAYOUT.md) for the subsequent rotation journeys and their results.

VoiceOver traversal and explicit spoken command names are covered in [VOICEOVER.md](VOICEOVER.md), including the distinction between traversal evidence and unverified VoiceOver activation.

## Speech engine cancellation — 28 October 2026

`BoardScannerSpeechEngine` is an opt-in integration scheme using installed system voices and the actual `SpeechController`. Its three tests cover two consecutive finite messages, immediately stopping a long request and speaking again with an unavailable saved voice identifier, and twenty rapid replacements followed by two finite messages. They observe published state after submission and await the engine callback, without fixed sleeps. These tests are excluded from the ordinary scheme because they intentionally exercise system speech services and require an installed voice.

The baseline `Phone-1` run failed both replacement/restart journeys: the final short message remained active beyond 30 seconds. The ordinary consecutive-message test passed. The controller previously ignored the Boolean result of `stopSpeaking(at:)`. It now discards and replaces the synthesizer if a request exists and that cancellation returns false, detaching the previous delegate first. This prevents an uncancelled preparing queue from delaying the next request. Successful cancellation retains the engine. Apple's [stopSpeaking documentation](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/stopspeaking%28at%3A%29) defines false as an unsuccessful stop and describes cancellation as clearing queued utterances.

The corrected iPhone run `Phone-2` and iPad run `iPad-1` each passed all three tests, exit 0, with no skips or expected failures. The result summaries report no runtime warnings, but the consoles contain system VoiceDB fallback/decoding messages, AXCommon concurrency diagnostics and AudioQueue underflow messages. Retain those logs; this is not a clean audio-quality assessment. A false speaking state reflects the controller's finish/cancel callback handling; it does not prove every word was audible or distinguish a system cancellation from successful audible completion. No physical-device check was performed.

Artifacts: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-speech-engine/`, with matching `.log` and `.xcresult` names.

Exact corrected iPhone command (the baseline used `Phone-1` instead):

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerSpeechEngine \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-speech-engine/Phone-2.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
```

Exact iPad command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerSpeechEngine \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-speech-engine/iPad-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
```

`Phone-Regression` passed all 12 selected checks (ten communication/message unit tests and two speech-control UI journeys), exit 0, zero failures/skips/expected failures and no result-summary runtime warnings. The UI checks retain keyboard/sheet cancellation, background cancellation, message preservation and maximum-text Stop visibility through rotation after the engine change. The unrelated native contrast audit was not selected for this focused run.

Exact focused speech-control regression command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-speech-engine/Phone-Regression.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/CommunicationSessionTests \
  -only-testing:BoardScannerTests/MessageEditingTests \
  -only-testing:BoardScannerUITests/SpeechAccessUITests/testSpeechCanBeStoppedFromPhraseAndRecallSheetsAndAfterBackgrounding \
  -only-testing:BoardScannerUITests/SpeechAccessUITests/testMaximumTextKeepsPhraseSpeechStopVisibleAcrossRotation \
  test CODE_SIGNING_ALLOWED=NO
```
