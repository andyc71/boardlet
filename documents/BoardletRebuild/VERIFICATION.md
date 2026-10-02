# Native verification — 2 October 2026

Environment: Xcode 27.0 (27A266a), iOS 27.0 simulator runtime. Commands run from `/Users/andy/dev/PECSMaker`. No production app identity or Photos database was replaced or removed. Baseline status entries are unchanged; implementation is in the new `Boardlet/` directory and these handoff records.

## Final commands

Both-device test command (iPhone light appearance, iPad dark appearance):

```sh
xcodebuild -project Boardlet/Boardlet.xcodeproj -scheme Boardlet \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -destination 'platform=iOS Simulator,id=E4B44237-C067-4F3E-881A-58024523D11F' \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -derivedDataPath Boardlet/.build/DerivedData \
  -resultBundlePath Boardlet/.build/release-candidate-check.xcresult \
  test CODE_SIGNING_ALLOWED=NO > Boardlet/.build/release-candidate-check.log 2>&1
```

Result: **PASS, exit 0**. Twenty test methods (17 behavioral and three UI), 24 expanded cases per device (48 total), zero failures, zero skipped tests and zero runtime warnings. The inspector reserves canvas space and full-screen captures verify landscape rendering. The result-bundle name does not assert release readiness. The preceding `delivery-verification.xcresult` also passed 48 cases in light appearance.

Plus build:

```sh
xcodebuild -project Boardlet/Boardlet.xcodeproj -scheme BoardletPlus \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath Boardlet/.build/PlusDerivedData \
  build CODE_SIGNING_ALLOWED=NO > Boardlet/.build/build-plus-final.log 2>&1
```

Result: **BUILD SUCCEEDED, exit 0** for the final source state.

Additional dark-appearance run completed with exit 0, one UI workflow passed:

```sh
xcrun simctl ui E4B44237-C067-4F3E-881A-58024523D11F appearance dark
xcodebuild -project Boardlet/Boardlet.xcodeproj -scheme Boardlet \
  -destination 'platform=iOS Simulator,id=E4B44237-C067-4F3E-881A-58024523D11F' \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -derivedDataPath Boardlet/.build/DerivedData \
  -resultBundlePath Boardlet/.build/dark-verification.xcresult \
  -only-testing:BoardletUITests/BoardletUITests/testCreateEditUsePrintAndReopen \
  test-without-building CODE_SIGNING_ALLOWED=NO > Boardlet/.build/dark-verification.log 2>&1
```

The original light appearance was restored successfully after verification with `xcrun simctl ui E4B44237-C067-4F3E-881A-58024523D11F appearance light`.

## What the tests cover

Seventeen behavioral tests cover edits/order/undo/redo/reopen and retained recording references; revision-safe writes; corrupt manifest recovery; unsafe/future schemas; five pagination cases; PDF label/credit/page-size content; duplicate message entries; read-only legacy import, missing assets and repeated import; complete archives; successful and failed Photos provider loading plus late cancellation; failed-save retry and failed-load protection; injected AI HTTPS/response behavior; the real nine-card Fruit legacy fixture; production-identity migration gating; cancellation during microphone permission; and camera-oriented crop output.

Three UI workflows on each device cover creation and Routine selection, persisted reopen, board controls open/close, Use with portrait-to-landscape rotation, native PDF preview, blank board and text card creation, real shared Photos picker presentation/cancellation, editable Spanish labels, and Spanish at accessibility XXXL including scrolled card actions. The tests use unique test libraries and do not delete existing app or Photos data. Native Photos selection is covered at the provider-loading boundary; the UI run opens/cancels the real system picker but does not select a user's picture.

Screenshots exposed and led to fixes for iPad card navigation/toolbars, inspector presentation and canvas overlap, keyboard/template selection, PDF SF Symbol rendering, ambiguous Cancel controls, large-text save status and PDF singular page grammar. The shared Photos source was not changed. Historical failing and incomplete result bundles remain under `.build` for diagnosis and are not pass evidence.

## Remaining coverage and integration gaps

- No iPhone Duo simulator or SDK 27.1 is installed. Fold/pose/reserved-region and cross-size-class edit continuity remain unverified. Standard safe areas and container layout are implemented; no Duo-specific API is invented.
- A real resized iPad window was not verified. The desktop Simulator application is now listed as Device Hub; native app accessibility selection timed out twice. The available simulator semantic snapshot did not expose a window resize handle. Narrow container and accessibility sheet behavior needs a direct window-resize pass.
- Text entry is exercised. The iPad screenshot uses hardware keyboard input and does not prove software-keyboard avoidance. VoiceOver, Voice Control, Switch Control, Reduce Motion and physical touch-target auditing need a dedicated device pass; accessibility names and explicit action alternatives are present.
- No iOS 16.6 runtime is installed. The deployment target remains 16.6 for every target. The current XCTest/Testing binaries emit an iOS 17 minimum-runtime linker warning. No target was raised to silence it.
- Actual camera capture, microphone playback/recording quality, audio-route interruptions, Personal Voice, Photos save permission/output and AirPrint hardware require device verification. Audio interruption handling exists, but there is no claim of a real telephone-call interruption test.
- Live ARASAAC search/download was not exercised during the offline/local test run. The production local client is used, attribution persists, and downloaded media is local.
- Dynavox new-search parity is blocked by the missing pinned Git LFS object documented in `PROGRESS.md`; optional AI generation has no configured application endpoint. AI request/error behavior is tested with an injected executor, not a live backend.
- The importer and production identity gate pass fixture tests. The signed old-version → new-version installation sequence under both production identities has not been performed. Follow `UPGRADE-PATH.md` before any release identity change.

No old production scheme or shared-source change was made, so the legacy production tests and disposable Photos matrix were not rerun. Do not interpret new-project passes as verification of the user's pre-existing production edits.

## Retained native evidence

These are unmodified full-screen simulator captures from the final passing run, not HTML mockups:

- [iphone-editor.png](evidence/iphone-editor.png)
- [iphone-communication-landscape.png](evidence/iphone-communication-landscape.png)
- [iphone-print-preview.png](evidence/iphone-print-preview.png)
- [ipad-controls-dark.png](evidence/ipad-controls-dark.png)
- [ipad-communication-landscape-dark.png](evidence/ipad-communication-landscape-dark.png)
- [spanish-large-text-iphone.png](evidence/spanish-large-text-iphone.png)
- [Authoritative test summary](evidence/test-summary.json)

The complete `.xcresult` bundles and exported attachment manifests remain in ignored `Boardlet/.build/`.
