# Validation record — 2026-09-21

Toolchain: Xcode 27.0 (27A266a), iOS Simulator SDK 27.0, Apple Silicon. App and test deployment target: 16.6. No iOS 16.6 runtime is installed, so the minimum OS is compile-checked but not runtime-tested here. Production targets and deployment settings were not changed. Installed iOS 18.0, 18.2, and 26.2 runtimes were not exercised; the selected matrix covers iOS 18.4, 26.5, and 27.0. Only Xcode 27.0 is installed, so this records that toolchain against multiple runtimes, not separate Xcode 26 and Xcode 27 builds.

## Portrait and landscape matrix

All **84/84 tests passed**, with zero failures or skips in the six final result bundles: 48 real system-picker UI tests (four journeys × two orientations × six devices) and 36 importer tests. Each UI test verifies the actual application-window aspect ratio. Landscape means `.landscapeLeft` device orientation.

| Device | Runtime/build | Portrait UI | Landscape UI | Importer | Final result bundle |
| --- | --- | --- | --- | --- | --- |
| iPhone 16 | 18.4 / 22E238 | 4/4 | 4/4 | 6/6 | `/private/tmp/pecs-picker-matrix-18-phone-final.xcresult` |
| iPad Pro 11-inch (M4) | 18.4 / 22E238 | 4/4 | 4/4 | 6/6 | `/private/tmp/pecs-picker-matrix-18-pad-retry.xcresult` |
| iPhone 17 | 26.5 / 23F77 | 4/4 | 4/4 | 6/6 | `/private/tmp/pecs-picker-matrix-26-phone-final.xcresult` |
| iPad Pro 11-inch (M5) | 26.5 / 23F77 | 4/4 | 4/4 | 6/6 | `/private/tmp/pecs-picker-matrix-26-pad/Tests.xcresult` |
| iPhone 17 | 27.0 / 24A434 | 4/4 | 4/4 | 6/6 | `/private/tmp/pecs-picker-matrix-27-phone/Tests.xcresult` |
| iPad Pro 11-inch (M5) | 27.0 / 24A434 | 4/4 | 4/4 | 6/6 | `/private/tmp/pecs-picker-matrix-27-pad-final2.xcresult` |

These are the final passing runs after adapting the shared UI driver to the observed layouts; the superseded attempts are recorded below. No picker/import implementation change was needed. The harness now declares landscape support, tests inherit the same journeys for both orientations, and the driver handles visible scrolling, iPad sidebar/Search variants, and container-sized toolbars.

Reproduce all six devices serially with:

```sh
MATRIX_DIR=/absolute/new/matrix-directory PhotoPickerHarness/Scripts/test-matrix.sh
```

Every final bundle was independently checked with `xcresulttool get test-results summary`; the combined local record is `/private/tmp/pecs-picker-matrix-summary.json`. Full-screen iOS 27 screenshot and hierarchy exports are in `/private/tmp/pecs-picker-matrix-evidence-27-phone` and `/private/tmp/pecs-picker-matrix-evidence-27-pad`. All six matrix-owned disposable simulators were removed after testing. Personal simulators and production targets were not modified.

## Earlier portrait-only runs

| Device | Runtime/build | Result | Result bundle |
| --- | --- | --- | --- |
| Dedicated iPhone 17 | iOS 26.5 / 23F77 | Initial gate: open/cancel and select/import passed, 2/2 | `/private/tmp/pecs-picker-proof3-26.5.xcresult` |
| Dedicated iPhone 17 | iOS 27.0 / 24A434 | Gate: open/cancel and select/import passed, 2/2 | `/private/tmp/pecs-picker-proof2-27.xcresult` |
| Dedicated iPhone 17 | iOS 26.5 / 23F77 | Final setup/test/cleanup script: 10/10 passed, no skips | `/private/tmp/pecs-picker-final-26.5/Tests.xcresult` |
| Dedicated iPhone 17 | iOS 27.0 / 24A434 | Final expanded suite: 10/10 passed, no skips | `/private/tmp/pecs-picker-final-27.xcresult` |
| Dedicated iPhone 16 | iOS 18.4 / 22E238 | 6 importer tests + 4 real-picker UI tests passed, 10/10, no skips | `/private/tmp/pecs-picker-full2-18.4.xcresult` |

Result bundles and screenshots are local run artifacts, not committed binaries. Every expanded UI run records the actual picker accessibility tree and screenshots as attachments, plus the imported-content tree and screenshot. `xcrun xcresulttool get test-results summary --path <bundle>` reports counts, runtime builds, and device details. Export evidence with `xcrun xcresulttool export attachments --path <bundle> --output-path <directory>`.

The first two gate runs used a minimal harness before expanding the suite. The initial 26.5 proof used exact decoded PNG pixels; the final fixtures use distinct EXIF-dated JPEGs and dimension/dominant-color checks. These are actual Photos library selections loaded through real item providers, not an in-app fixture substitution.

## Commands

Initial builds/tests used XcodeBuildMCP `build_sim`/`test_sim`, which ran `xcodebuild build-for-testing` followed by `test-without-building` against the dedicated simulator UUIDs. Equivalent direct invocation from the repository root:

```sh
xcodebuild -project PhotoPickerHarness/PhotoPickerHarness.xcodeproj \
  -scheme PhotoPickerHarness \
  -destination 'platform=iOS Simulator,id=<dedicated-simulator-uuid>' \
  -derivedDataPath /private/tmp/pecs-picker-derived \
  -parallel-testing-enabled NO \
  -resultBundlePath /private/tmp/pecs-picker-run.xcresult test
```

For the initial gate, add `-only-testing:PhotoPickerHarnessUITests/RealPickerTests/testOpenCancel` and `-only-testing:PhotoPickerHarnessUITests/RealPickerTests/testSelectAndImport`. The final 26.5 run used exactly:

```sh
RUN_DIR=/private/tmp/pecs-picker-final-26.5 PhotoPickerHarness/Scripts/test.sh
```

The script exited successfully and removed its simulator and ownership file. Manual guard checks confirmed that `delete` and `reset` reject a state file naming an unowned device, and `create` rejects an existing state file before invoking simulator commands. The test-runner guard also rejects an existing ownership file/result bundle before installing its cleanup trap; this was checked with an existing state file and verified to leave it unchanged.

The checked-in `Scripts/test.sh` also records the toolchain and runtime inventory and creates/seeds/deletes its own simulator.

The shared source also built successfully in production's Swift 5 language mode (exit 0; empty warning/error log):

```sh
xcodebuild -project PhotoPickerHarness/PhotoPickerHarness.xcodeproj \
  -scheme PhotoPickerHarness -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /private/tmp/pecs-picker-swift5 -quiet \
  ARCHS=arm64 SWIFT_VERSION=5.0 build
```

All four task-created disposable simulators from the earlier portrait-only validation were deleted after those runs. No production UI suite or destructive `SetupPhotos` test ran. Project plist validation, shell syntax validation, simulator ownership/reuse guards, and `git diff --check` also passed.

## Failures investigated rather than skipped

- **Expanded orientation/device matrix:** initial iOS 18 landscape tests exposed off-screen grid cells and imported labels skipped by scroll momentum; initial iPad tests exposed Photos as a `PhotosSidebarScrollView` cell rather than a button. The helper now supports that sidebar, dismisses the optional privacy explainer, bounds grid taps between navigation and toolbar, and uses slow drags with a hold before release. Imported labels must actually be hittable. Initial bundles: `/private/tmp/pecs-picker-matrix-18-phone/Tests.xcresult`, `/private/tmp/pecs-picker-matrix-18-pad/Tests.xcresult`. The first iPhone retry still overshot labels; its log is `/private/tmp/pecs-picker-matrix-18-phone-retry.log`.
- **26.5 landscape grid:** the scroll view is named `photosView_content_scroll_view`, while iOS 18 uses `content_scroll_view`. The helper supports both observed identifiers and allows half a point of frame rounding at grid edges. The initial iPhone run also reported one portrait multi-selection count mismatch; the subsequent full run rechecks selection order and exact decoded content. Original log: `/private/tmp/pecs-picker-matrix-26-phone.log`. Two failed-run collectors stalled after their test runners exited and were terminated; their logs are retained, and the passing full reruns use separate result bundles.
- **Landscape screenshot capture:** XCTest's `app.screenshot()` produced offset/cropped landscape attachments despite correct landscape accessibility frames. A direct simulator screenshot confirmed the complete iPad presentation (`/private/tmp/pecs-picker-26-pad-live.png`). Evidence capture now uses `XCUIScreen.main.screenshot()`; earlier bundles retain their original app captures and complete accessibility trees.
- **27.0 iPad accessibility:** Search is an embedded `TextView` inside `photosSearchBar`, with a separate `Search your library…` static label. Several `Toolbar` elements cover entire containers, and enumerating them by index produced a snapshot mismatch as their count changed. The helper recognizes the actual Search control, subtracts only a compact toolbar, and uses a stable first-match lookup. The two superseded attempts were cancelled; logs: `/private/tmp/pecs-picker-matrix-27-pad.log` and `/private/tmp/pecs-picker-matrix-27-pad-final.log`.
- **Diagnostics collection:** optional `simctl diagnose` processes stalled after some runs, including the successful iOS 26 iPad run. The optional collector for the final iOS 27 iPad run was also stopped to avoid the same delay. Stopping those collectors allowed Xcode to finalize its result bundle with exit 0 and 14 passing tests; screenshot, hierarchy, and test-result evidence remains available. Stopped diagnostic collections may be incomplete.
- **26.5 thumbnail hit testing:** the first run opened/cancelled successfully but `XCUIElement.tap()` failed with `Not hittable: Image, {{0.0, 312.0}, {132.9, 133.0}}, label: 'Photo, September 21, 4:19 PM'`. The tree identified `PXGGridLayout-Info` in the out-of-process picker. A tap at the center of that queried frame selected the image and the decoded-image assertion passed. The driver retains this bounded fallback; there are no fixed device-coordinate taps. Evidence: `/private/tmp/pecs-picker-proof-26.5.xcresult`.
- **26.5 completion label:** the actual control is `Done`; the older picker uses `Add`. Both are handled in the driver.
- **18.4 Search accessibility:** Search appears as a `TextView` with value `Search your library…` under navigation bar `Photos`, alongside the `magnifyingglass` image. The initial expanded run failed the too-narrow Search query, while all six importer tests passed. Adding the observed text-view variant allowed all UI tests to pass. Evidence: `/private/tmp/pecs-picker-full-18.4.xcresult` and the passing `full2` bundle.
- **27.0 first app launch:** one initial gate attempt timed out acquiring the app's background assertion before picker interaction. The other test selected and loaded the dated photo, but exposed a fixture color-profile mismatch in the assertion. The image evidence now draws into explicit sRGB and checks dimensions and dominant decoded color. A subsequent complete gate passed both tests without skips. Both attempts are retained (`pecs-picker-proof-27.xcresult`, `pecs-picker-proof2-27.xcresult`).
- Xcode 27 emits linker warnings because its XCTest libraries have minimum iOS 17.0 while the harness targets 16.6, plus the standard “no AppIntents.framework dependency” metadata warning. This does not raise the app deployment target. Use a toolchain compatible with an older runtime to validate iOS 16.6 itself. No Swift concurrency warnings remain in the tested source.
- The iPad runtimes also warn that support for all orientations will soon be required: the harness currently declares portrait and both landscape orientations, but not upside-down portrait. This matrix exercises portrait and landscape-left device orientation, not upside-down portrait or both landscape directions.

## Coverage and limits

Automated real-picker coverage: actual Cancel/Photos/Search/grid UI; empty cancel; single-image import; multi-image import in selection order; cancel with an existing imported batch and a new tentative selection; reopen after cancel; successful replacement; single-selection mode and repeated presentation. Assertions check thumbnail existence, dimensions, decoded color, and count as well as dismissal.

Automated importer coverage: loading/progress state, sequential ordered atomic commit, provider error, corrupt image, preserved previous data, cancellation of provider progress, late callbacks, superseding imports, empty selection, recovery, and a registered NSItemProvider without asset access. These deterministic tests exercise shared import code and are separate from the real-picker tests.

Remaining manual checks: semantic Search results/indexing, iCloud offloaded downloads and network errors, physical device behavior, iPad multitasking/window resizing, interactive sheet dismissal, very large/rotated/HEIF/Live Photo assets, and accessibility with VoiceOver. The suite checks Search's presence only. Local simulator media does not exercise iCloud. No requested automated picker scenario has been replaced with a fixture-only pass.
