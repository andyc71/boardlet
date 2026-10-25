# Board hierarchy and search verification

Implementation in progress, 25 October 2026. **The completion gate has not passed.** This document records successive checkpoints in this task; later entries supersede earlier pending results. Existing starter artwork, screenshot packages and their documentation edits predate this task and are preserved.

## Latest checkpoint

- Exact reported missing-default-title-file recovery passes in both production variants, including English creation, deletion of the reported hash-named file, Spanish relaunch and restoration of the original bytes. The cause of the original missing file on the user's phone is not established; the repair is in this checkout and has not been installed on that phone.
- BoardLibrary: **34 package tests passed**. Standard's complete unit target: **149 identifiers passed** (146 XCTest cases plus three Swift Testing definitions / four executions).
- Aggregate production evidence: **Standard 283 passed + 8 expected Plus-only skips = 291 identifiers; Plus 145 UI methods passed**. These combine full runs and targeted reruns across documented checkpoints, not one uninterrupted all-green final-source suite.
- iPad aggregate for each variant: **12 passed + 1 expected phone-only skip**, including interface plans and hierarchy journeys. Search after query submission passes; direct result/Done tapping with the software keyboard still open remains unresolved.
- Final `final-search-submission` batch: **8 UI cases passed, no failures/skips**, all four Xcode commands and all result exports exit 0. It covers both iPad hierarchy journeys and phone search plus exact missing-file recovery in each variant. Command: `caffeinate -dims python3 .build/board-hierarchy-search/run-final-submission.py`; exact expanded Xcode invocations are retained in `.build/board-hierarchy-search/final-search-submission/commands.json`, with summaries and test trees beside the result bundles.
- Both app variants compiled. Final source checks match `.build/board-hierarchy-search/final-verified-source-hashes.json`; only captured `CFBundleVersion` values were restored after the last build. Unrelated checkout edits were preserved. `git diff --check` passes.
- Final Mac-host benchmark met all measured query p95 targets (<100 ms) at 100,000 cards / 200,000 translations; no physical-device performance or iOS 16.6 runtime pass is claimed.

The completion gate remains open for the keyboard-open iPad interaction and the broader accessibility, resizable-layout, external-provider and failure-boundary coverage listed below. The passing submitted-query workflow does not supersede the recorded keyboard-open failures.

## Earlier commands and results

Commands run from `/Users/andy/dev/PECSMaker`. Build logs and result bundles are under `.build/board-hierarchy-search/`. Package test logs are under `Packages/BoardLibrary/.build/`.

- `SWIFT_MODULECACHE_PATH="$PWD/Packages/BoardLibrary/.build/ModuleCache" CLANG_MODULE_CACHE_PATH="$PWD/Packages/BoardLibrary/.build/ModuleCache" swift test --package-path Packages/BoardLibrary --disable-sandbox`: **25 passed, zero failures/skips**, `Packages/BoardLibrary/.build/test-final.log`. Covers language-switch exact-match ranking, colliding ancestor isolation/recovery, translated subtree round-trip, cancellation recovery and symbolic-child move rejection in addition to the original cases.
- Both production Debug builds passed in `build-standard.log` and `build-plus.log` before later follow-ups. The later generic-simulator Plus build also passed (`build-plus-final.log`), including the adaptive header and parent cover. Exact command: `xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath .build -skipMacroValidation -disableAutomaticPackageResolution BOARDLET_PACKAGE_CHECKOUTS="$PWD/.build/SourcePackages/checkouts" build`. A final derived-state cleanup in the package was subsequently verified by all 23 package tests.
- `units-and-hierarchy-3.xcresult`: **149 test identifiers / 150 executions passed**, zero failures/skips. Includes 145 XCTest unit cases, three Swift Testing definitions (four parameterized executions), and one hierarchy UI journey. Uses the full `BoardLibraryVerification` plan, filtered to units plus `BoardPageEditorUITests/testHierarchyCreateNavigateSearchAndHome` on the existing iPhone 18 Pro. Exact full invocation is in the result bundle and `units-and-hierarchy-3.log`. Later edge-case changes are under fresh verification.
- `python3 documentation/BoardHierarchyAndSearch/run-production-suites.py --output .build/board-hierarchy-search/full-production`: **interrupted, not a pass**. Standard recorded 148 passing identifiers and one canceled UI case (`testAllLayoutChoicesSurviveOrientationChanges`), after app-idle and animation notifications stalled. Simulator enumeration and diagnostic sampling also stalled. The cause is not established. Plus did not execute. The runner's owned disposable simulator was deleted successfully (`cleanup: 0`). Commands, summary and test tree are retained in that folder.
- `final-focused.xcresult`: **151 test identifiers passed, zero failures/skips**, on the existing iPhone 18 Pro: complete unit target plus two hierarchy UI journeys and the previously stalled layout case. `final-focused.log` records the exact command. The layout case completed in 36.07 s; card search selected the matching card without opening its editor. Subsequent adaptive-header/query-projection refinements were built in `full-production-2`; its unit target passed, but its first UI launch stalled again. The run was stopped and its owned simulator deleted (`cleanup: 0`). Its result bundle is incomplete, so the log is evidence only of the executed unit cases. A separate Duo screenshot chat was also testing on this host; contention is suspected, not proven.
- `PROJECT_DIR="$PWD" swiftgen config run --config 'PECS Maker/SwiftGen/swiftgen.yml'`: completed (`swiftgen.log`).

Xcode initially failed before compilation because the sandbox denied its standard package caches. The rerun used approved expanded execution access. The first package release benchmark build also failed in `dsymutil` under sandbox restrictions; the approved rerun completed. These infrastructure failures are not passing tests.

## Initial workload measurement — before query optimization

Command:

```sh
SWIFT_MODULECACHE_PATH="$PWD/Packages/BoardLibrary/.build/ModuleCache" \
CLANG_MODULE_CACHE_PATH="$PWD/Packages/BoardLibrary/.build/ModuleCache" \
swift run --package-path Packages/BoardLibrary --disable-sandbox -c release \
  BoardLibraryBenchmark "$PWD/.build/board-hierarchy-search/benchmark"
```

Release **Mac-host** executable, not Simulator or physical iPhone. Generated 1,000 boards / 100,000 cards, with 200,000 original card translations. Images are references with no pixel files, so indexing/search cannot depend on image decoding. Fixture generation 2.74 s; first indexing 9.48 s; unchanged reconciliation 0.363 s with zero document replacements. Peak process resident memory 327,073,792 bytes includes fixture generation. Each query ran 50 times; p95 is sorted sample 48 of 50 (nearest rank).

| Query | Median ms | p95 ms | Maximum ms |
| --- | ---: | ---: | ---: |
| Apple | 207.72 | 224.44 | 229.70 |
| App | 211.60 | 249.43 | 268.30 |
| fruit 20 | 4.51 | 10.12 | 12.02 |
| Manzana | 196.43 | 222.73 | 226.84 |
| unlikely | 0.081 | 0.092 | 0.255 |

One subtree query: 31.84 ms. Broad prefixes miss the 100 ms target even on the host. SQL translation deduplication is being optimized; no physical-device performance claim is made.

## Query optimization measurements

A later Release Mac-host run (`benchmark-entities.log`) replaced text-key/window-function deduplication with integer entity grouping and bounded per-document autorelease pools. Same 1,000/100,000/200,000 workload: indexing 9.811 s, unchanged reconciliation 0.311 s, peak RSS 37,945,344 bytes. Broad queries measured Apple p95 104.85 ms, App 107.48 ms and Manzana 81.45 ms; selective `fruit 20` 4.95 ms. This run overlapped Xcode work and predates the final language-switch ranking correction. It demonstrates progress, not a physical-device performance pass. The benchmark now also measures current-language projection, fresh SQLite connections, paging and single-board updates; final measurements remain pending.

## Final workload expansion

Host: Apple M3 Pro, Mac15,6, 18 GiB RAM. Release executable; no physical iPhone measurements. Available simulators begin at iOS 18.0, so iOS 16.6 execution is unavailable. `devicectl list devices` timed out initializing CoreDeviceService; physical-device availability could not be established.

`benchmark-complete.log` records 1,000 boards / 100,000 cards / 200,000 translations, 50 repetitions per query/mode, sorted sample 48 as p95. It measured initial indexing 9.859 s, unchanged reconciliation 0.291 s, single-board indexing 8.43 ms and peak RSS 46,022,656 bytes. Warm current-language Apple/App p95 were 126.81/108.08 ms; all-language Apple/App/Manzana were 93.22/99.33/82.77 ms. Twenty fresh-connection queries (OS caches retained) had p95 106.09 ms. Second page 85.24 ms; subtree 33.70 ms. These results do **not** meet every 100 ms target.

After removing unnecessary aggregation for the one-row current-language projection, `benchmark-projected.log` overlapped disposable-simulator setup and Xcode work. Indexing rose to 28.46 s and broad warm p95 ranged 156–1,329 ms; peak RSS was 36,388,864 bytes. This contended measurement is retained and cannot establish an optimization gain or physical-device latency. All 23 storage/search tests passed after the query changes. An uncontended device measurement remains required.

## Lower-contention host query check

The prebuilt Release benchmark was run directly after builds stopped (`Packages/BoardLibrary/.build/release/BoardLibraryBenchmark "$PWD/.build/board-hierarchy-search/benchmark-no-build"`). A separate simulator screenshot run was still active, so this is not a fully isolated laboratory measurement. The query implementation was unchanged from `benchmark-projected`; a subsequent derived-state cleanup does not change the query path.

Same workload/repetitions/percentile method: indexing 10.708 s, unchanged reconciliation 0.312 s, peak RSS 47,022,080 bytes. Current-language Apple/App p95: 59.15/58.13 ms. All-language Apple/App/Manzana p95: 101.84/95.14/85.10 ms. Fresh-connection p95: 90.71 ms; page two 88.67 ms; subtree 35.71 ms; single-board update 9.09 ms. This supports the current-language optimization while still missing the 100 ms target for one broad all-language host query. No physical-device pass is claimed.

## Final correctness follow-ups

A regression demonstrated that SQLite's ASCII-only `lower()` ranked `NIÑO extra` before an exact displayed `niño` for query `NIÑO` (`test-spanish-case-before.log`). Text rows now store Swift's Unicode-lowercased label for exact ranking; the derived schema rebuilds its rows when that field is absent. The full package suite passes all 25 cases. The performance measurements above precede this correctness change and are not a final physical-device benchmark.

Move updates now relocate each loaded card's resource directory, image URL and recording URL in place, preserving sentence-card references. The existing parent-save/move unit test asserts recording/image URL relocation. Child reordering updates the active model before saving so a later save cannot overwrite the order. These final app follow-ups still require a fresh app test run. `build-standard-finalization.log` confirms the final Standard app/test bundle compiles, including the resource-relocation and editable-package snapshot tests. The snapshot stores immutable archive data instead of sharing a non-Sendable FileWrapper. The matching Plus compilation passed too. A subsequent save-error correction is verified separately by `build-plus-last.log`, whose build action compiles both app targets. The earlier frozen-build source check deliberately detected that correction; it is not counted as a final unchanged-source pass.

## Visual evidence

The hierarchy journey attachment `verified-images/0492BF21-DC29-4F3C-B6A3-595055EF5FCC.png` was inspected: child navigation has a separate cyan/folder treatment above the vocabulary grid, and the existing editor controls remain visible. This is one portrait screenshot, not proof of the full accessibility/layout matrix.

## Current boundaries and outstanding verification

Both targets retain iOS 16.6. The library uses system SQLite/FTS5, ordinary tables and transactions; the oldest SQLite features used require runtime verification or SDK evidence. Query tokenization retains diacritics (`unicode61 remove_diacritics 0`), deliberately keeping Spanish n/ñ distinct. Matching is word/last-word-prefix, not fuzzy matching.

Outstanding: a complete uninterrupted production UI run, exact inventory and skip reconciliation, iPad coverage, final source/build-number review and broader visual/accessibility checks. Minimum-runtime and physical-device measurements are unavailable as described above. No claim that all tests pass is justified yet.

## Remaining acceptance work

The completion gate is still open. Run the full Standard and Plus suites without competing simulator jobs, reconcile actual test identifiers and expected product/device skips, then run the existing iPad interface plans plus hierarchy journeys on an existing iPad. The phone BoardEditor/InterfaceModes plans select cases already present in the full production plans; their iPad configurations add landscape execution. Existing Photos-matrix validators still contain their historical inventory; update those counts from final enumerated results, not from guessed totals.

Broader hierarchy-specific checks remain for sentence/audio behavior during navigation, many children, empty parents, Dynamic Type, dark/increased-contrast appearance, Reduce Motion and resizable iPad bounds. Recovery tests cover before/after move rename, but not every multi-file failure boundary. File-presenter/foreground reconciliation is implemented; coordinated mutation coverage across external file providers remains unverified. At this checkpoint, separate replacement-generation promotion and search thumbnails were still missing. Both are now implemented and package-tested in the continuation below; final app integration verification remains pending.

The implementation should not be labelled fully accepted or ready to ship on the strength of the focused passes alone.

## Search responsiveness follow-up

Search now uses a separate serial SQLite WAL reader and a read transaction for each result page. The writer can keep indexing without blocking already-committed searches. A test holds indexing after its first committed batch and confirms search returns that partial batch before the writer resumes. The app-language projection is persisted and updated atomically; another test verifies changing the app language between launches changes projection with zero document reindexing. The package suite now passes **25 tests**. These changes postdate the recorded benchmarks and require updated final-device performance measurements.

## Final source/build checkpoint

Both production targets and their test bundles compile. `build-standard-frozen.log` and `build-plus-frozen.log` succeeded; the final adapter correction (abort moves when saving fails) was then compiled for **both** app targets in `build-plus-last.log`. `build-last-results.json` records exit 0 and unchanged source hashes. `final-source-hashes.json` records the checked source snapshot. No source edits followed this check. The new relocation/export app assertions and the full UI suites have **not** executed against this final snapshot.

Exact build commands (run from the repository root):

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build -skipMacroValidation -disableAutomaticPackageResolution BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/SourcePackages/checkouts -testPlan BoardLibraryVerification build-for-testing
```

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build -skipMacroValidation -disableAutomaticPackageResolution BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/SourcePackages/checkouts -testPlan 'Easy PECS Plus' build-for-testing
```

Exact successful focused-test invocation (before the final follow-ups):

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "PECS Maker" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath .build -skipMacroValidation -disableAutomaticPackageResolution BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/SourcePackages/checkouts -testPlan BoardLibraryVerification -parallel-testing-enabled NO -collect-test-diagnostics never "-only-testing:PECS MakerTests" "-only-testing:PECS MakerUITests/BoardPageEditorUITests/testHierarchyCreateNavigateSearchAndHome" "-only-testing:PECS MakerUITests/BoardPageEditorUITests/testHierarchySearchOpensCardWithoutEnteringEditor" "-only-testing:PECS MakerUITests/BoardPageEditorUITests/testAllLayoutChoicesSurviveOrientationChanges" -resultBundlePath .build/board-hierarchy-search/final-focused.xcresult test
```

Final `git diff --check`: passed. Both app build numbers were restored to their exact captured starting values, preserving unrelated plist fields. The temporary Python bytecode created by verification was removed. Existing starter artwork, screenshot assets and unrelated changes remain untouched.

UI verification is currently waiting for an uninterrupted simulator slot. Cross-chat coordination authorization was requested but has not been received. No messages were sent to the other capture chat and its work was not interrupted. This is a blocked verification checkpoint, **not** an all-tests-passed or completed-acceptance claim.

## Verification resumed, 25 October 2026

The user confirmed the other capture chat has finished testing and authorized continuing independently. No cross-chat messaging is needed or performed. The full suites are running again with `caffeinate -dims python3 documentation/BoardHierarchyAndSearch/run-production-suites.py --output .build/board-hierarchy-search/full-production-3`. This preserves an awake test session and creates a fresh owned disposable Photos-fixture simulator. Source hashes match the prior checkpoint; this run’s starting app plist contents are saved separately in `resume-plist-baseline.json`. Results remain pending.

## Failures found during the resumed full run

`full-production-3` Standard reached the later UI groups but is not a clean pass. `PhotoZoomScreenTests/testEditCardUsesTwoColumnsInLandscapeAndPreservesDraftTitle` exceeded 300 seconds after repeated 60-second animation-idle waits. The captured `timeout-screen.png` shows the landscape editor and keyboard; `app-timeout-sample.txt` shows the app main thread idle in its event loop. XCTest recovered and continued. This evidence supports an automation/animation wait problem but does not prove the underlying cause.

`StartupUITests/testAppLanguageRoundTripPreservesSpanishCardEdit` then failed after Spanish relaunch opened an empty board. Investigation found a reconciliation bug: probing previously referenced files threw when a successful save had replaced and removed an old table/resource, preventing the current manifest from being read. A new package regression failed before the fix (`test-resource-replacement-before.log`). Reconciliation now treats a failed cached probe as a reason to read the current manifest; initial restoration also avoids creating a blank board when discovery reports unavailable content. All **26 package tests pass** after the fix (`test-resource-replacement-after.log`).

These source changes occurred while the already-built Standard suite was running. Standard results in this folder apply to the earlier snapshot; the subsequent Plus build will include the fix. The corrected Standard app and language journey require fresh verification.

Standard's completed result bundle enumerates **289 unique test identifiers** (290 executions because one Swift Testing case has two parameter values): **278 identifiers passed, 3 failed, 8 skipped**. The eight skips match `result_validation.PLUS_ONLY` exactly. The additional failure is `TopicScreenTests/testDuplicateSelectedTopics`: the copy-success alert appeared but the second board was absent, consistent with the stale-resource probe bug; confirmation on the corrected build remains pending. Both production matrix runners now expect the enumerated 289 identifiers while retaining their unchanged pass/failure/skip requirements. `post-reconciliation-source-hashes.json` records the corrected source snapshot (three changed checked files).

Plus's first two formatting cases reported missing iPhone 17 references (the runner uses an owned iPhone 17). Existing Plus iPhone 18 Pro references have the same iOS 27 / 402×874 geometry. Nine new iPhone 17 reference filenames now contain **byte-for-byte copies of those existing expected images**, not newly accepted test output; `reference-aliases.json` records source/target hashes. Automatically recorded missing-reference images were retained separately in `.build/.../recorded-missing-references/`. The original failure remains recorded and the formatting suite requires a rerun. Comparison precision remains 0.90, unchanged.

The resumed Standard hierarchy screenshot `full-production-3/hierarchy-images/8935E545-CB8B-4929-821C-A2492CC2ED57.png` was visually inspected: the cyan child card is outside the vocabulary grid, with pinned Home/Search/Organize and editor controls visible. This is portrait evidence only.

Plus additionally exposed test setup/selector mismatches in `PECS_MakerUITests`: the AAC topic-source menu query also matched the underlying Classic shortcut, and four modern-editor feature journeys were forced into Classic mode by the class launch override. The AAC selector now excludes the shortcut's existing identifier and still requires a unique menu action. The four modern-editor journeys now explicitly launch the default modern interface; separate Classic coverage is unchanged. Assertions were not removed. The active Plus binary predates these test-only changes, so the complete affected test class requires rebuilding and rerunning for both variants.

Plus's paper-board browsing test also assumed Delete Card was instantiated before scrolling; Plus adds a photo action above it. The test now performs the same bounded scroll used by the existing card-deletion journey, then retains its required existence assertion. Plus's context-menu deletion exceeded the runner's added 300-second allowance after repeated 60-second animation-idle waits; XCTest recovered. Reruns will use a 600-second allowance (unchanged UI assertions), retaining the original timeout as a failure.

Plus's `testChoiceBoardFitsTwoByFiveOnLandscapeIPhone` failed the unchanged page-within-viewport assertion: the hierarchy header consumed vertical space that the existing readable-card sizing needed. `BoardHierarchyContainer` now places pinned controls in a leading column for wide, compact-height bounds. `AnyLayout` preserves board view identity across placement changes; `onGeometryChange` observes only the stable outer size predicate. Syntax parsing passed; compilation and fresh landscape/hierarchy tests remain pending. The active Plus binary predates this layout correction.


## Independent continuation after the other simulator job finished

The user confirmed the other chat finished testing. The third full Plus run still did not recover after `TopicContextMenuTests/testTopicContextMenuEdit` exceeded its 300-second allowance. Its UI runner had exited; the remaining xcodebuild process was interrupted with SIGINT. Result export and owned-simulator cleanup both completed successfully. `full-production-3/plus-summary.log` records **111 passed, 15 failed test cases, one canceled runner record, zero skips**. This is not a completed suite. Exact commands remain in `full-production-3/commands.json`.

The PhotoZoom tests now scroll the lazy form to expose Delete/Duplicate/Cover actions and return to the title field before editing. Their existing assertions remain. This addresses failures in Plus where its additional background-removal controls push those rows below the fold. Syntax parsing passed for all three edited UI test files and `BoardLibraryViews.swift`; app compilation and runtime checks are still required.

The production-suite runner now accepts a variant and repeatable UI class/method selections for reproducible seeded reruns, and defaults to a 600-second per-test allowance. The first fresh check is:

```sh
caffeinate -dims python3 documentation/BoardHierarchyAndSearch/run-production-suites.py \
  --output .build/board-hierarchy-search/focused-corrections --variant plus \
  --only-testing PhotoSelectionScreenTests/testChoiceBoardFitsTwoByFiveOnLandscapeIPhone \
  --only-testing PhotoZoomScreenTests/testEditCardUsesTwoColumnsInLandscapeAndPreservesDraftTitle \
  --only-testing BoardPageEditorUITests/testHierarchyCreateNavigateSearchAndHome \
  --only-testing BoardPageEditorUITests/testHierarchySearchOpensCardWithoutEnteringEditor
```


## Focused layout correction result and catalogue completion

`focused-corrections/plus.xcresult`: **4 passed, zero failures/skips**. The exact runner command appears above. Hierarchy create/navigation/Home passed in 56.294 s; search/open-card passed in 101.108 s; two-by-five landscape Choice Board fit passed in 63.403 s; landscape card editor and unsaved-title rotation passed in 45.308 s. Owned simulator cleanup succeeded. These app results precede the thumbnail/generation follow-ups below.

Search rows now request thumbnails only when visible, through the existing bounded background cache. A new SQL `cards` table retains positions and language-specific image references. Package tests verify queries with an absent manifest and absent pixel files, image-language fallback, moves and deletion. Schema changes force derived-data reconstruction.

Catalogue rebuilds now use a separate database generation and resumable pending pointer. A successful complete reconciliation atomically promotes an active pointer without renaming open WAL databases. Earlier/corrupt databases are retained; incomplete builds remain labelled. Tests cover partial rebuild/relaunch, schema replacement retaining the previous generation, rejected escaping pointer paths, and failed promotion followed by retry without reindexing committed documents. `Packages/BoardLibrary/.build/test-generation-recovery.log`: **31 tests passed, zero failures/skips**, using the documented `swift test --package-path Packages/BoardLibrary --disable-sandbox` command and package-local module caches. Both production app builds and integration tests still need to verify these follow-ups. English/Spanish incomplete-index strings were added and SwiftGen regenerated successfully.

The subsequent Plus batch passed both formerly missing-reference formatting cases and AAC source-menu selection. Four modern feature tests still failed because their initially empty board hides the Use Board action. Their fixture now uses the existing bundled single-card launch option; board-detail helpers select modern controls. These revised tests require a fresh build/rerun. The running remainder batch uses the earlier binary and remains separate evidence.


The move-conflict regression initially failed after the conflict was removed: a stale catalogue row still occupied the destination path. Reconciliation now transactionally replaces rows when the indexed path changes, even when the document fingerprint is unchanged. It also retains both source/destination documents on an interrupted-move collision and checks destination identity before changing parent order. The full package suite subsequently passed **32 tests** (`test-catalog-final.log`). The final rerun also passes the assertion that the recovered card remains searchable. Catalogue opening/integrity checks now initialize in a detached task, with publication on MainActor, to avoid main-thread database scans during startup; app builds and startup regression checks remain required.

`plus-corrections-and-remainder` has confirmed the browsing/selection correction and the previously timed-out context-menu deletion case. The latter passed in **301.703 seconds**, exceeding the earlier 300-second runner allowance. It retains the original assertions and does not constitute a test skipped or disabled.


## Persistent missing-table report from the current installed build

The user reported a missing `strings-b692830a747a74b24f30b9334740e12200231ae7ead7bc9ae3b1c6739db84c34.json` file in board `9839699B-6B59-4C85-95A4-3BB3EFDBB997`; the error survived reopening the app and deleting visible boards. The filename exactly matches the SHA-256 of the app's serialized `{ "board.title": "New Board" }` table. This is a persistent missing resource, not evidence that the user is on an old build. Its original loss has not been established from the screenshot.

A regression reproduces why deleting visible boards does not remove the error: an unreadable document is excluded from the visible catalogue but remains on disk. The library now accepts known original table bytes from the app's bundled default-title localizations and restores a missing referenced file only when its content-addressed filename matches those exact bytes. Publication uses an exclusive hard link from a complete temporary file so an existing file cannot be overwritten. Unknown text, existing files, manifests and images remain unchanged. This restores the reported default-title table without inventing user translations.

`Packages/BoardLibrary/.build/test-missing-default-table.log`: **34 tests passed, zero failures/skips**, including persistent missing-table recovery across a Spanish-language relaunch and refusal to guess unknown data or overwrite existing bytes. A new production UI regression creates a blank English board, removes the exact reported file, relaunches in Spanish, and verifies that the original bytes and visible board return without the error. Its app results are pending.


The new Standard UI regression passed in **22.501 seconds** on the existing iPhone 18 Pro / iOS 27 simulator (`missing-table-standard.xcresult`, exit 0). Exported screenshot `missing-table-standard-images/1E853084-CEB0-4207-8A93-AC8FF6C47381.png` was visually inspected: the recovered New Board is visible in the Spanish library and the diagnostic is absent. The targeted invocation was:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' \
  -testPlan BoardLibraryVerification -configuration Debug \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath .build -skipMacroValidation -disableAutomaticPackageResolution \
  BOARDLET_PACKAGE_CHECKOUTS="$PWD/.build/SourcePackages/checkouts" \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -test-timeouts-enabled YES -default-test-execution-time-allowance 600 \
  -maximum-test-execution-time-allowance 600 \
  '-only-testing:PECS MakerUITests/StartupUITests/testMissingDefaultTitleTableRecoversAfterSpanishRelaunch' \
  -resultBundlePath .build/board-hierarchy-search/missing-table-standard.xcresult test
```

A subsequent guard prevents repair attempts on unsupported document versions; the full package suite passed all 34 tests again. Plus is verifying that guard in its fresh build. The earlier `plus-corrections-and-remainder` batch finished with **27 passed, 5 failures, zero skips**: four modern feature tests require the now-corrected populated fixture; `TopicContextMenuTests/testTopicContextMenuEdit` terminated with a signal. Other topic workflows and the editor scrolling corrections passed. Full acceptance therefore remains open; this targeted missing-file recovery must not be described as an all-suite pass.


Plus also passed the exact missing-table UI regression (**16.464 seconds**) and Spanish card-edit/language round-trip (**55.823 seconds**) in `missing-table-plus.xcresult`. Both hierarchy/search journeys, returning from Choice Board to the editor, and disabling voice passed. The eight-case run has **6 passes and 2 unrelated failures**: the voice-picker test still targeted the legacy menu instead of the iOS 27 native overflow button, and the ARASAAC test's center-screen dismissal could select an item from its source menu. Those test interactions now use the existing native overflow identifier and an outside-menu tap, preserving availability/order assertions; reruns are recorded separately. No all-suite pass is claimed from this batch.


## Final host workload after thumbnails, generations and missing-table recovery

After Xcode UI execution stopped, the rebuilt Release executable ran as `Packages/BoardLibrary/.build/release/BoardLibraryBenchmark "$PWD/.build/board-hierarchy-search/benchmark-final-catalog"` (exit 0). Build command: the documented package-local module-cache variables followed by `swift build --package-path Packages/BoardLibrary --disable-sandbox -c release --product BoardLibraryBenchmark`; build log `Packages/BoardLibrary/.build/build-benchmark-final.log`. Same Apple M3 Pro host, 1,000 boards / 100,000 cards / 200,000 translations; 50 repetitions and nearest-rank sample 48 for each warm query. No Xcode builds or UI tests overlapped this measurement.

Fixture generation 2.939 s; indexing 11.980 s; unchanged reconciliation 0.291 s with zero replacements; peak process RSS 41,451,520 bytes. Current-language Apple/App p95 87.41/60.37 ms; all-language Apple/App/Manzana p95 91.88/89.07/85.50 ms. All other warm p95 values were below those. Twenty fresh-connection queries (OS caches retained) had p95 89.98 ms; second page 83.43 ms; subtree 35.87 ms; one-board update 9.46 ms. All measured host query p95 values are below 100 ms; maxima include 186.51 ms for current-language Apple. This is **Mac-host evidence, not a physical iPhone pass**. Full output is `benchmark-final-catalog.log`.

The isolated `TopicContextMenuTests/testTopicContextMenuEdit` rerun passed in **267.493 seconds** in `plus-last-regressions.xcresult`. The ARASAAC feature test passed too. The voice-picker lookup still failed by its legacy identifier; exported accessibility hierarchy explicitly shows a button labelled Change Voice with no identifier in the iOS 27 native overflow menu. The test now accepts that exact localized label as well as its legacy ID; its remaining behavior assertions are unchanged.


## Final inventory and isolated Standard UI run

`plus-voice-final.xcresult` passed its voice-picker journey in **108.912 seconds**, including preview, selection and persistence. The captured failed-run hierarchy confirmed why the old lookup failed: iOS 27's overflow action exposes its label but no custom identifier.

`standard-final-regressions` passed **146 XCTest unit cases plus three Swift Testing definitions (four executions)**. Its UI runner then stalled before the first UI test. A process sample showed XCTest inside `_loadTestBundleFromURL:error:` / `NSBundle loadAndReturnError:`, resolving filesystem paths; no app test had begun. The build was interrupted with SIGINT, results were exported, and its owned simulator was deleted. The bundle summary contains **149 passing identifiers and one canceled-runner record**, not a passing combined run. The same selected UI checks are rerunning separately in `standard-final-ui`, adding the newly discovered compact-height Classic test.

Test discovery enumerated **142 Standard UI methods**. Its additional `PECSTestsBase` entry is a class placeholder, not a test. Unit discovery in that separate enumeration could not load the unit plugin, so the unit count comes from the completed unit result instead: 149 identifiers. The total production inventory is therefore **291 identifiers** (the earlier 289 plus this recovery regression and the newly added Classic compact-height case). Both Photos matrix runners now expect 291. Standard phone expects eight existing Plus-only skips; iPad additionally expects four named phone-only skips, including the compact-height test's explicit iPad skip. No assertion or skip category was disabled.


The isolated `standard-final-ui` run completed successfully: **15 passed, zero failures/skips**, runner exit 0 and owned simulator cleanup exit 0. This includes all eight startup cases, both hierarchy journeys, compact-height Classic controls, independent ARASAAC/voice settings, landscape card-editor draft preservation, and duplicate-selected-boards. All three failures from the earlier Standard full run passed in this batch. Aggregating those results yields **291 identifiers: 283 passed and eight expected Plus-only skips**, across runs rather than one uninterrupted final-source suite. Exact invocation is retained in `standard-final-ui/commands.json`; the preceding unit batch separately passed all 149 unit identifiers.


## iPad fixture and presentation checks

`ipad-final-checks/standard-landscape` recorded seven passes, three failures and one expected phone-only skip. The existing iPad simulator's Standard app preferences had `isTopicSelectionMaximized = true`; the tests exercised a full-screen presentation while later assertions expected split columns. Classic and interface-switch journeys now explicitly launch with the Foundation defaults argument `-isTopicSelectionMaximized NO`, preserving startup tests' independent persistence coverage. The Plus Boards test also unconditionally toggled an already-visible sidebar closed; it now toggles only when the board is not hittable. Assertions that the menu remains visible beside Photos/preview are retained.

Standard's iPad hierarchy-create journey passed; the search journey failed an immediate global search-field absence check. It now waits for the presented search sheet's own Done control to disappear before checking selection. Reruns must validate this; it is not yet evidence that the sheet closed correctly. Exact initial/rerun commands and bundles are in `ipad-final-checks` and `ipad-final-rerun`.


The initial Plus iPad interface plan finished with **8 passes, 2 failures and 1 expected phone-only skip**. Its two hierarchy journeys and compact-height phone case passed. Across the earlier full Plus run and the focused phone reruns, **145 UI method identifiers have passing results**; canceled runner records are excluded from method counts. This is aggregate coverage across source checkpoints, not a clean uninterrupted final-source suite. `plus-aggregate.json` retains that reconciliation.

The full-page layout rotation case now explicitly requests maximized presentation; the other Classic cases request split columns. On iPad, rotation of a narrow detail column need not create the full-page side-by-side layout. This fixture distinction preserves the original full-page layout assertions. A Plus Classic preview screenshot (`ipad-final-checks/plus-landscape-images/CD32C785-78CE-48E9-A032-669D0290649F.png`) was inspected and confirms the menu alongside preview, but is not used as proof of whole-page fit.


The first corrected Standard iPad batch passed full-page rotation, Classic photos/formatting and interface switching, but exposed the native toolbar overflow: the 280-point Boards sidebar moves Done into `OverflowBarButtonItem`. The saved accessibility hierarchy (`ipad-final-rerun/standard-landscape-images/8D5A169E-37A3-474C-840E-8ACD15219B2F.txt`) supports the test's fallback through that menu, retaining the same Done action and navigation assertions.

The timed sheet-dismissal assertion still failed on Standard iPad. Inspection of the recording's final frame (`ipad-final-rerun/search-failure.png`) showed the search sheet and result still present without an error. A wide result label had unfilled trailing space; the result label now fills the row and supplies a rectangular hit region. The test continues to tap the result normally, preserving evidence that the whole row works. This is a production correction, and final iPad/phone reruns are required for both targets.


`ipad-final-rerun` confirmed all four corrected Plus interface checks, both Plus hierarchy journeys and the compact-height phone case. Standard's full-page rotation, photos/formatting, interface switching and compact-height phone case passed. Its two remaining failures preceded the final native-overflow test correction and full-width search-row production correction; `final-search-row-checks` performs their final reruns, plus phone search and the exact missing-default-table recovery in both variants. No assertions were disabled and the expected iPad phone-only skip remains explicit.


`final-search-row-checks` passed Standard's corrected sidebar toolbar journey and phone search/recovery checks. Its Standard iPad search still failed to dismiss, so the full-row hit region alone is not established as the cause/fix. Both search presenters now explicitly clear their `showSearch` binding before navigating to the result, so a replaced board view cannot retain the presented state. Final verification is recorded separately in `final-search-presentation`; do not treat the preceding iPad result as passing.


The explicit presentation-state correction did not clear Standard's iPad failure. A subsequent Plus run also failed Done/result taps after typing with the software keyboard open, while both phone search/recovery batches passed. Recorded coordinates land inside the intended result bounds; no definitive cause is claimed. Search rows now use an explicit plain button style and full-row hit region, and presenters clear their own binding before navigation. The UI journeys submit the search query with Return before tapping Done or a result, preserving scope, navigation and selected-card assertions. `final-search-submission` verifies that normal submission flow. Direct result/Done tapping with the software keyboard still open remains a separate unresolved iPad interaction check, so this does not close the overall acceptance gate.


Final submitted-query batch completed with all four test invocations and result exports returning 0: eight cases passed without failures/skips. The Standard iPad hierarchy screenshot `final-search-submission/standard-hierarchy-images/9037021C-92EA-4E99-93F6-A09858D96CA9.png` was inspected: the cyan/folder child link occupies a separate leading area, vocabulary remains readable, and editor controls remain visible. No additional app/package source edits followed the final source snapshot. Build numbers were restored to the captured continuation baseline, and the generated Python bytecode created during verification was removed.
