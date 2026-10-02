# MediaFramework local package

This package is based on `andyc71/MediaFramework` at revision
`a489754542a3d2c5daa251dc2a59553022ac06b3`.

`AudioHelper` owns the application's audio session for AAC speech, recorded AAC
selections, and voice previews. Its shared `SpeechSession` configures `.playback`,
`.voicePrompt`, and only `.duckOthers`, then activates immediately before playback.
It never requests `.interruptSpokenAudioAndMixWithOthers`. `MuteViewModel` observes
volume without activating or deactivating the session.

Speech submissions, cancellations, playback, and session transitions use one serial
background queue. The synchronous `AVAudioSession.setActive` call can block the
main thread; the native asynchronous API is unavailable on iOS 16.6. Submitted
utterances and playing clips retain ownership until their completion callbacks.
`didFinish` and `didCancel` release an utterance; a deferred idle check releases the
session with `.notifyOthersOnDeactivation` only when all helpers have finished.
Already submitted selections and cancellation replacements are processed before
that check. Duplicate and late callbacks cannot release another utterance's session.

Explicit cancellation clears the helper's complete speech queue, including
utterances that never started and may not deliver cancellation callbacks. It also
replaces the synthesizer: on iOS 27, cancelling during voice preparation can return
`false` while `isSpeaking` is `false`, leaving pending speech otherwise uncleared.
A failed stop while speech is still running retains session ownership until
completion. Voice selection, language, rate, pitch, volume, and normal utterance
queuing remain unchanged. Audio-session errors are logged through LogFramework;
playback is still attempted. If deactivation fails, ownership remains marked active
so a subsequent idle transition retries it.

Neither production app enables background audio. On entering the background,
the helper cancels speech and stops recorded playback to release the session before
suspension. Foreground speech activates it again. Leaving the AAC screen keeps the
existing global helper alive and allows speech to finish; leaving voice settings
cancels that screen's preview.

## Verification

`Tests/MediaFrameworkTests/AudioHelperTests.swift` is also referenced by the
production `PECS MakerTests` target. It covers configuration, activation order,
30 rapidly queued utterances, cancellation, immediate replacement, stale callbacks,
multiple helpers, background notifications, cleanup, and session failures. Live
simulator tests exercise native speech completion, cancellation both during voice
preparation and after `didStart`, replacement, and recorded playback completion.
These tests do not modify the simulator's photo library.

Verified on the existing iPhone 18 Pro / iOS 27.0 simulator: both production builds
and all 16 `AudioHelperTests` passed with the standard test plan's Thread Sanitizer.
The final commands are shown below. XcodeBuildMCP supplies its usual index/cache
and macro-validation arguments; these are the equivalent source-build commands:

```sh
cd /Users/andy/dev/PECSMaker
task_package_cache=/Users/andy/Library/Developer/Xcode/DerivedData/PECS_Maker-gckgzretvnrfnscmrgvkuwgkoizh/SourcePackages
task_build_args=(
  -project 'PECS Maker.xcodeproj'
  -configuration Debug
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021'
  -derivedDataPath Packages/MediaFramework/.build/AppDerivedData
  -clonedSourcePackagesDirPath "$task_package_cache"
  -disableAutomaticPackageResolution
  "BOARDLET_PACKAGE_CHECKOUTS=$task_package_cache/checkouts"
  CODE_SIGNING_ALLOWED=NO
)
xcodebuild "${task_build_args[@]}" -scheme 'PECS Maker' build
xcodebuild "${task_build_args[@]}" -scheme 'Easy PECS Plus' build
xcodebuild "${task_build_args[@]}" -scheme 'PECS Maker' \
  '-only-testing:PECS MakerTests/AudioHelperTests' -parallel-testing-enabled NO test
```

The exact emitted `xcodebuild` commands (including XcodeBuildMCP's
`build-for-testing` and `test-without-building` steps) and results are recorded in:

- [PECS Maker build: succeeded](/Users/andy/Library/Developer/XcodeBuildMCP/workspaces/PECSMaker-9247489f2c67/logs/build_sim_2026-10-02T06-51-34-655Z_pid79113_d73bff69.log)
- [Easy PECS Plus final build: succeeded](/Users/andy/Library/Developer/XcodeBuildMCP/workspaces/PECSMaker-9247489f2c67/logs/build_sim_2026-10-02T07-13-21-209Z_pid79113_5e1e1e1d.log)
- [PECS Maker final test build and run: 16 passed, 0 failed](/Users/andy/Library/Developer/XcodeBuildMCP/workspaces/PECSMaker-9247489f2c67/logs/test_sim_2026-10-02T07-16-35-733Z_pid79113_d2625f17.log)

A fresh dependency resolution failed because DynavoxSymbols has a missing remote
Git LFS object. The existing dependency cache avoids that download. Supplying
`BOARDLET_PACKAGE_CHECKOUTS` also resolves existing UI-test source references when
using this cache and a custom DerivedData directory.

### Physical-device checks still required

Automated tests verify lifecycle and native playback completion, not audible
cross-app attenuation or the hardware silent switch. On each production variant:

| Scenario | Check | Status |
| --- | --- | --- |
| Apple Music | Playback continues, ducks for speech, promptly restores volume | Not device-tested |
| Spotify or equivalent | Same as Apple Music | Not device-tested |
| Podcast | Continues throughout speech without pausing; ducks and restores | Not device-tested |
| Audiobook | Continues throughout speech without pausing; ducks and restores | Not device-tested |
| Hardware silent switch enabled | AAC speech and recorded selections remain audible | Not device-tested |
| No background audio | Normal voice and recorded playback; session releases | Native simulator tests passed; listening check pending |
| Rapid selections and queued utterances | One activation through the queue; no permanent ducking | Lifecycle tests passed; cross-app check pending |
| Cancel during speech | Release when the queue is cancelled | Callback tests passed; cross-app check pending |
| Cancel and immediately replace | No premature release; restore after replacement | Native simulator tests passed before and after speech starts |
| Leave AAC screen during speech | Existing speech finishes and releases the session | Code path inspected; UI/device check pending |
| Background/foreground | Background cancels/releases; foreground speech works again | Notification-driven tests passed; actual UI/device transition pending |

Persistent system errors can prevent successful activation or deactivation. They
are logged and do not crash the AAC interface; deactivation is retried at the next
idle transition. External apps' own playback policies still require device checks.
