# Isolated “I” pronunciation — 28 October 2026

The supplied Motor Plan 66 database stores button 1 as label `I`, no separate message, and a single add-message command. It does not contain the words “capital I”. A standalone capital can be interpreted as a letter by the system voice even though the same text is pronounced correctly in a sentence.

`SpeechController` now supplies Apple's `AVSpeechSynthesisIPANotationAttribute` with `aɪ` for an isolated `I` when the resolved voice language is English. The hint applies only to that character, allowing surrounding whitespace. The board, message tokens, saved phrases and utterance text retain their original spelling. Sentences, explicitly written `capital I`, other words and non-English voices receive no override. Voice selection and speech speed remain unchanged.

Apple documents [IPA pronunciation attributes](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisipanotationattribute) and [attributed utterances](https://developer.apple.com/documentation/avfaudio/avspeechutterance/init(attributedstring:)). Both are available before the app's iOS 16.6 deployment target.

## Verification

Artifacts: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/`.

- `Pronoun-Folder-1.xcresult`: all **eight communication tests pass**, including retention of the IPA attribute by `AVSpeechUtterance`, language/whole-word boundaries, and composing `I want water` without altering its text. The run overall failed its separate folder-label layout check; it is not reported as a clean run.
- `Pronoun-Engine-1.xcresult`: **three actual speech-engine tests pass**, zero failures, exit 0. The completion sequence now includes standalone `I`, followed by `I want water.` and `Please help me.`. Rapid replacement and stop/restart also pass.
- These checks verify the pronunciation request and actual engine completion on the existing iPad (A16), iOS 27.0 simulator. They do not constitute an auditory assessment of every installed voice or physical-device output. VoiceOver activation verification remains deferred at the user's request.

Exact commands, run from the repository root (each command's output redirected to its same-named `.log`):

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/iPadDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/Pronoun-Folder-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  '-only-testing:BoardScannerTests/CommunicationSessionTests' \
  '-only-testing:BoardScannerUITests/AccessUITests/testNarrowImportedFolderLabelsKeepReadableWidth' \
  test CODE_SIGNING_ALLOWED=NO

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerSpeechEngine \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/iPadDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/Pronoun-Engine-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
```
