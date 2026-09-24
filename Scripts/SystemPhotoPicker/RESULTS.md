# Migration validation — all seven configurations passed

All seven configurations passed all 62 Boardlet tests and all ten harness tests,
with zero failures, skips or expected failures: 504 tests plus seven orientation
primers. Coverage includes iPhone portrait on iOS 18.4, 26.5 and 27.0, iPad Pro
portrait and landscape on iPadOS 27.0, and iPad A16 portrait and landscape on
iPadOS 18.4. On 2026-09-23 the user replaced
the three blocked iOS 16 rows with iPhone 16 / iOS 18.4 portrait and iPad A16 /
iPadOS 18.4 portrait and landscape. Diagnostic subsets and snapshot
recording runs do not count as full passes.

| Required configuration | Runtime / model | Owned simulator ID | Full-run result and evidence |
|---|---|---|---|
| iPhone iOS 18.4 portrait | iOS 18.4 (22E238), iPhone 16 | E0B23858-D06B-4AD3-890E-535D54D89244 | **PASSED**, 62 + 10; `/private/tmp/boardlet-picker-replacement/verified3/18-4-phone-portrait` |
| iPhone iOS 26 portrait | iOS 26.5 (23F77), iPhone 17 | 3F9E4973-1BB8-4FC8-9A05-B0AEC2AB66CA | **PASSED**, 62 + 10; `/private/tmp/boardlet-picker-verified8/26-phone-portrait` |
| iPhone iOS 27 portrait | iOS 27.0 (24A434), iPhone 17 | B86267D1-0CDB-4862-A7D1-75661C64FA7C | **PASSED**, 62 + 10; `/private/tmp/boardlet-picker-verified9/27-phone-portrait` |
| iPad iPadOS 18.4 portrait | iPadOS 18.4 (22E238), iPad A16 | 7AD773FC-BAAF-452C-B942-F17165D7908D | **PASSED**, 62 + 10; `/private/tmp/boardlet-picker-replacement/verified2/18-4-pad-portrait` |
| iPad iPadOS 18.4 landscape | iPadOS 18.4 (22E238), iPad A16 | 97FEC96E-64DB-4AB4-AA49-FC5773ABD3EB | **PASSED**, 62 + 10; `/private/tmp/boardlet-picker-replacement/verified3/18-4-pad-landscape` |
| iPad iPadOS 27 portrait | iPadOS 27.0 (24A434), iPad Pro 11-inch (M4), 8 GB | DA7CC991-D512-4B13-99ED-38607B5248DE | **PASSED**, 62 + 10; `/private/tmp/boardlet-picker-verified10/27-pad-portrait` |
| iPad iPadOS 27 landscape | iPadOS 27.0 (24A434), iPad Pro 11-inch (M4), 8 GB | 88656738-04FE-4DA6-B0E0-180813A99BD6 | **PASSED**, 62 + 10; `/private/tmp/boardlet-picker-verified11/27-pad-landscape` |

Host: macOS 27.0 (26A428), Xcode 27.0 (27A266a), `/Applications/Xcode.app`.
Deployment targets remain 16.6. The revised matrix removes the unavailable iOS 16
rows; no iOS 16 coverage is claimed. Replacement runtime/device inventory is under
`/private/tmp/boardlet-picker-replacement/runtimes.json`. See
[revised older-OS coverage](README.md#revised-older-os-coverage).

## Reproduction and evidence

Each full-run directory contains `commands.json`, `result.json`, host and Xcode
versions, logs and `.xcresult` bundles. `test-existing-build.py` verifies simulator
ownership, runs an orientation primer, both complete Boardlet test targets
(17 unit tests and 45 UI tests), then all six importer tests and four real-picker
harness journeys for the requested orientation. It refuses filtered Boardlet
builds and requires exactly 62 + 10 passes with zero failures, skips or expected
failures. Thread Sanitizer remains enabled. At most two owned simulators run
concurrently. All seven completed simulators were deleted through the ownership-checked
cleanup script. Their result bundles, installed fingerprints, ownership records
and cleanup records are retained.

The final audit checks all seven rows, complete result bundles, exact test counts,
unfiltered Boardlet commands and the common app executable hash. Its output is
`/private/tmp/boardlet-picker-replacement/final-matrix-audit.json`; the audit script
and log are retained alongside it.

Reusable Boardlet build:
`/private/tmp/boardlet-system-picker-build/Build/Products/Boardlet System Picker_SystemPhotoPickerMatrix_iphonesimulator27.0-arm64.xctestrun`.
Reusable harness build:
`/private/tmp/boardlet-picker-final/HarnessDerived/Build/Products/PhotoPickerHarness_iphonesimulator27.0-arm64.xctestrun`.
Build logs are under `/private/tmp/boardlet-picker-matrix/`.

The final app executable SHA-256 is
`ca401425f4f6b87a6c223157eca24f5b0193bf2b4d23bb6f9545c4c30f1dc363`.
It is identical across all seven passing configurations and the current test-helper build.
Build and installed fingerprints are retained with the evidence. The original iPad harness collectors timed out after 600 seconds
while gathering optional simulator diagnostics; Xcode finalized both test bundles
and exited successfully, with all ten harness tests passing in each configuration.
The test app comes from `Variant-TSan/Debug-iphonesimulator`, not the ordinary Debug directory.

Main `build-for-testing` passed in `stable-color-dismissal-build.log`.
Plus `build-for-testing` passed in `plus-preserve-active-board-build.log`, using
`EXCLUDED_SOURCE_FILE_NAMES=Package.resolved OpenAI-Info.plist` because these
existing machine-local AI resources are absent from the isolated checkout.
No secrets were supplied or project resources removed. This is compile validation,
not a Plus UI-suite pass.

## Production fixes exercised by the matrix

- Both apps and the standalone harness compile the same four shared system-picker
  and importer source files. Real picker tests cover ordered delivery, append,
  cancel/reopen, topic replacement and persistence. Unit tests cover imported
  photos without asset identifiers, preservation of existing edits and order,
  distinct IDs, and the 150-photo limit. Camera capture remains a separate action;
  ZL is retained only for editing an existing image.
- An iOS 27 SIGTRAP originated from rating bindings constructed in the scene's
  deferred content closure on a background render thread. `BoardletRootView`
  constructs them in its main-actor View body. Evidence:
  `/private/tmp/boardlet-picker-final/27-pad-landscape/root-binding-crash.ips`.
- Split-view board selection now updates the selected-board binding and prepares
  board state when selection changes. Initial preparation on appearance is
  restricted to an absent `pageLayoutState`, so dismissing the picker cannot
  switch a compact view away from the board being edited. Four repeated import/
  copy journeys passed across compact and split layouts before the full reruns.

## Test-driver corrections and focused evidence

Assertions, photo counts and snapshot precision remain enforced. No failures
are skipped or automatically retried into a passing full row.

- The picker driver uses observed cell centres, bounded scrolling, seeded photo
  identities and native Selected-trait acknowledgement. A recorded eight-photo
  failure had actually imported seven; acknowledgement fixed the reproduced
  failure. Focused evidence: `SelectionAcknowledgement.xcresult` and
  `BoardletEightPhotos.xcresult` under `/private/tmp/boardlet-picker-selection-lab/`.
- All 63 new formatting references (nine per configuration) were visually
  reviewed. Precision remains 0.90. All seven full runs passed all comparisons.
  Earlier incorrect captures are retained outside the repository under
  `/private/tmp/boardlet-picker-matrix/rejected-snapshots`. Missing-reference
  recording runs are failures, not validation passes.
- Formatting helpers verify switch values, palette opening, applied colours and
  sheet dismissal, and scroll along inert sheet margins. Palette index 30 is
  labelled dark green on these runtimes despite the legacy test name saying blue;
  its index is preserved. iPadOS 27 split-layout captures explicitly reveal and
  assert the board sidebar so they match the three-column references. Both repeated checks
  passed in `verified8/27-pad-landscape/SnapshotColumns.xcresult`.
- The app is terminated before deleting each test repository. Asynchronous screen
  waits remain bounded, and photo counts are checked exactly. The mocked-email
  flow cannot send mail; its thank-you appearance and automatic dismissal are
  still asserted with deadlines appropriate to the observed transition.
- Rename input deletes through the focused field and asserts the exact value before
  Save. Main-menu readiness checks an on-screen frame because an XCTest hittability
  query threw an activation-point exception during a transition. Real taps and
  destination assertions remain.
- Landscape `verified9` finished with 61 Boardlet passes, one title-entry timeout,
  zero skips and all ten harness passes. Keyboard deletion, replacement text and
  Return are now sent as one sequence, with exact-text verification retained.
  Both title entry and rename passed in `verified9/27-pad-landscape/CombinedKeyboardInput.xcresult`.
  Title entry passed under the original 20-minute allowance. In the complete
  landscape `verified11` run it passed in 1110.010 seconds, again under that allowance.
  Subsequent commands
  use a bounded 30-minute infrastructure ceiling to accommodate repeated 60-second
  XCTest keyboard-animation waits; assertion deadlines and expected counts did
  not change. The earlier timeout remains a failure.
- Landscape `verified10` was interrupted after 28 passes and one formatting failure.
  The native colour picker remained in the recorded hierarchy after a transient
  disappearance, leaving formatting Close inaccessible. The helper now requires
  stable picker absence and a hittable host colour control, and verifies the selected
  colour after dismissal. All three consecutive small-margin comparisons passed
  in `verified10/27-pad-landscape/StableColorDismissal.xcresult` before full run
  `verified11` began; that complete row subsequently passed all 62 + 10 tests.
  Diagnostic hierarchy evidence is retained in
  `verified10/27-pad-landscape/small-margin-diagnostics/`.

During `verified10`, host free disk space briefly ran out. Only this task's
regenerable intermediate, module, index and bare dependency-repository caches
were removed. App products, dependency checkouts, results and logs were retained.
No causal connection between disk pressure and the formatting failure is claimed.

Earlier diagnostic bundles are under `/private/tmp/boardlet-picker-matrix/` and
`/private/tmp/boardlet-picker-final/`, with subsequent runs under `verified*`.
Superseded partial runs are marked INTERRUPTED in their result JSON. Historical
results in `PhotoPickerHarness/VALIDATION.md` predate this integration and do not
count toward this matrix.

## iOS 18.4 replacement runs

All three replacement rows passed all 62 + 10 tests: A16 portrait in
`verified2/18-4-pad-portrait`, iPhone portrait in `verified3/18-4-phone-portrait`,
and A16 landscape in `verified3/18-4-pad-landscape`. Their complete bundles,
counts and installed fingerprints passed the final audit.

The app executable did not change during replacement validation. These changes
addressed observed test-driver differences while retaining assertions:

- **Colour controls:** iOS 18 exposes SwiftUI colour controls as `ColorWell`,
  while newer runtimes expose `Button`. Queries now use the stable identifier
  across element types and retain colour-value and dismissal checks. Evidence:
  `phone-color-hierarchy.txt`, `colorwell-query-build.log`.
- **Mock email:** the original tests tapped while the composer was transitioning.
  A dismissal-only wait failed all three checks in `StableEmailDismissal.xcresult`.
  The corrected helper waits for on-screen, stable, hittable mail buttons before
  tapping and uses XCTest's native disappearance wait after cancellation. Three
  consecutive full cancel/reopen/send journeys passed in `StableMailButtons.xcresult`
  (77.741, 72.874 and 71.843 seconds). Cancel, send, confirmation, thank-you and
  automatic-dismissal assertions remain. The first portrait full attempts were
  interrupted after the observed failure (phone 29 passes; iPad 21 passes).
- **Picker viewport:** phone `verified2` finished with 61 Boardlet passes, one
  viewport assertion failure and all ten harness passes. The sixth requested cell
  began at y=153.7 while navigation ended at y=156; its centre was visible, but
  whole-cell containment rejected the two-point overlap. The driver now requires
  the actual centre tap point to be inside the unobscured grid with an eight-point
  margin. Unique photo identity, Selected-trait acknowledgement and exact counts
  remain. All three eight-photo end-to-end checks passed in `VisiblePhotoCenters.xcresult`
  (181.357, 217.579 and 184.832 seconds). Both shared-driver test builds passed.
- **Landscape references:** iPadOS 18 presents the board sidebar as an overlay
  that clips the preview, unlike the iPadOS 27 three-column layout. The snapshot
  helper now normalizes three columns only on iPadOS 27. The two rejected iOS 18
  captures are retained in `rejected-landscape-overlay-references` outside the
  repository. All nine unobscured landscape references were visually reviewed;
  the recording run `UnobscuredReferences.xcresult` has only missing-reference
  failures. Recording runs never count as validation passes.
- **Layout scrolling:** landscape `verified2` was interrupted after 33 passes
  and one orientation assertion failure. The helper scrolled the wrong split-view
  pane, leaving the Landscape button off-screen. It now scrolls the pane owning
  the layout controls, verifies selected orientation and restores visible controls
  before the next choice. Minimum layout counts and thumbnail-shape assertions
  remain. Both focused `ScopedLayoutScrolling.xcresult` iterations passed in
  216.164 and 217.792 seconds.

Replacement evidence is rooted at `/private/tmp/boardlet-picker-replacement/`.
Focused bundles are inside the relevant `18-4-phone-portrait`, `18-4-pad-portrait`
or `18-4-pad-landscape` directory. Build logs and fingerprint JSON files record
each test-helper version. `scoped-layout-scroll-build.log` is the latest successful
Boardlet test build; `visible-photo-center-harness-build.log` is the corresponding
shared-driver harness build. The production app hash remains the one above.
Failed and interrupted attempts are retained and are not included in passing rows.
