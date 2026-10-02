# Boardlet system picker migration

The four files under `Shared/SystemPhotoPicker` and reusable test driver under
`TestSupport/SystemPhotoPicker` were imported from task
`01a0c489-94b2-7872-a5e2-45231b2ebf51` (worktree `734a`) on 2026-09-21.
They were uncommitted there and are shared by source reference with the standalone
harness and both production app targets here. Prior harness evidence is historical,
not a passing result for this migration.

Board photos append in tap order, with the picker limit reduced to remaining
capacity (150 total). The underlying replacement path remains atomic. Topic
selection imports one image and saves it using the existing persistence path.
Cancellation and failed imports preserve existing content; failed imports offer
Choose Again, and loading can be cancelled. No PhotoKit authorization or asset
fetch is used by the new integration. Production has used unselected, additive
presentations (`preselectPhotosInPicker = false`) since before this migration;
existing board edits, duplicate photos, and titles remain in the board.

Camera capture is a separate Take Photo action, available when the device has a
camera. It does not save to the user's Photos library. Edit Photo uses the existing
ZL image editor separately on imported board/topic images. ZL is retained solely
for that user-facing editing capability; the custom library picker/presenter and
its global configuration are removed. Automatic whitespace crop remains.

## Full matrix

```sh
python3 Scripts/SystemPhotoPicker/test-matrix.py --output /private/tmp/boardlet-picker-new-run
```

The seven required rows are iPhone 16 / iOS 18.4 portrait, iPhone 17 / iOS 26.5
and 27.0 portrait, iPad A16 / iPadOS 18.4 portrait and landscape, and iPad Pro
11-inch (M4) / iPadOS 27.0 portrait and landscape. The three 18.4 rows replace
the originally requested iOS 16 rows, as agreed on 2026-09-23. Use
`--configuration 18-4-phone-portrait`, `18-4-pad-portrait`, or
`18-4-pad-landscape` for the replacement rows.

Each row creates and seeds its own disposable simulator using the imported ownership
script, runs **all** Boardlet unit/UI test targets, then all importer tests and the
four real-picker harness journeys for that orientation. Use `--configuration
27-pad-landscape` to reproduce a row. No automatic whole-test retries or failure skips are enabled.
The matrix exits nonzero for failures or unavailable configurations. `--keep-sim`
retains only the newly created devices for diagnosis. The original ownership record
is preserved as `simulator-record.json` even after cleanup.

`Boardlet System Picker` uses `SystemPhotoPickerMatrix.xctestplan`, with explicit
Portrait/Landscape configurations. UI tests set and verify device orientation and
window dimensions before/after every journey. Test artifacts include result bundles,
logs, runtime/Xcode/host inventories and JSON summaries with counts. Fruit fixtures
are generated from repository images with unique February 2020 EXIF dates; the
harness's January fixtures are also seeded. Selection uses unique date labels, never
semantic Search results. The shared driver verifies Search controls.

The old UI-test setup that requested Photos authorization and deleted existing
library images has been removed. The historical `SetupPhotos.swift` is not in any
test build phase and is never called. The matrix does not operate on personal
simulators or personal photo libraries.

The UI-test target's three shared identifier source files now resolve from the
actual package checkouts through `BOARDLET_PACKAGE_CHECKOUTS`, defaulting to
`$(BUILD_DIR)/../../SourcePackages/checkouts`. If using
`-clonedSourcePackagesDirPath /path/packages`, pass
`BOARDLET_PACKAGE_CHECKOUTS=/path/packages/checkouts` too.

## Revised older-OS coverage

On 2026-09-23 the requested iOS 16 rows were replaced with iPhone 16 / iOS 18.4
and iPad A16 / iPadOS 18.4 in both orientations. The initial iPadOS 17.0 suggestion
was clarified to 18.4 after checking the installed runtimes. Both selected device
types are supported by the available iOS 18.4 (22E238) runtime.

The historical iOS 16 blocker and its evidence remain in earlier run artifacts;
those rows are no longer required by the revised matrix. Deployment targets stay
at 16.6. Passing the replacement rows does not establish iOS 16 runtime coverage.

## Reusing a final test build

`test-existing-build.py` runs an orientation primer, the **complete** Boardlet unit
and UI suites, and the ten applicable harness tests from `.xctestrun` files created
by `xcodebuild build-for-testing`. It requires a matching harness ownership record,
restarts that disposable device, preserves its fixture library, and refuses to
reuse an output directory. It writes exact commands, host/tool versions, result
bundles, summaries and a live result JSON. A row passes only with all 93 current
Boardlet tests (38 unit, 55 UI), all ten harness tests, and zero failures, skips
or expected failures. Update these expected counts when adding applicable tests.
Individual tests have a 30-minute execution ceiling so a broken automation loop
cannot run indefinitely. iPadOS 27 XCTest can wait 60 seconds before and after
individual keyboard events; the ceiling accommodates those waits without
changing the tests' value, persistence, interaction or snapshot assertions.

```sh
python3 Scripts/SystemPhotoPicker/test-existing-build.py \
  --state /path/to/owned/simulator.json \
  --orientation Portrait \
  --boardlet-test-run '/path/to/Boardlet System Picker_SystemPhotoPickerMatrix_iphonesimulator27.0-arm64.xctestrun' \
  --harness-test-run /path/to/PhotoPickerHarness_iphonesimulator27.0-arm64.xctestrun \
  --output /private/tmp/boardlet-verified-row
```

Build Boardlet with the `Boardlet System Picker` scheme and
`SystemPhotoPickerMatrix` test plan, and the harness with `PhotoPickerHarness`.
Use `-destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
ARCHS=arm64 build-for-testing`, with the same package checkout arguments as above.
Keep both Portrait and Landscape configurations in the Boardlet build; the runner
selects the requested one at execution time. Snapshot references must be reviewed
before rerunning comparisons. Missing-reference recordings are failures.
