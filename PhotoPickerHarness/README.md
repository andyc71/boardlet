# System Photos picker harness

A standalone, dependency-free iOS app plus XCUITests. Open `PhotoPickerHarness.xcodeproj` and select the `PhotoPickerHarness` scheme. The project is checked in; XcodeGen is needed only after editing `project.yml` (`xcodegen generate --spec PhotoPickerHarness/project.yml` from the repository root).

## Shared integration

The canonical implementation lives in `../Shared/SystemPhotoPicker`, included by source reference rather than copied into the harness. Add these same files to the PECS Maker and Easy PECS Plus targets when migrating. `SystemPhotoPicker` presents Apple's `PHPickerViewController`; `PhotoImportModel` loads item-provider representations, publishes loading/error/cancel states, and commits a complete ordered image batch. The view owning the sheet also owns the importer, so dismissal does not destroy the import. No Photos usage-description key, photo-library authorization request, asset identifier, or `PHAsset` fetch is needed.

Both production app targets and the harness deploy to **iOS 16.6**; the production project-level default is 14.0, overridden by the targets. Nothing raises a production deployment target. PHPicker fits the existing UIKit presentation boundary, supports ordered selection, and can also be wrapped in SwiftUI. SwiftUI PhotosPicker is available at this deployment target, but would not improve the system accessibility boundary under test. The shared source is built in Swift 6 mode with complete concurrency checking; production remains Swift 5.

The legacy `PECS Maker/PhotoPicker/PhotoPicker.swift` wrapper is not reused: it clears bound images on empty results, appends in provider-completion order, and ignores provider errors. Current production entry points in `Extensions/View+selectPhotos.swift` use `ZLPhotoPickerPresenterVC`. They remain unchanged. Do not introduce a third importer when migrating: replace the old wrapper with this shared boundary.

Import semantics: `0` means unlimited, `1` means single selection. Each presentation starts unselected. A successful batch replaces the previous images atomically; cancellation or any item failure retains the previous batch. An error identifies the failed selection index. The user can cancel a slow import; provider progress is cancelled and generation checks reject late callbacks. A new import supersedes an older one. Selected images are decoded at their original size; a production migration should choose a memory/size policy for very large batches and images.

## Reproducible simulator run

Requirements: Xcode with a compatible installed iOS simulator runtime, Python 3, and command-line tools selected with `DEVELOPER_DIR` or `xcode-select`. No CocoaPods or production package resolution is needed.

From the repository root:

```sh
# Creates, boots, seeds, tests, and deletes only a new disposable simulator.
PhotoPickerHarness/Scripts/test.sh

# Older runtime / current release / upcoming beta: choose installed identifiers.
RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-18-4 \
DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-16 \
PhotoPickerHarness/Scripts/test.sh

DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-27-0 \
DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-17 \
PhotoPickerHarness/Scripts/test.sh

# Quick viability gate before the full suite on a new runtime.
PhotoPickerHarness/Scripts/test.sh \
  -only-testing:PhotoPickerHarnessUITests/RealPickerTests/testOpenCancel \
  -only-testing:PhotoPickerHarnessUITests/RealPickerTests/testSelectAndImport
```

To run the iOS 18.4 / 26.5 / 27.0 iPhone and iPad matrix in both orientations:

```sh
MATRIX_DIR=/absolute/new/matrix-directory PhotoPickerHarness/Scripts/test-matrix.sh
```

Each of the six devices runs four portrait journeys (`RealPickerTests`), the same four landscape-left journeys (`LandscapePickerTests`), and six importer tests: 14 tests per device, 84 in total. Landscape inherits the portrait journeys so their scenarios stay identical. Every test sets orientation and verifies the actual host-window aspect ratio; the harness declares portrait and both landscape orientations. Each device has its own result bundle and a separate seeded disposable simulator. The matrix continues after a failed device and exits nonzero if any run fails. `test.sh` also runs both orientations by default. Use `-only-testing:PhotoPickerHarnessUITests/LandscapePickerTests` or `-only-testing:PhotoPickerHarnessUITests/RealPickerTests` to isolate one orientation.

Use `xcrun simctl list runtimes` and `xcrun simctl list devicetypes` for identifiers. Keep the deployment target at 16.6 when switching SDKs. `RUN_DIR=/absolute/new/directory` selects the output location; otherwise a new temporary directory is printed. It contains `Tests.xcresult`, `test.log`, Xcode version, and runtime metadata. Do not reuse a result bundle path. Tests run serially, without simulator clones or automatic test retries.

`KEEP_SIM=1` retains the dedicated simulator for inspection. To seed/reset independently:

```sh
python3 PhotoPickerHarness/Scripts/simulator.py create --state /tmp/picker-simulator.json
python3 PhotoPickerHarness/Scripts/simulator.py id --state /tmp/picker-simulator.json
python3 PhotoPickerHarness/Scripts/simulator.py reset --state /tmp/picker-simulator.json
python3 PhotoPickerHarness/Scripts/simulator.py delete --state /tmp/picker-simulator.json
```

Reset deletes and recreates **only the recorded disposable device**, after checking its UUID, exact unique name, and runtime. It never accepts a personal simulator UUID, edits Photos database files, or invokes `PECS MakerTests/SetupPhotos.swift` (which deletes DCIM/PhotoData directly). The library is seeded using `simctl addmedia`. Apple stock photos may coexist; tests use the three fixtures' distinct January 1–3, 2020 EXIF capture dates. System and host language are English (`en`), locale `en_US`. No Apple account or semantic indexing is required. The JPEGs are committed; regenerate with `swift PhotoPickerHarness/Scripts/generate-fixtures.swift PhotoPickerHarness/Fixtures`.

## Automation boundary and maintenance

Include `../TestSupport/SystemPhotoPicker/SystemPhotoPickerDriver.swift` in the production UI-test target as a source reference. It centralizes Apple's labels, photo queries, completion controls, and any accessibility workarounds. Keep host-app identifiers and fixture-date predicates in the caller; the driver accepts an arbitrary photo-label predicate and requires exactly one match. Tests must fail on missing picker controls/content; never substitute supplied images or mark an unsupported runtime as passing.

On a new runtime, first run the two viability tests above. Inspect the result bundle's system hierarchy and screenshots if Apple's labels change. Update the helper using observed accessibility evidence, rerun the gate, then run the full suite. The iOS 26.5 grid exposes `PXGGridLayout-Info` image elements and frames but reports `isHittable == false`; the helper can tap the queried thumbnail's center after scrolling it fully inside the visible grid, between the navigation bar and toolbar. It does not guess fixed screen coordinates. On compact landscape screens it dismisses the optional privacy explainer and uses bounded drags without release momentum. iOS 18.4 exposes Search as a text view with the placeholder “Search your library…”, and iPad can expose Photos as a sidebar cell. Older releases use Add; newer ones use Done. Maintain this compatibility in one place.

On iPadOS 27, Search is a text view inside `photosSearchBar` with a separate placeholder label. Container-sized toolbar elements must not be treated as bottom bars. Avoid indexed enumeration of those changing remote elements; the shared helper uses a stable first match and checks its geometry. Evidence uses full-screen screenshots because app-only screenshots can be cropped after rotation.

The imported thumbnail and its dimensions/color description are derived from the decoded provider image. Tests verify both, along with imported count and ordered content, rather than a presentation flag. The solid fixtures use dimensions plus a dominant-color check on decoded sRGB pixels, allowing JPEG and color-profile rounding. Deterministic provider tests cover failure and cancellation races separately; they do not replace the real-picker XCUITests. See `VALIDATION.md` for measured coverage and remaining limitations.

## Manual checks

For physical-device runs, enable signing (`CODE_SIGNING_ALLOWED=YES`) and select your development team in the harness target. The checked-in configuration disables signing for simulator/CI builds.

- **Search:** on a device or simulator with a suitably indexed library, open Choose Photos, open Search, search for a known subject/date/place, select results, and verify the imported thumbnail and selection order. Check keyboard and cancel/reopen behavior. CI checks the Search control's presence only; it must not wait for semantic indexing or assert search results.
- **iCloud:** on a test device/account with Optimize Storage enabled, choose an image whose original is offloaded. Confirm loading remains visible, successful download renders the right image, and cancel retains the earlier batch. Repeat offline or interrupt connectivity to observe a provider error and then retry online. Do not sign into a personal account in a disposable CI simulator. Simulator-local fixtures do not prove cloud behavior.
- Also check very large/rotated/HEIF/Live Photos, memory pressure, interactive sheet dismissal, VoiceOver, and iPad multitasking/window resizing. The automated matrix covers full-screen iPad portrait and landscape. The harness imports still-image representations, not video or paired Live Photo resources.

## Production follow-up

Use the same shared picker and importer in `selectPhotos` and `selectTopicPhoto`, presenting from the relevant scene/view. Map successful results with `PhotoItem(image: photo.image)`; its `asset` and `assetId` parameters are optional. Decide whether successful imports call `photoBrowserData.add` (append) or `setPhotos` (replace), and keep cancellation from invoking either. Only commit after the entire batch succeeds, or explicitly design and test a partial-success UI.

Retain thin real-picker smoke tests at each production entry point plus one complete pick/import/layout journey. Supply images directly for unrelated layout, title-editing, pagination, and printing tests. Do not make those tests traverse the photo library.

Before removing ZL, account for its camera action, image editing, maximum-selection behavior, and theme/presentation differences. PHPicker does not replace the ZL camera/editor. The harness deliberately has no preselection: provider-only access need not return asset identifiers, and preselected results can omit already-delivered providers. If preselection is required later, retain previous data by identifier, define deselection/reselection and duplicate semantics, and test them explicitly without fetching `PHAsset`. Preserve titles/edits when reconciling existing `PhotoItem`s.
