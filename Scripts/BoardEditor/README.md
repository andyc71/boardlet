# Page editor verification

The board screen composes cached individual card images in canonical page coordinates (72 points per inch). Export draws those same cards from original images. Page geometry reserves title and attribution space at every output scale. Screen gridlines are vectors, and only title/footer strips are rasterized separately.

The default viewport uses the largest aspect-preserving whole-page fit whenever the actual card geometry remains at least 94 points on its shorter side (approximately four cards across a 402-point iPhone). Title/footer reservations and fixed-aspect layouts participate in this decision. Otherwise, it compares width- and height-filling candidates and chooses the readable candidate with the least scrolling, measured in viewport lengths. If neither reaches the target in a very small window or dense grid, it uses the larger candidate while retaining one locked axis. Explicit zoom remains available from 25% to 200%. Fitted pages preserve 12-point padding on all sides; horizontal overflow removes trailing padding and vertical overflow removes bottom padding. Screen placement does not alter export geometry.

The scroll container retains its identity across zoom and window-size changes. Cached artwork scales immediately during live resizing and pinch gestures; resolution preparation waits for a 150 ms quiet period after a committed size/zoom change. Superseded work exits before rasterization. Changing the page resets its position. Overflow arrows and native scrolling share the same padded content bounds.

`PhotoItem.renderRevision` changes for label, image, and Fitzgerald key edits. Card cache keys include that revision, relevant card formatting, canonical dimensions, and target pixel dimensions. Cache storage is bounded to 32 MiB. Reordering changes placement without invalidating unchanged content; repeated placements have separate view identities and share their content image.

The main-actor rendering model snapshots inputs before suspending, yields between cards, and rejects cancelled or superseded preparations. Views consume prepared results. Metadata and photos save immediately; generated covers are coalesced for 600 ms, keyed only to first-page visual inputs, and flushed when the app backgrounds. A persisted dirty flag recovers interrupted cover generation on the next load.

## Safe test plan

`BoardEditor.xctestplan` selects only `BoardEditorRenderingTests`, `PhotoItemTests`, and `BoardPageEditorUITests`. These use generated images, bundled test images, and isolated repositories. They do not invoke `SetupPhotos` or seed/delete the simulator Photos library.

The focused plan disables Thread Sanitizer because the current iOS 27 UI runner fails at startup with "Interceptors are not working" when sanitizer is enabled. The existing main test plan remains unchanged.

Run from the source checkout, using the existing iPhone 18 Pro:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath .build/board-editor/DerivedData \
  -skipMacroValidation -testPlan BoardEditor -parallel-testing-enabled NO test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' \
  -configuration Debug \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath .build/board-editor/DerivedData \
  -skipMacroValidation -parallel-testing-enabled NO \
  '-only-testing:Easy PECS Plus UI Tests/BoardPageEditorUITests' test
```

Some existing UI-test source references expect `Build/SourcePackages` under DerivedData. If that directory is absent, link it to the resolved package checkout directory:

```sh
ln -s ../SourcePackages .build/board-editor/DerivedData/Build/SourcePackages
```

Both production targets reference `BoardPageRendering.swift`, `BoardPageRenderModel.swift`, and `BoardPageViewport.swift`. Build artifacts, results, logs, screenshots, and generated before/after measurements live under `.build/board-editor/` and are ignored. Temporary `.xctestproducts` created outside the checkout by XcodeBuildMCP were removed after preserving the results and logs to reclaim disk space.

## Performance fixture

The before measurement used the unchanged full-page renderer on ten edits to a generated 100-card board: a 390-pixel visible page plus a 500-pixel cover each time. It averaged 681.7 ms (maximum 724.8 ms), drawing 200 cards per edit. The incremental fixture measures `BoardPageRenderModel.prepare` for the same card count after warming its cache, at the screen's 3× scale. The historical matched run below used the earlier minimum 44-point card target, before the viewport-fill follow-up. It asserts exactly one new card render per label edit and zero for reordering. The matched run averaged **7.93 ms** (maximum **8.14 ms**) per edit; reordering took **4.00 ms** and rendered zero cards. Both fixtures used the same 600-point source image at the simulator’s default 3× scale. Timing records are printed as `BOARD_INCREMENTAL` and `BOARD_REORDER`.

These are simulator rendering/preparation measurements in Debug. Both timing runs used the existing main test plan with the same `-enableThreadSanitizer NO` command override; Xcode still emitted `Variant-TSan` products, so these should not be described as uninstrumented measurements. The UI verification uses the separate focused plan with sanitizer disabled in the plan itself. They do not measure touch-to-display latency, navigation animation, or photo/disk persistence time. Cache eviction, new source images, global formatting, resolution changes, and export can require more work.

The tests also compare screen composition with export at identical scales and compare screen output against reduced 300-dpi output, including portrait/landscape, title/footer, label positions, Fitzgerald borders, dense and fixed-aspect layouts. Raster antialiasing is allowed a small pixel tolerance.

## Initial implementation verification — 4 October 2026

On the existing iPhone 18 Pro simulator, iOS 27.0:

- `PECS Maker` production build: passed. Focused `BoardEditor` suite: **26 passed** (8 renderer/persistence tests, 17 existing PhotoItem tests, 1 editor UI flow).
- `Easy PECS Plus` production build: passed. `BoardPageEditorUITests` flow: **1 passed**.
- Matched before/after performance fixtures: **1 passed per run**. Use `matched-performance.xcresult` for the after timing; earlier correctness runs used a smaller source image or different instrumentation and are not the matched comparison.
- Editor flow covers label editing, selection, drag reordering, pagination, zoom, formatting presentation, rotation, and the PDF print/share sheet. Unit comparisons cover shared screen/export geometry and raster output.
- Portrait and landscape screenshots were visually inspected. These initial screenshots precede the viewport-fill follow-up below.
- `git diff --check`: passed. Build-script version increments were restored to the exact pre-task plist contents.

[Exact executed commands and results](../../.build/board-editor/verification-commands.txt) include the XcodeBuildMCP build-for-testing/test-without-building invocations. Their original product paths are retained in the record even though temporary products were removed after testing. [Standard result bundle](../../.build/board-editor/verified-standard.xcresult), [Plus result bundle](../../.build/board-editor/verified-plus-final.xcresult), and [matched performance result](../../.build/board-editor/matched-performance.xcresult) remain available.

Visual evidence: [portrait](../../.build/board-editor/verified-plus-images/20421D75-C3E5-4F63-8467-65E7E39D8CE2.png), [landscape](../../.build/board-editor/verified-plus-images/9355F4A8-8A7D-4015-BBB3-9DD2DF03227F.png). Screenshots are also attached to the result bundles.

The final Plus build initially exhausted disk space while copying symbol resources. Removing only this task's temporary test products allowed the build and UI test to pass. XcodeBuildMCP's connection closed during that failure, so the final Plus checks used the equivalent `xcodebuild` CLI. Runtime verification was on iOS 27; the deployment target remains iOS 16.6. Export and original-image disk persistence are still synchronous user actions and are outside the incremental-render timing.

## Viewport-fill follow-up — 4 October 2026

`BoardPageViewport` now uses aspect fill within the available space (allowing the existing 12-point page inset). The fitted axis is excluded from the `ScrollView` axes, rather than merely disabling its bounce. An axis change resets scroll offsets. The zoom menu returns to this mode with “Fill available space”. The earlier automatic 44-point minimum no longer enlarges the fitted axis; explicit zoom remains available for dense boards.

Verification on the same iPhone 18 Pro, iOS 27.0:

- Standard production build passed; **26 unit tests** and the existing edit/select/reorder/format/paginate/export UI flow passed.
- The new viewport gesture test passed on **both production variants**, including the Plus build. It checks full height with horizontal overflow, an inert vertical swipe, horizontal reachability, rotation, full usable width, an inert horizontal swipe, and working vertical scrolling.
- The initial new UI assertions were corrected for XCTest’s offscreen hittability error and landscape safe-area accounting. Only that test needed rerunning; production layout code was unchanged after the unit and existing editor flow passes.
- Both variants’ screenshots were visually checked. `git diff --check` passed, and generated build-number changes were restored to this follow-up’s starting plist contents.

[Exact commands and results](../../.build/board-editor/viewport-fit/commands.txt), [standard passing viewport result](../../.build/board-editor/viewport-fit/standard-axis-final.xcresult), and [Plus passing viewport result](../../.build/board-editor/viewport-fit/plus-axis.xcresult).

Screenshots after scrolling: [landscape board filling a portrait viewport](../../.build/board-editor/viewport-fit/plus-proof/7D36710D-AB1E-4D2B-981E-6513D79F49DF.png) and [board filling a landscape viewport](../../.build/board-editor/viewport-fit/plus-proof/3853DEDD-0274-4C61-8EA6-A1F38141ADC8.png).

## Editor controls follow-up — 4 October 2026

The board name is now the editable navigation-bar title. On iPhone in compact vertical size class, page/zoom controls move to a narrow side column and the bottom toolbar is hidden. Layout, formatting, sharing, printing, and the Plus voice-board action remain available from the navigation menu; selection actions also move there. This removes both the separate title row and bottom control rows from the landscape canvas.

Non-interactive, accessibility-labelled arrows appear only at edges that have more scrollable content. Geometry observation updates the arrow state separately from the raster renderer. The fitted axis remains absent from the scroll view's axes. Cards use tap recognition that cancels on movement so a swipe along that fitted axis cannot accidentally open an editor.

Card navigation uses the native zoom transition on iOS 18 and later, with standard navigation on older versions or when Reduce Motion is enabled. Each page slot has a stable transition source, including an empty slot that becomes a saved card. The deployment target remains iOS 16.6; the geometry observer is available from iOS 16.

Every empty slot opens the card editor. Saving content into a later slot preserves its position by persisting skipped slots as transparent placeholder cards. Placeholder metadata is optional when decoding older boards, survives copying and saving, and clears when a title or image is supplied. Cancelling an untouched empty slot does not materialize any cards.

Verification on the existing iPhone 18 Pro, iOS 27.0:

- Both production schemes built successfully. **28 unit tests passed** in the standard scheme (11 renderer/persistence tests and 17 PhotoItem tests).
- **All 3 editor UI tests passed on each production variant**. These cover edit/select/reorder/paginate/zoom/format/export, cancelling and saving a later blank slot in place, directional overflow indicators, fitted-axis gesture locks, rotation, the navigation title, and compact landscape menu access.
- Final portrait and landscape screenshots from both variants were visually inspected. The native zoom was also inspected in the captured test recording. Older iOS runtime and Reduce Motion behavior were not exercised on this simulator.
- The first UI runs exposed identifier propagation, missing arrow updates, and accidental card taps during fitted-axis swipes; these were fixed and the final UI suites passed. The blank-slot fixture and visible-height assertions were also corrected. The standard final run encountered two iOS 27 animation-idle waits after rotation, then completed successfully; the Plus run completed without those waits.
- `git diff --check` passed. Build-generated `CFBundleVersion` increments were restored from this follow-up's starting plist files after confirming all other fields were unchanged.

[Exact executed commands and results](../../.build/board-editor/controls/commands.txt), [standard unit result](../../.build/board-editor/controls/standard.xcresult), [final standard UI result](../../.build/board-editor/controls/standard-final.xcresult), and [Plus result](../../.build/board-editor/controls/plus.xcresult). The standard unit bundle also contains the initial, subsequently fixed UI failures; the final UI bundles are the passing verification.

Visual evidence: [compact landscape controls](../../.build/board-editor/controls/plus-images/F2559074-0279-490C-A51F-A3371C5E524E.png), [horizontal overflow indicator](../../.build/board-editor/controls/plus-images/E2C6A749-83D2-4F45-80D4-272785BA24AE.png), and [vertical overflow indicator](../../.build/board-editor/controls/standard-final-images/152C3929-E290-4941-8EB3-D1887E4CD6F6.png).

## Controls and photo sizing refinements — 5 October 2026

This revision supersedes the landscape overflow-menu arrangement above. Layout, Format, Share, Print, and (in Plus) Use Board are directly available in the right-side column. A single menu combines page selection and zoom. The bottom toolbar uses explicit horizontal icon/text labels, natural button widths, and a shorter localized Format label. Single-page boards omit the page count and previous/next buttons.

Layouts within two points of matching the viewport use aspect fit to avoid a tiny scroll range. Fully fitting boards have no scroll view. Overflowing boards enable only their required axes and use size-dependent bounce behavior on both axes. Canvas identity resets offsets when its dimensions or page change; an old raster with obsolete dimensions is not laid out inside the new viewport while its replacement is being prepared.

Overflow arrows are buttons with 44-point hit areas. Each advances about 80% of the viewport along its axis, preserving the other offset and clamping the destination to the content bounds. The movement respects Reduce Motion.

The card editor's image preserves its aspect ratio in a centered preview whose height is 40% of the available editor height, constrained to 120–280 points. Its width can no longer force a tall photo row on iPad or a wide iPhone. The UI size check includes the surrounding Form row's vertical insets.

Verification:

- Both production targets built successfully with the final source. **29 unit tests passed** (12 renderer/persistence tests and 17 PhotoItem tests).
- **4 UI tests passed on each production variant** on the existing iPhone 18 Pro, iOS 27. They cover the editing/export flow, later blank slots, viewport/arrow interactions, and single-page controls/photo sizing. The Plus run additionally exercised selection of both pages in the final inline menu and vertical arrow taps.
- The single-page/photo-sizing test also passed on the existing iPad Pro 13-inch (M5), iOS 27, in portrait and landscape using the already-built standard app. Both iPad screenshots show all card actions without scrolling. Portrait and landscape phone screenshots were also inspected; the Plus bottom bar displays all five text labels in full.
- The initial photo-size assertion incorrectly excluded Form row insets; the corrected assertion passed. The standard UI flow again encountered simulator animation-idle notification delays after rotation but completed successfully.
- SwiftGen regenerated the English/Spanish Format label. `git diff --check` passed. Build-generated version increments were restored to this refinement's exact starting plist contents.

[Exact commands and results](../../.build/board-editor/refinements/commands.txt), [unit result](../../.build/board-editor/refinements/standard.xcresult), [passing standard UI result](../../.build/board-editor/refinements/standard-final2.xcresult), [Plus result](../../.build/board-editor/refinements/plus.xcresult), [iPad result](../../.build/board-editor/refinements/ipad.xcresult), and [final standard build](../../.build/board-editor/refinements/standard-build.xcresult). The unit bundle also contains the initial UI assertion failures; use the passing UI bundles for final results.

Screenshots: [landscape action column](../../.build/board-editor/refinements/plus-images/598B5C05-0B69-404A-8B4D-7FFAA2CE0A85.png), [labelled bottom toolbar](../../.build/board-editor/refinements/plus-images/FB4AA594-A85E-4276-B5CF-03C06403218F.png), [iPhone photo editor](../../.build/board-editor/refinements/standard-final-images/417E9A93-5BA3-439D-BB0F-8B6F09ADB1A4.png), and [iPad photo editor](../../.build/board-editor/refinements/ipad-images/6E741B26-98AF-48CB-A2AD-E8BDB52942AD.png).

## Whole-page fit for modest overflow — 5 October 2026

The default viewport now fits the entire page when its fit scale is at least 80% of its fill scale. This replaces the two-point-only tolerance above: portrait boards with modest horizontal overflow shrink to fit, while larger aspect-ratio differences retain single-axis scrolling. Explicit zoom still enlarges the chosen default scale.

Both production variants built and passed the two relevant UI checks on the existing iPhone 18 Pro (iOS 27); all 14 rendering tests passed in the standard variant. Tests cover the 20% reduction boundary, portrait and landscape fitting, explicit zoom, and preserved scrolling for larger overflow. The portrait screenshot was inspected and shows all three columns and four rows without a scroll arrow. Build-generated version increments were restored.

[Exact commands and results](../../.build/board-editor/whole-page-fit/commands.txt) · [Whole-page screenshot](../../.build/board-editor/whole-page-fit/images/B6E9C854-78CF-4DBE-A313-04ECE0846A39.png).


## Card-aware adaptive fit — 8 October 2026

The card-size target is now 94 points (approximately four cards across an iPhone). The native scroll container keeps both axes enabled, with its measured content size and size-based bounce locking fitted dimensions. It retains identity during resizing and zoom, so returning to fit clears native overflow offsets without replacing the view. Raster preparation coalesces size/zoom changes for 150 ms while cached artwork scales immediately.

Verification on the existing iPhone 18 Pro / iOS 27: standard target built and passed 21 rendering/layout tests plus 2 UI tests; Plus built and passed the matching scroll/zoom/rotation UI test. Existing iPad A16 visual verification confirmed sidebar resizing and the zoom → scroll → fit sequence. Continuous system-window dragging could not be exercised through available simulator controls; no frame-rate measurement is claimed. Test-generated build-version increments were restored, preserving the pre-existing checkout changes.

[Exact commands and results](../../.build/board-editor/adaptive-fit/verification.txt), [standard results](../../.build/board-editor/adaptive-fit/stable-axes.xcresult), [Plus results](../../.build/board-editor/adaptive-fit/plus-final.xcresult), and [iPad verification notes](../../.build/board-editor/adaptive-fit/ipad/verification-notes.txt).
