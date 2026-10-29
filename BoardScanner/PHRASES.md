# Phrases and message correction

Choice Board Scanner supports reusable text phrases and correction of the current picture sentence. These features work with screenshot boards, imported page sets and newly authored boards.

## Use

- **Phrases** opens a searchable collection shared by every board on this device. Tap a phrase to append it to the current sentence; selection speech follows the existing voice and selection-speech preference. Its Options menu can **Speak now** without changing the current sentence, edit its words/name, or delete it with confirmation.
- **Save current message** creates a phrase from the current sentence. **New phrase** starts with blank text. A name is optional; without one, the message supplies the display name. Phrases save as text, without copying picture tokens or changing board vocabulary.
- Use **Edit** in the phrase library to reorder phrases. Reordering is disabled while searching. **Undo phrase deletion** restores the last deleted phrase during the current app session.
- Tap the pencil beside the message strip to **Edit message**. Tap a selection to correct its words; its picture stays attached. **Organize** exposes removal and drag reordering. VoiceOver actions also offer Move earlier and Move later.
- **Add last message** appends the last sentence accepted by **Speak**/**Speak now**, or the last cleared sentence. Picture tokens are preserved for composed sentences. Repeated reuse creates separate selections; it does not replace words already in the composer. A reused sentence speaks once when selection speech is enabled.
- Correction, reordering and removal stop existing speech but do not automatically speak the edited sentence. Press **Speak** to read the result. Clear-after-speaking retains the sentence for recall, provided the speech request was accepted.

Phrases and Edit message show a persistent **Stop speaking** bar whenever they initiate speech. Command–period also stops it. Opening a nested editor or deletion dialog stops the previous utterance. See [speech access verification](SPEECH-ACCESS.md).

## Storage and privacy

Saved phrases use a bounded, versioned text collection in `communication.phrases.v1` in UserDefaults. The initial common phrases are seeded only when the key is absent; deleting all phrases leaves an empty library on subsequent launches. The library holds up to 500 phrases, 200 characters per name, 10,000 characters per message, and a total encoded size of 1 MB. Invalid edits leave the saved collection unchanged.

Unreadable stored phrases are not silently replaced. The UI offers an explicit reset and retains the unreadable payload under a recovery key. Saved phrases are device preferences and are not part of a `.boardscan` export.

The sentence and last-message recall stay in memory. Opening another board or restarting the app clears both. Page navigation within a board keeps them. Saved phrases and speech preferences survive those changes. UI tests using an isolated library UUID also get isolated preferences; production preferences are unaffected.

## Verification — 27 October 2026

Artifacts: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-phrases/`. The standalone build passed (`Build-1.log`). Focused verification passed **14 unit tests and 1 UI journey**, zero failures/skips (`Tests-3.xcresult`, `Tests-3.log`, exit 0). The iPhone screenshot was visually reviewed: all six conversation controls, the sentence-edit pencil and board vocabulary remain visible. **Full regression: TEST SUCCEEDED**, exit 0, **75 passed, 5 optional supplied-file tests skipped, zero failures** (`Regression-1.xcresult`, `Regression-1.log`; 70 unit and 10 UI identifiers). **Initial successful iPad journey: TEST SUCCEEDED**, exit 0, **1 UI test passed** (`iPad-2.xcresult`, `iPad-2.log`, existing iPad A16/iOS 27.0). Both retained composer screenshots were visually reviewed.

Tests cover phrase creation/edit/order/delete/restore across relaunch, empty-library retention, invalid and corrupt data preservation, token identity/artwork under edits, ordered multi-selection moves, recall and punctuation, failed speech requests, clear-after-speaking, and conversation reset. The UI journey corrects a sentence, saves it as a phrase, recalls it, relaunches without conversation history, reuses the saved phrase, deletes it and undoes deletion.

The initial UI run identified a confusing permanently active list-edit mode. The editor now uses an explicit Organize action so the default word buttons retain clear labels and activation behavior.

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
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-phrases/Tests-3.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/PhraseLibraryTests \
  -only-testing:BoardScannerTests/MessageEditingTests \
  -only-testing:BoardScannerTests/CommunicationSessionTests \
  -only-testing:BoardScannerUITests/PhraseCommunicationUITests \
  test CODE_SIGNING_ALLOWED=NO
```

The implementation retains iOS 16.6 support and uses native SwiftUI controls. Production PECS Maker targets and shared picker sources are unchanged. Physical speech, accessibility service behavior and older-OS runtime verification remain separate acceptance work tracked in AAC.md.

Full regression and iPad commands:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-phrases/Regression-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-phrases/iPad-2.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/PhraseCommunicationUITests \
  test CODE_SIGNING_ALLOWED=NO
```

The UI test uses search after saving and reopening, so saved entries need not fit in the initial viewport. An initial iPad run asserted an offscreen row existed before searching; the test was corrected without changing app behavior.

`git diff --check` and whitespace checks passed. Xcode retains its existing XCTest minimum-OS, skipped App Intents metadata and iPad orientation-declaration warnings. No new app runtime warning was observed in these journeys.

Visual review found the new Phrases label wrapping in an unnecessarily narrow iPad grid column. The action grid now uses a 116-point minimum scaled with Dynamic Type. Organize also remains dismissible after all selections are removed. Final-source iPad verification passed **1 UI journey** (`iPad-3.xcresult`, `iPad-3.log`, exit 0); its screenshot confirms Phrases stays on one line. All **14 focused unit tests** also passed in `Tests-4`. That run’s UI case needed an additional test step to close compact search before tapping the temporarily hidden Done button. **Final iPhone UI: TEST SUCCEEDED**, exit 0, **1 journey passed** (`Tests-5.xcresult`, `Tests-5.log`). The app source is unchanged from the successful final iPad and model checks.


Final-source commands use the same project, scheme, DerivedData and timeout options above:

- iPad: the iPad command above with `iPad-3.xcresult` (log `iPad-3.log`).
- Focused iPhone model checks: the focused command with `Tests-4.xcresult` and `test-without-building` (log `Tests-4.log`). Its UI failure was test setup, as described above; it is not counted as a passed journey.
- Final iPhone UI: the focused command with `Tests-5.xcresult`, only `-only-testing:BoardScannerUITests/PhraseCommunicationUITests`, and `test` (log `Tests-5.log`).
