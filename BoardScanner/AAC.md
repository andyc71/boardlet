# Choice Board Scanner AAC

Goal: build the standalone scanner into a functional AAC app, preserving screenshot and TD Snap imports. **Implementation and authorized verification are complete as of 28 October 2026.** See the [requirement-by-requirement acceptance review](ACCEPTANCE.md) for evidence and limits. The user directed simulator-only testing and deferred VoiceOver activation verification; neither physical-device validation nor deferred activation is claimed as passed.

The latest [inactive-toolbar correction](TOOLBAR-VALIDATION.md) restores the failed menu and vocabulary interactions. The full `Final-Phone-1` regression recorded 108 passes, one Files-presentation wait failure and one known expected contrast finding, with no skips. All six earlier failed journeys have no unexpected failures in that full run. The Files wait was aligned with the other native-picker tests, and the strengthened iPhone follow-up passed with actual browser presentation and complete cancellation verified. App implementation remained unchanged. Historical failures below are retained as dated evidence, not relabelled as clean runs.

## Latest checks — 28 October 2026, 10:43 UTC

VoiceOver activation verification is deferred at the user's request. The isolated English **I** now receives a pronunciation hint while preserving the message text; eight communication tests and three actual speech-engine tests pass. See [the exact pronunciation commands and evidence limits](PRONUNCIATION.md).

The ordinary iPhone refresh, `board-scanner-aac-audit/Phone-1.xcresult`, finished with **101 passes, six failures, no skips and no expected failures** (exit 65). This build predates the pronunciation and folder-tile changes. Failures are the two native-authoring journeys, URL-launch composition, phrase reuse, the communication accessibility audit's setup, and supplied-library recovery. The first five include XCTest reporting a computed hit point of `{-1, -1}`; recovery timed out waiting for the imported page title. These remain unresolved, and are not waived as simulator failures. The accessibility audit did not reach its assertions in this run. Supplied-page browsing and every model test passed. Do not describe this as a clean regression or full AAC completion.

The actual Motor Plan display also exposed cramped folder names: `ViewThatFits` chose a horizontal layout with a fixed-size picture, leaving only 20 points for the label in the baseline fixture. Tiles now keep the label below the picture and shrink the picture first. `Folder-2` passes merged-cell rotation and maximum-text/button-size scanning, but failed an overstrict label-width assertion. Screenshot inspection showed a readable two-line label: XCTest exposes glyph bounds, not allocated layout width. The corrected regression checks at most two lines, a minimum readable glyph width, and folder navigation in portrait and landscape. `Folder-3` passes that check (exit 0); the retained screenshots were inspected. The baseline and intermediate failures remain in the artifact directory.

All artifacts below are under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/`, with matching `.log` files. Exact commands from the repository root:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/Phone-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  '-skip-testing:BoardScannerUITests/VoiceOverUITests' \
  test CODE_SIGNING_ALLOWED=NO \
  TD_SNAP_FIXTURE='/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' \
  TD_SYMBOL_LIBRARY='/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3'

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/iPadDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/Folder-2.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  '-only-testing:BoardScannerUITests/AccessUITests/testNarrowImportedFolderLabelsKeepReadableWidth' \
  '-only-testing:BoardScannerUITests/AccessUITests/testImportedMergedChoicesRemainVisibleAndSelectableAcrossRotation' \
  '-only-testing:BoardScannerUITests/AccessUITests/testMaximumTextAndButtonSizeKeepLandscapeScanChoiceVisible' \
  test CODE_SIGNING_ALLOWED=NO

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/iPadDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/Folder-3.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  '-only-testing:BoardScannerUITests/AccessUITests/testNarrowImportedFolderLabelsKeepReadableWidth' \
  test CODE_SIGNING_ALLOWED=NO
```

## Acceptance and current state

The user-reported Motor Plan warning exposed a command-precedence bug: 164 Home buttons and one Keyboard button were treated as links to absent historical IDs. [The correction](ROLE-LINKS.md) executes those supported role commands and distinguishes unused source references from genuinely unavailable navigation destinations.

Latest verification (28 October 2026): the [final-source ordinary iPhone run and focused corrections](COMPATIBILITY.md#final-source-regression-and-test-input-corrections--28-october-2026) recorded **96 passes, three failures, five optional fixture skips and one expected contrast-audit failure**, with zero runtime warnings. The three failures were test-input/synchronization issues; each passed a focused rerun after correction, with app implementation unchanged. iPad import checks passed 2/2, and the corrected import drag also passed on SE/iOS 18.2. This is not a clean full-suite pass. The earlier full-suite and supplied-file results remain dated evidence below. Landscape VoiceOver touch activation again failed on the current iPad app while portrait passed. The user subsequently directed that activation verification be left for now; it is deferred, not passed, and is no longer the current work item. Physical-device validation remains outside the user's simulator-only scope.

The later [iOS 18.2 compact-screen checks](COMPATIBILITY.md) found and fixed large-text import-row compression and a Files picker that failed to present with two import modifiers on the same view. The final app uses one presenter for board and symbol-library files. Across focused SE runs, all ten selected AAC UI journeys have passing coverage, with an additional passing picker-switching journey; 73 model tests also passed, with three optional fixture skips. The iOS 27 affected-area regression passed 14 cases with the existing expected contrast issue, and native Files backup/restore passed after the presenter change. Exact commands, intermediate failures and source scopes are retained in the compatibility report. These are focused results, not a new full-suite pass or proof of iOS 16.6 runtime behavior.

Subsequent focused authoring checks also passed: native Files artwork selection and relaunch on iPhone, plus Files cancellation and saved/cancelled artwork removal on both iPhone and iPad. Their exact commands, retained screenshots and scope are in [AUTHORING.md](AUTHORING.md). These are additional focused results, not a rerun of the full suite.

After the user chose simulator-only testing, an orientation-checked control reproduced the VoiceOver activation failure in the iPad simulator's Settings app: landscape failed and portrait passed. Direct Device Hub input showed the same pattern for Board Scanner's Create menu. This is evidence that the failure is not unique to Board Scanner, not a passing landscape result. See [ACTIVATION.md](ACTIVATION.md) for the retained evidence and restored simulator settings.

A later matching-text iPhone comparison again passed portrait and failed landscape activation. The available iOS 27.1 Duo passed portrait but did not provide the requested landscape window, so no landscape comparison was established there. Injected VoiceOver keyboard activation failed in both iPhone orientations and is not a substitute for a touch pass. These diagnostic failures and exact commands remain in [ACTIVATION.md](ACTIVATION.md#runtime-and-keyboard-input-comparison--28-october-2026).

The subsequent [Duo display-pose investigation](ACTIVATION.md#duo-display-pose-and-diagnostic-corrections--28-october-2026) corrected two diagnostic assumptions: orientation now uses the actual window instead of the application frame, and focus must reach the exact toolbar label. The final open-Duo wide-window activation failed; closed-Duo portrait passed. The corrected default-iPhone comparison also failed landscape and passed portrait. This establishes a valid iOS 27.1 wide-window attempt, without resolving the input failure or changing app implementation. Simulator VoiceOver settings were restored and the Duo returned to its original closed, shutdown state.

A later [merged-button layout check](EXTREME-LAYOUT.md#imported-merged-button-follow-up--28-october-2026) found and fixed clipping in sparse imported boards at maximum text size. Minimum sizing now accounts for visible button spans, and short tiles bound their pictures, labels and scan markers. The final focused regressions passed 12 iPhone and three iPad journeys with no failures or skips. These results extend imported-layout coverage without claiming every possible span combination or replacing the earlier full-suite result.

[Native Files backup and restore](LIBRARY.md#native-files-backup-and-restore--28-october-2026) is now verified on both existing iOS 27 simulators. The final opt-in journey exports a newly authored two-page board, restores into a separate empty library, and verifies the second page, custom spoken message, picture and persistence after relaunch. Phone-7 and iPad-5 each passed with zero failures or skips. This establishes local Files backup/restore for the native fixture, not cloud sync or system Open In routing.

The subsequent [document URL launch checks](LIBRARY.md#document-url-launch-and-failed-startup-import--28-october-2026) deliver both `.sps` and `.boardscan` files through XCTest's URL-launch API and verify library retention, invalid-file recovery and relaunch. A deterministic model check found and fixed a startup ordering gap: restoration now waits for an incoming import and restores the saved board if that import fails, retaining the import error. This does not establish other apps' share-sheet/default-handler selection.

- Implemented: speech output with voice/speed settings, stop, selection speech toggle, sentence strip with pictures, typed messages, undo/clear, navigation without losing the message, separate communication/edit modes, hidden-card exclusion.
- Implemented: separate screenshot spoken text; imported-button label/message edits and explicit communication actions; original source commands preserved and links retained unless explicitly edited/deleted; save/export round trips.
- Implemented: conservative translation of observed TD Snap schema-4.20 single commands. `3/MessageAction=0` adds a message; `3/MessageAction=1` speaks the button immediately; `4` back, `5` home, `8` speak message, `9` clear, `10` delete last selection, `17` keyboard, `75` stop. Unknown or compound commands remain inspectable. Conditional links continue to offer destinations rather than evaluate expressions. This is not complete TD Snap command emulation.
- Implemented: a persistent multi-board library with autosave, safe switching, revision recovery, rename/duplicate, reversible deletion, and legacy-save migration. See [library verification](LIBRARY.md).
- Implemented: native board/page/button creation, starter words, picture selection, page links, grid/placement editing, home-page management and screenshot-to-native copies. See [authoring behavior and verification](AUTHORING.md).
- Implemented: searchable saved phrases, phrase editing/order/delete/undo, per-selection sentence correction and reordering, and in-memory message recall. See [phrases and message correction](PHRASES.md).
- Implemented: direct/manual/automatic selection modes, visible scan focus with scroll-to-choice, keyboard operation, scan-accessible message/page commands, repeat filtering and button sizing. See [access and layout verification](ACCESS.md). Physical switch/system accessibility traversal remains unverified.
- Implemented: visible speech cancellation in phrase/recall/voice-preview sheets, cancellation when opening other editors, a verified Command–S Speak shortcut, and stronger communication-control contrast. See [speech and accessibility checks](SPEECH-ACCESS.md).
- Implemented: replacement of a speech engine that reports unsuccessful cancellation, so an immediately stopped request does not delay the next message. Three actual-engine completion/replacement/restart checks pass on each existing iPhone/iPad simulator; see the `BoardScannerSpeechEngine` results in [SPEECH-ACCESS.md](SPEECH-ACCESS.md).
- Implemented: viewport-bounded communication tiles, horizontal/vertical scan scrolling, focus retention through rotation, and a speech Stop bar that stacks at large text sizes. See [maximum-size layout verification](EXTREME-LAYOUT.md).
- Implemented and simulator-verified: VoiceOver command names, vocabulary/message traversal, linked-page focus and compact page context. See [VoiceOver verification](VOICEOVER.md).
- Remaining verification: broader imported layouts and window sizes, physical access devices, offline/device speech and interruption behavior. Landscape VoiceOver touch activation is deferred at the user’s request. The [input investigation](ACTIVATION.md) reproduces landscape activation failures on a standard toolbar button without a board grid. Current landscape and large-text test results are tracked in ACCESS.md. Retain the existing iOS 16.6 deployment target; an iOS 27 simulator pass does not establish 16.6 runtime coverage.

## Persistence boundaries

Screenshot version 1 gains optional `message`. Page-set version 2 gains optional `communicationAction` on buttons. Earlier documents decode with default label fallback and imported behavior. Both fields remain inside self-contained `.boardscan` exports; no migration discards source commands, links, geometry or artwork.

Voice preferences live in `communication.settings.v1` in UserDefaults. Tests use a separate preferences suite. Messages and last-message recall are session-only and are cleared when opening another document; navigating within a page set does not clear them. Completed board edits now autosave to the board library; Save remains available as an explicit retry.

## Verification — 27 October 2026

Artifacts: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/`.

Initial speech/composer build succeeded (`build.log`). The first suite’s test cases completed with 39 unit tests (2 optional supplied-file tests skipped) and 6 UI tests (2 optional supplied-file tests skipped), zero failures. Its separate simulator-diagnostics collection delayed finalization by about ten minutes; it ultimately finished with TEST SUCCEEDED and exit 0. The later runs disable verbose diagnostics.

The expanded suite finished with **TEST SUCCEEDED**, exit 0: **46 passed, 4 optional supplied-file tests skipped, zero failures**, in `Tests-2.xcresult` / `test-2.log` (43 unit and 7 UI identifiers). It covers screenshot detection/cropping regressions, document validation, native metafile rendering, generated TD Snap imports/navigation, AAC action translation, message composition, and custom spoken messages saved and reopened. This run exposed synchronous audio-session runtime warnings.

The final refinements use system-managed speech audio activation and an adaptive action grid, fixing the warning and keeping Clear/Type visible. Final focused verification: **TEST SUCCEEDED**, exit 0, **12 passed, zero failures/skips/runtime warnings**, in `Tests-3.xcresult` / `test-3.log` (9 unit + 3 UI). The retained screenshot **AAC screenshot board and message strip** was visually inspected: all five controls are visible, with large targets and both card rows readable in iPhone portrait.

Speech request contents are checked through an injected recording output. UI journeys exercise the actual synthesizer controls. These results do not establish audible output quality on a physical device, voice downloads/offline availability, interruption recovery, or accessibility service behavior.

The system-managed audio-session behavior is documented by Apple’s [`usesApplicationAudioSession`](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/usesapplicationaudiosession) API and confirmed in the installed SDK header (available since iOS 13).

Commands run from the repository root:

```sh
xcodegen generate --spec BoardScanner/project.yml
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  build CODE_SIGNING_ALLOWED=NO
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/Tests-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 90 \
  -test-timeouts-enabled YES test CODE_SIGNING_ALLOWED=NO
```

Source membership is confined to BoardScanner. The production PECS Maker variants and shared Photos picker implementation are unchanged by this work.

Expanded suite command: the full-suite command above with `Tests-2.xcresult` as the result path and `-collect-test-diagnostics never` added. Final focused command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/Tests-3.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 90 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/CommunicationSessionTests \
  -only-testing:BoardScannerTests/SnapCommunicationBehaviorTests \
  -only-testing:BoardScannerUITests/CommunicationUITests \
  test CODE_SIGNING_ALLOWED=NO
```

The final app binary also passed **3/3 communication UI journeys** on the existing **iPad (A16), iOS 27.0** (`iPad-1.xcresult`, `ipad-1.log`, exit 0). Its retained screenshot exposed an inconsistent initial simulator orientation, so the screenshot journey is repeated with an explicit portrait setup. At the time of that run, the app omitted upside-down portrait from its iPad orientation declaration and Xcode reported an orientation-support warning. The subsequent access/layout work adds all four iPad orientations; see ACCESS.md.

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/iPad-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 90 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/CommunicationUITests \
  test-without-building CODE_SIGNING_ALLOWED=NO
```

Explicit-portrait iPad rerun: **TEST SUCCEEDED**, exit 0, **1 UI test passed** in `iPad-3.xcresult` / `ipad-3.log`. The screenshot was visually reviewed and confirms the full board and all controls fit correctly. The previous clipped capture was due to the test’s unnormalized simulator orientation. `iPad-2` did not run: a main-actor annotation on XCTest’s nonisolated setup override failed compilation; orientation setup now occurs inside the existing main-actor test methods.

The successful portrait rerun used the iPad command above with `iPad-3.xcresult`, `test` instead of `test-without-building`, and `-only-testing:BoardScannerUITests/CommunicationUITests/testScreenshotCommunicationAndEditingAreSeparate`. `git diff --check` and whitespace checks of the new communication sources passed. No production targets or shared picker sources were changed.

## Next implementation step

Complete device/accessibility validation and resolve any resulting usability issues. Access controls and adaptive layouts are documented in ACCESS.md; reusable phrases in PHRASES.md; authoring in AUTHORING.md. The AAC goal remains active.

VoiceOver command names, page-focus behavior, targeted simulator results, and the remaining landscape touch-activation limitation are documented in [VOICEOVER.md](VOICEOVER.md).

## Completion audit — 28 October 2026

This audit re-read the current communication, speech, authoring, document, phrase, library and access implementations, the scheme exclusions, and the completed result bundles. It does not declare full AAC completion.

| Requirement | Authoritative evidence | Assessment |
| --- | --- | --- |
| Compose from pictures or typed text, correct/reorder words, undo/clear and recall messages | `CommunicationSession`, message/phrase UI; communication and phrase journeys in `board-scanner-activation/Regression-1.xcresult` | Implemented; simulator journeys pass. Messages remain session-only by design. |
| Speak messages with selectable voice/rate and reachable Stop controls | `SpeechController` uses the system synthesizer; speech, background and large-text Stop journeys; `board-scanner-speech-engine/Phone-2` and `iPad-1` | Controls and request/state behavior verified. Actual-engine restart/replacement checks pass after fixing unsuccessful cancellation. Audible physical output, offline voice availability and accessory/interruption behavior remain unverified. |
| Create and edit boards, pages, buttons, pictures and links | Transactional `PageSetAuthoring`, native authoring journey, `PhotoArtwork-4`, `FilesArtwork-1`, `ArtworkChanges-5`, `ArtworkChanges-iPad-2` | Board creation, linked navigation, local Photos/Files artwork, cancellation and saved removal verified within the documented device scopes. |
| Keep conversation through page navigation; separate editing and communication | `CommunicationSession`, `SnapPageSetView`, screenshot/native communication journeys | Simulator journeys pass. |
| Preserve screenshot and TD Snap import/edit/export behavior | `BoardDocument`, `ScannerModel`, importer/model tests and generated-page-set navigation/restore journey; `board-scanner-final-regression/Supplied-iPad-1` and corrected browser check `Supplied-iPad-3` | Generated fixtures pass. The five supplied-file checks also have passing coverage across the retained iPad runs: full inventory, library/export preservation, artwork recovery and real-page navigation. Imported commands retain the explicitly documented supported subset. |
| Persist multiple boards and recover from damaged/cancelled saves | `BoardLibrary` atomic revision/index writes and fallback reads; library/model tests and switch/rename/duplicate/delete/restore UI journey | Tested recovery and relaunch flows pass. This is not evidence of physical power-loss behavior. |
| Export a portable backup and restore it through Files | `FilesBackupUITests`; `board-scanner-files-backup/Phone-7.xcresult` and `iPad-5.xcresult`; subsequent `OpenDocumentUITests` and startup model regression | Native two-page backup/restore and separate `.sps`/`.boardscan` URL-launch journeys pass on both simulators. Cloud providers and other apps' handoff UI remain outside this evidence. |
| Direct, keyboard and manual/automatic scan access with explicit activation and modal/background suspension | `AccessController`, scan controls and nine access UI journeys in `board-scanner-final-regression/Phone-1` | Simulator journeys pass, including imported merged choices, maximum text/button size and landscape visibility. Physical switch equipment remains unverified. |
| Readable and navigable accessibility presentation | Three functional VoiceOver journeys, large-text/rotation checks, native accessibility audit | Traversal and page focus pass. One narrowly documented expected contrast-audit discrepancy remains. Landscape synthesized touch activation fails in the separate toolbar diagnostic on both simulators. Physical gesture behavior is unresolved. |
| Retain platform/project boundaries | `project.yml` and generated scheme/source membership; simulator and unsigned device builds | iOS 16.6 remains the minimum. Only iOS 18/26/27 simulator runtimes are installed; minimum-version runtime coverage is missing. Production PECS targets and shared picker sources were not changed by this milestone. |

Fresh result-bundle summaries confirmed: `Regression-1` has 93 passes, five skips and one expected failure out of 99 cases, with zero unexpected failures. `Diagnostic-iPad` has one pass and three failures. Each of `PhotoArtwork-4`, `ArtworkChanges-5`, `ArtworkChanges-iPad-2` and `FilesArtwork-1` has one pass with no failures or skips. Commands and detailed scopes remain in [ACTIVATION.md](ACTIVATION.md) and [AUTHORING.md](AUTHORING.md). The later app change only gives the existing artwork-error text an accessibility identifier; the later focused runs build that source. No broad regression rerun is claimed.

At this audit checkpoint, the prepared physical-device check awaited authorization and the goal was marked blocked. The user subsequently answered **“Keep testing on simulators.”** That decision supersedes the pending request: do not sign/install on a physical device or treat approval as still outstanding. Continue the landscape VoiceOver investigation within the simulator boundary. No physical installation or settings change has occurred. Simulator speech state does not establish physical audibility, minimum-version runtime or physical accessory behavior; these remain evidence limits rather than a renewed approval request.

## Regression refresh — 28 October 2026

This refresh builds the current speech-cancellation, startup-recovery and alert-dismissal fixes together. Artifacts are in `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-final-regression/`. The ordinary iPhone run and supplied-file iPad checks use separate build directories and existing iOS 27 simulators. No application code changed during these runs.

`Phone-1` completed with **TEST SUCCEEDED, exit 0: 97 passed, five skipped, one expected contrast-audit failure, zero unexpected failures and zero runtime warnings**, out of 103 cases (76 unit/model and 27 UI cases). This refresh covers all nine access journeys, native authoring, picture-edit save/cancel behavior, screenshot and generated imports, library recovery, message/phrase editing, URL launch, speech controls and all three functional VoiceOver journeys. The five skips are supplied-file checks, covered separately below. Scheme-excluded speech-engine, Files backup/artwork, real-Photos and VoiceOver input diagnostic classes retain their separately documented results; they were not silently counted as passes here. The expected contrast discrepancy again named exactly Edit, Undo, Clear, Type and Phrases.

The retained source manifests cover 127 app/test/project/shared-picker files. The only source change during the run was `UITests/TDSnapUITests.swift`, updating its supplied-browser test, which the ordinary run skipped. Application sources stayed unchanged. Scoped whitespace checks passed. Full AAC completion remains unproven because landscape VoiceOver touch activation is still unresolved; these ordinary passes do not supersede the failing input diagnostics.

The five supplied-file checks were run with the previously supplied 307-page export and its symbol database. In `Supplied-iPad-1`, the three data checks and artwork-recovery/save/relaunch UI journey passed; the page-browser UI journey failed. The source page set preserved 307 pages, 700 links and all 2,764 embedded previews through export/library round trips. Symbol supplementation recovered 147 additional assets, producing 2,911 previews and leaving one button image absent from the supplied sources. SHA-256 verification after the tests matched both input files to their pre-run hashes.

The browser failure occurred after typing in Search and tapping the filtered row. `Supplied-iPad-2` retained the failure even after waiting for sheet dismissal: waiting alone did not fix it. The recorded tap was at (410,394), while the later hierarchy put the filtered row at y=261.5–328.5. The final test submits Search before tapping the result, waits for the sheet to disappear and the actual destination title, and retains a destination screenshot. `Supplied-iPad-3` passed this journey, exit 0, with zero skips/failures/runtime warnings. Its Food & Drink screenshot was inspected. The test also uses a UUID library and stops at the first failed assertion. This is a test-sequence correction, not an app navigation fix; the earlier failed runs remain retained.

Exact ordinary iPhone command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-final-regression/Phone-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
```

Exact supplied-file iPad command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-final-regression/Supplied-iPad-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/LibrarySuppliedTests \
  -only-testing:BoardScannerTests/TDSnapImporterTests/testSuppliedPageSet \
  -only-testing:BoardScannerTests/SnapSymbolLibraryTests/testSuppliedLibraryRecoveryAndExport \
  -only-testing:BoardScannerUITests/TDSnapUITests/testSuppliedPageSetBrowser \
  -only-testing:BoardScannerUITests/TDSnapUITests/testSuppliedLibraryRecoverySaveAndRestore \
  test CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' \
  'TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3'
```

`Supplied-iPad-2` and `Supplied-iPad-3` use this command with their corresponding result names, only `-only-testing:BoardScannerUITests/TDSnapUITests/testSuppliedPageSetBrowser`, and omit `TD_SYMBOL_LIBRARY`. Matching log names use `.log` in the same directory. These focused runs refresh all five supplied-file checks across the retained bundles; they are not described as a single clean five-test run.
