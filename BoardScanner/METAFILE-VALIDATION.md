# Native TD Snap artwork — 27 October 2026

## Result

The supplied SQLite `.sps` imports **all 2,764 embedded images**: **2,730 placeable WMFs, eight EMFs, 20 PNGs and six JPEGs**. Unsupported/malformed embedded assets: **zero in this sample**. **419 buttons reference absent assets**, down from 3,742 unavailable-artwork buttons before native rendering. Missing library content is not reconstructed or substituted. The graph retains 307 pages, 428 layouts, 6,687 placements, 5,382 buttons and 700 destinations, including the same 165 references to absent pages.

The simulator import/export/reopen test retains every original asset and its preview byte-for-byte. The complete JSON archive is **71,576,343 bytes**, below the 80,000,000-byte limit. Metafile previews use a longest edge of **224 pixels**; raster previews retain the existing 256-pixel limit. The initial 256-pixel vector experiment left too little archive headroom, so the final output is deliberately smaller. Arbitrary larger page sets can still exceed the existing archive limit and receive the existing export error.

`SnapArtwork` generates one preview per embedded asset, reused by every referencing button. Both `.sps` import and `.boardscan` opening run on `@concurrent` workers. Opening an older version-2 archive regenerates nil metafile previews from its preserved bytes; save again to persist them. Version-1 screenshot archives and the version-2 graph schema remain compatible. `SnapAsset.previewFailure` is an optional diagnostic field, so old archives decode unchanged.

## Format evidence and implemented surface

The record inventory was inspected before implementation. Supplied WMFs use mapping/window records, pen/brush creation and selection/deletion, fill modes, 45,544 poly-polygon records and 28,681 polyline records. One also uses SaveDC/RestoreDC and a 24-bit DIB transfer. All have placeable bounds, with widths 490–1,024 logical units and 288 units per inch. The largest embedded metafile is 51,236 bytes; the largest record stream contains 4,212 records.

The eight EMFs use anisotropic window/viewport mapping, solid/null brushes and extended pens, fill modes, Bézier-to paths, closed figures, poly-polylines/poly-polygons, fill/stroke operations, and integer miter limits. No text records occur in either format in the sample; visible lettering is outlined vector geometry.

The implementation follows Microsoft's primary specifications:

- [MS-WMF specification](https://learn.microsoft.com/openspecs/windows_protocols/ms-wmf/) and [playback device context](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-wmf/6af060b6-07dd-4b1a-ad1d-972a9ce1603b).
- [WMF poly-polygons](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-wmf/941630ee-85e6-4a0f-b02f-1c534b3fa9f8) and [STRETCHDIB layout](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-wmf/7ebae08d-61ee-4d82-9aa5-9217ba2aa8c1).
- [EMF extended pens](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-emf/d7f51e05-4024-497c-ad4a-8aeca9d34256), [Bézier-to records](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-emf/d27cc966-84a4-4715-a6de-45aa6cd03292), [path brackets](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-emf/b930b989-30ec-4954-a889-1dc60ce0b689), and [drawing-state field types](https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-emf/ea08d738-9437-4e80-840a-d2751ea73a39).

Supported WMF operations: placeable headers and checksums; anisotropic mapping; window/viewport origin and extents, including reversed axes; origin offsets; save/restore; solid/null pens and brushes; object selection/deletion/reuse; winding/even-odd fills; move/line, polygon/polyline/poly-polygon, rectangle/ellipse; intersect-rectangle clipping; and full-source, positive-destination, uncompressed 24-bit BI_RGB DIBs using SRCCOPY.

Supported EMF operations: header/EOF/object bounds; anisotropic window/viewport mapping; world transforms and composition; save/restore; supported stock brushes/pens; solid/null pens and extended geometric pens with round/square/flat caps and round/bevel/miter joins; rectangles/ellipses; 16/32-bit polygon, polyline, Bézier and “to” records; path begin/end/close/abort, fill/stroke, and intersect-path/rectangle clipping. Paths retain transformed points, and geometric pen widths are transformed in logical space. Fill-and-stroke closes all open figures.

This is a bounded symbol renderer, not complete Windows GDI emulation. Text/font records, EMF+, comments/escapes, non-anisotropic mapping modes, dashed/pattern/hatch pens or brushes, other bitmap encodings/crops, advanced raster operations, arbitrary region combinations and other unknown records reject the **entire preview**. No commands, fonts, scripts or escape payloads are executed. Partial output is never published after a parse error. Transparent or unpainted results are rejected; white artwork remains white.

## Bounds and tests

Little-endian reads are record-local and check ranges without unaligned memory casts. The parser checks record/file lengths, EOF, counts, coordinate transforms, object indices, brush/pen styles and placeable checksums. Limits per asset: 4 MB input, 50,000 records, 200,000 points, 4,096 object slots/polygons, 64 saved states and clips, bitmap dimensions at most 2,048 each, and output dimensions at most 512 (normal previews use 224). Coordinates, transforms and pen widths have finite magnitude limits. Cancellation is checked before rendering, each record, each bitmap row, every 256 vector points, and each asset. Rendering failures remain nil previews with a diagnostic; cancellation propagates.

Ten deterministic `MetafileRendererTests` use original synthetic geometry, with no extracted personal symbols. They cover pixel colors/transparency, signed origins, reversed axes, saved state, even-odd holes, clipping, world translation, logical current position across viewport changes, Bézier paths, pen caps, object reuse, DIB BGR conversion/bottom-up rows/padding, every truncated prefix of both formats, invalid lengths/counts/handles/checksums/transforms, work limits, unknown records after drawing, empty paths, deterministic cancellation and old-archive regeneration. The deliberately truncated four-byte WMF in the existing SQLite fixture remains unavailable.

`TDSnapImporterTests.testSuppliedPageSet` now explicitly asserts 2,764 previews, all 2,738 metafiles rendered, zero unavailable embedded assets, 419 missing-asset button references, the graph inventory, archive size under 75 MB, and original/preview byte equality after a real filesystem export and reopen.

## Visual inspection and retained evidence

Evidence lives only under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-metafiles/`; the personal input and extracted symbols are not bundled or committed.

- `Inspection/contact-sheet.png`: inspected 49 tiles, including all eight EMFs, the WMF with DIB, the 15 largest metafiles and an evenly spaced selection across the set. The bitmap example appears twice because it is also the largest file.
- Checked recognizable silhouettes, color fills, holes, outlines, multi-part shapes, curves, map details, outlined lettering and orientation. The white navigation EMF (asset 3510) is visible on the checkerboard; its white fill is intentional source content. EMFs include an eye/target, keyboard-like control, looping line symbol, navigation icons and a person. Complex WMFs include world maps, a band, a classroom, currency and animals. The Brazil flag retains its small embedded bitmap detail.
- `Inspection/<asset-id>.png` retains every metafile preview. `Inspection/summary.json` and `inspection.log` report **2,730 WMF + 8 EMF**, no failures and **37,148,162 PNG bytes** in the macOS inspection pass. iOS PNG encoding/container overhead accounts for the actual archive size quoted above.
- `Attachments-2/32419331-F5B7-44F4-9C6D-3D231054F4AC.png`: inspected the actual iPhone simulator home page with the original people/action symbols and the 419-unavailable-images count. Screenshots also remain in the test result bundles.

After the final logical-position correction, the inspector was rerun into `Inspection-final/`; `diff -qr Inspection Inspection-final` returned no differences across all 2,738 PNGs, the contact sheet and summary.

Visual review is representative, not a pixel comparison with Windows GDI or an inspection of every symbol. The same renderer sources are compiled into the iOS app and the optional macOS inspection command; the app performs native rendering on-device and does not depend on preconverted assets.

## Commands and results

Run from `/Users/andy/dev/PECSMaker`. Xcode 27.1; existing iPhone 18 Pro, iOS 27.0. No Photos database changes or disposable devices.

```sh
xcodegen generate --spec BoardScanner/project.yml

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-metafiles/DerivedData \
  build CODE_SIGNING_ALLOWED=NO

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-metafiles/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-metafiles/Tests-3.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES test CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps'

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-metafiles/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-metafiles/Tests-5.xcresult \
  -parallel-testing-enabled NO \
  -only-testing:BoardScannerTests/MetafileRendererTests \
  -only-testing:BoardScannerTests/TDSnapImporterTests \
  test CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps'
```

Standalone initial build: **BUILD SUCCEEDED**, `build.log`. Full suite: **TEST SUCCEEDED**, **30 unit tests + 3 UI tests**, zero failures/skips, `Tests-3.xcresult` / `tests-3.log`. Final brush-length hardening and logical-current-position correction: **TEST SUCCEEDED**, **17 unit tests**, zero failures/skips, `Tests-5.xcresult` / `tests-5.log`. Xcode tests also rebuilt the final app. `git diff --check` passed.

The earlier `ParserTests-1.xcresult` intentionally records the initial failed color-space assertions, corrected by explicit sRGB for both drawing and decoding. The initial sample inspector rejected one EMF because the miter-limit field was mistakenly read as floating-point; it is now read as UINT32 per the specification. `Tests-2.xcresult` passed the prior 27-unit/3-UI suite. `Tests-4.xcresult` passed 16 focused tests after brush-length hardening. A subsequent review corrected the GDI current pen position to remain logical across mapping changes, with an additional pixel regression in the final 17-test run. These earlier runs are not substituted for the final checks.

Optional reproducible visual inspection (runs the production renderer sources, reads SQLite with `SQLITE_OPEN_READONLY`):

```sh
xcrun swiftc BoardScanner/App/Import/Metafile/*.swift \
  BoardScanner/Scripts/inspect-metafiles.swift \
  -o /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-metafiles/inspect-metafiles

/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-metafiles/inspect-metafiles \
  '/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' \
  /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-metafiles/Inspection

xcrun xcresulttool export attachments \
  --path /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-metafiles/Tests-2.xcresult \
  --output-path /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/td-snap-metafiles/Attachments-2 \
  --test-id 'TDSnapUITests/testSuppliedPageSetBrowser()'
```

No verification blocker remains for the tested simulator. Physical hardware, iOS 16.6 runtime, arbitrary third-party metafiles and Windows GDI pixel equivalence remain unverified. Xcode emitted its existing XCTest iOS 17 minimum-version linker warnings, skipped App Intents metadata warning and simulator diagnostic messages; these did not prevent the build/tests. The app deployment target remains iOS 16.6, and no production app target or shared Photos picker source was changed.
