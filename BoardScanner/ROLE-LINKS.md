# Motor Plan Home and Keyboard references — 28 October 2026

The “165 unavailable links” warning counted stored references without considering the button’s command. A read-only query of `Motor Plan 66 - Napa 2026 - V1.sps` found:

| Stored absent page ID | Buttons | Actual single command |
| --- | ---: | --- |
| `3acaf8df-164b-4c93-a40e-356c547e1d84` | 164 | Home (`$type: 5`) |
| `9617a618-7107-43e6-a5fb-cbfa077215d3` | 1 | Keyboard (`$type: 17`) |

The file has 307 pages and 700 destination references. Its configured home page is `10a33ecd-5396-48d3-ba59-2f2ac508fe3e` (“Home Page”). The source SHA-256 is `2c7f7098459c7f3836ad3c48d6c28530d6910a25284cad50220afe265fa6021e`. The detailed database audit is retained in `board-scanner-role-links/source-link-audit.json` under the external artifact root.

## Behavior

`SnapCommunicationBehavior` now resolves a supported single Home or Keyboard command before consulting stored page references. Home returns to the current board’s home page; Keyboard opens the native Type a message editor. User-selected actions still take precedence. Labels alone never imply commands. Compound/unknown commands and ordinary destination handling retain their prior behavior.

The full source inventory remains `missingLinkCount`. A separate `unavailableNavigationLinkCount` counts absent destinations only when the button’s current behavior actually uses its page references. The import warning uses the latter and omits zero-count categories. Import details explain retained, unused references; button details distinguish original references from active links. Genuinely unavailable navigation destinations remain reported.

No destination IDs, source command payloads or page content are removed or rewritten. Saved boards receive the corrected interpretation when reopened; they do not need reimporting. This does not reconstruct absent pages or implement all TD Snap command semantics.

## Verification

Artifacts and matching `.log`/`.xcresult` bundles are under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/`. Only the standalone Board Scanner target is affected; production PECS targets and shared Photos sources are unchanged by this fix.

The generated regression includes single Home/Keyboard commands with retained absent IDs, an actual unavailable navigation destination, explicit Open page/No action overrides, compound commands, source-payload preservation and export/reopen. Its UI journey checks Home, typing a message, import details and relaunch. The supplied-file model check asserts 164 Home actions, one Keyboard action, zero unavailable navigation destinations, 165 retained absent references and all 700 references after round-trip.

The supplied-file UI check opens the Keyboard editor, navigates to Food & Drink and returns using the imported Home button. The import warning and details must report no unavailable navigation links. VoiceOver activation verification is deferred at the user’s request and is not part of this run.

### Retained runs

- `Phone-1`: exit 65 before test execution; app and UI-test runner were killed during bootstrap. A fresh task-specific DerivedData directory was used for the next run.
- `Phone-2`: 22 passed, one failed, zero skips or runtime warnings. All five UI journeys and the actual supplied-file import/round-trip passed. The single failure was in the new No action override test: `.none` assigned nil to an optional. Changing it to `CommunicationAction.none` fixes the test setup; the app resolver was unchanged.
- `iPad-1`: one passed, one failed, zero skips or runtime warnings. Actual Motor Plan Home/Keyboard navigation and warning checks passed. The symbol-recovery/relaunch journey failed. This result is retained separately from the rerun using fresh build outputs and explicit window orientation waits.

- `iPad-2`: **7 passed, zero failures/skips/runtime warnings; exit 0**. All five command-behavior tests pass, including the corrected No action setup. Both supplied-file UI journeys pass: Home/Keyboard navigation, zero unavailable navigation links, symbol recovery, save/relaunch and remembered-library reimport. The fresh-build/orientation rerun resolves the earlier recovery test failure without a further app implementation change; its exact cause was not isolated.

All 23 selected iPhone cases have passing coverage across `Phone-2` and the five model reruns in `iPad-2`; this is focused regression evidence, not a new full-suite pass. The final actual-file iPad checks pass together.

### Commands

Run from the repository root; output was redirected to the matching log file under the artifact directory.

#### Phone-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/Phone-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/SnapCommunicationBehaviorTests \
  -only-testing:BoardScannerTests/TDSnapImporterTests \
  -only-testing:BoardScannerTests/CommunicationSessionTests \
  -only-testing:BoardScannerUITests/CommunicationUITests \
  -only-testing:BoardScannerUITests/TDSnapUITests/testImportNavigateAllPagesAndRestore \
  test \
  CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps'
```

#### Phone-2

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/Phone-2.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/SnapCommunicationBehaviorTests \
  -only-testing:BoardScannerTests/TDSnapImporterTests \
  -only-testing:BoardScannerTests/CommunicationSessionTests \
  -only-testing:BoardScannerUITests/CommunicationUITests \
  -only-testing:BoardScannerUITests/TDSnapUITests/testImportNavigateAllPagesAndRestore \
  test \
  CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps'
```

#### iPad-1

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-extreme-layout/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/iPad-1.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/TDSnapUITests/testSuppliedPageSetBrowser \
  -only-testing:BoardScannerUITests/TDSnapUITests/testSuppliedLibraryRecoverySaveAndRestore \
  test \
  CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' \
  'TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3'
```

#### iPad-2

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project BoardScanner/BoardScanner.xcodeproj \
  -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-role-links/iPad-2.xcresult \
  -parallel-testing-enabled NO \
  -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES \
  -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/SnapCommunicationBehaviorTests \
  -only-testing:BoardScannerUITests/TDSnapUITests/testSuppliedPageSetBrowser \
  -only-testing:BoardScannerUITests/TDSnapUITests/testSuppliedLibraryRecoverySaveAndRestore \
  test \
  CODE_SIGNING_ALLOWED=NO \
  'TD_SNAP_FIXTURE=/Volumes/Crucial-SSD-2TB/Downloads/Motor Plan 66 - Napa 2026 - V1.sps' \
  'TD_SYMBOL_LIBRARY=/Users/andy/Library/Mobile Documents/com~apple~CloudDocs/Dynavox Symbols/SymbolsSnapCoreFoundation.db3'
```
