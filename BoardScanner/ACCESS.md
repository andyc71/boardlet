# Access and adaptive communication layouts

Choice Board Scanner retains iOS 16.6 support. Access settings belong to this standalone app and do not change the production PECS Maker variants or the shared Photos picker.

## Operation

Open **Communication settings → Access**:

- **Touch** retains direct selection.
- **Step scanning** uses Start scan, Previous, Next and Select. Space starts a scan or selects the highlighted choice; Command–Left/Right steps. A thick border and arrow mark the focused tile. Full choice text is available through its accessibility label and the Select button.
- **Automatic scanning** advances focus at the chosen interval (0.5–5 seconds). It never selects automatically. Press Space or Select to choose, then explicitly restart for another choice.
- **Repeat delay** (0–2 seconds, default off) ignores a quick repeat of the same board choice. Different choices remain immediately available. Suppressed repeats do not extend the delay.
- **Button size** scales the minimum cell size from 1× to 2× in addition to Dynamic Type. Original positions, hidden gaps and merged spans remain intact; larger boards scroll in both directions. Communication tiles are bounded by the available viewport, so increasing size stops at the space available for a complete choice.

Scanning visits visible choices in row/column order. Empty screenshot cells, hidden choices and imported message-window placeholders are excluded. Repeated placements of the same imported button remain distinct scan targets. Page sets then offer Previous page and Home page. Both board types finish with Stop speaking, Speak message, Undo last word and Clear message before wrapping to the beginning. Commands are named in the Select button rather than presented as extra vocabulary tiles.

Touch remains available in scan modes. A selection pauses scanning. Direct Speak/Undo/Clear also pause it. The main Stop button and Command–period stop both speech and scanning; Command–S speaks the current message. Settings, page browsers, typing, phrase/message editors, document changes, loading, errors and scene inactivity stop scanning. Closing a sheet or returning to the app never resumes it automatically. Shortcuts are suspended behind sheets and editors so typing spaces does not select board choices.

For operating controls outside the board scan (such as phrase management and authoring), use native buttons with the device's Switch Control or Full Keyboard Access. App scanning accepts keyboard events; it does not configure a physical switch, eye-gaze device, or system accessibility service.

## Layout and storage

Compact-height windows place the message beside a horizontal action strip. In compact-height scan mode, page title and Pages share the scan-control row; Previous page/Home remain in the scan cycle. Ordinary saved status is hidden while communicating in compact height, retaining unsaved and editing feedback. Accessibility text sizes use a scrolling action strip in portrait instead of stacking six action rows. Page navigation uses icons with accessible labels in compact/large-text layouts. At accessibility text sizes, the scan button displays the choice name without the redundant “Select:” prefix and uses short visible command labels; its accessibility label retains the full action and its value provides the page title. Status text remains one line, with its full text accessible. The iPad app declares all four orientations and does not require full screen.

`onGeometryChange` observes local width and the height of the flexible scroll viewport. The viewport is independent of its content size; those measurements bound communication tiles without a layout feedback loop. `SourceGridLayout` places imported and screenshot communication tiles at real layout coordinates, preserving sparse cells and spans while allowing ScrollViewReader to reveal the scan target. Visual offsets previously gave scrolling the wrong target frame; the landscape test caught this and the layout was replaced.

`communication.access.v1` stores validated settings in UserDefaults independently of voice settings. Current focus, timers, suspension state and repeat-filter history are not persisted. Test preferences and board libraries use unique UUID suites. Existing board export formats are unchanged.

The import row preserves Photos, Files and On device labels at accessibility text sizes and scrolls horizontally when necessary. Its content determines its height, preventing narrow screens from wrapping the status label into a tall column. See [older-runtime and compact-screen verification](COMPATIBILITY.md).

## Verification — 27 October 2026

Artifacts: `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/`. Shared DerivedData remains under `board-scanner-aac/DerivedData`.

The first focused test run passed five controller tests, the accessibility text UI journey and the keyboard/manual scan journey. Its landscape UI journey failed because the focused last-row tile remained offscreen. That result is not counted as a pass. The first build also caught a SwiftUI modifier placement error, corrected before tests.

Full regression: **TEST SUCCEEDED**, exit 0, **85 passed, 5 optional fixture tests skipped, zero failures**, in `Regression-1.xcresult` / `regression-1.log` (75 unit identifiers with 3 skips; 15 UI identifiers with 2 skips). This precedes the final Command-arrow and compact-header refinements, which receive focused verification below. Coverage includes persisted/clamped settings, independent voice settings, repeat timing, explicit selection and wrapping, hidden/empty exclusion, placement identity, timer cancellation, additive suspension, keyboard input, scan commands, page-link navigation, typing/background suspension, large text and landscape scrolling. Simulator execution does not verify physical-device speech audibility, installed offline voices, physical switch operation, VoiceOver traversal, or iOS 16.6 runtime behavior. The combination of maximum accessibility text, maximum button size and landscape remains a separate layout case to validate.

Commands run from the repository root:

```sh
xcodegen generate --spec BoardScanner/project.yml
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/Tests-2.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerTests/AccessControllerTests \
  -only-testing:BoardScannerUITests/AccessUITests \
  test CODE_SIGNING_ALLOWED=NO
```

The initial focused run used `Tests-1.xcresult`. The initial build used the same project, scheme, destination and DerivedData with `build CODE_SIGNING_ALLOWED=NO` and no test-specific flags, logging to `build-1.log`.

Final full regression command (including build):

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/Regression-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  test CODE_SIGNING_ALLOWED=NO
```

Final iPad access run reuses that build on the existing iPad (A16), iOS 27.0:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/iPad-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/AccessUITests \
  test-without-building CODE_SIGNING_ALLOWED=NO
```

Intermediate `Tests-2` passed all controller tests plus large-text, automatic, landscape and manual/keyboard UI tests. It failed the new page-link scan test: an old grid's disappear callback could stop the newly opened page's scan. Stop ownership now resides in document/page transitions and explicit suspension; the view-scoped timer task still cancels on disappearance. `Tests-3` passed the five controller tests and the page-link UI test, exit 0. Its command is the focused command above with `Tests-3.xcresult` and `-only-testing:BoardScannerUITests/AccessUITests/testScanPageLinkAndReturnWithoutLosingMessage` replacing the UI class selector.

The initial landscape app-region screenshot was cropped incorrectly by XCTest during rotation. Final access captures use `XCUIScreen.main.screenshot()` to retain the complete screen, including a capture before activating the highlighted final-row choice.

The initial iPad access run passed large text, automatic scanning, landscape scrolling and page-link navigation, but plain Right Arrow did not advance focus in the keyboard journey. Stepping now uses **Command–Left/Right**. `iPad-2.xcresult` / `ipad-2.log` passed that keyboard/manual-scan journey with the revised shortcut, exit 0. It used a separate build directory so the ongoing iPhone regression continued with its original products:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=50F3CC1E-D723-4494-B2B3-39CAD32244C0' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/iPad-2.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/AccessUITests/testStepScanningSelectsChoicesAndMessageActionsAndPausesForSheets \
  test CODE_SIGNING_ALLOWED=NO
```

The iPad landscape screenshot was visually reviewed: the final-row Toilet tile is fully visible with a thick border and arrow, the Select button names it, and message/navigation controls remain reachable. Built Info.plist inspection confirms all four iPad orientations. Source/file coverage audit found all 22 planned app, test, project and documentation files present; no global-screen sizing or GeometryReader was introduced.

`Keyboard-Phone.xcresult` / `keyboard-phone.log` also passed the revised keyboard/manual-scan journey on iPhone, exit 0. It uses the iPad-2 command above with the iPhone destination, result path `Keyboard-Phone.xcresult`, and `test-without-building`.

Visual review of the full-screen iPhone landscape capture then exposed a limitation in the original assertion: a hittable portion of the focused tile was visible, but its label was clipped. The compact scan header now combines page title/Pages with the scan controls, freeing a complete row. The landscape test now compares the full tile height with its intersection inside the board viewport. This is a real layout fix, not a relaxed test threshold.

Final compact-header verification command:

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/KeyboardDerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-access/Layout-Phone.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 180 \
  -test-timeouts-enabled YES -collect-test-diagnostics never \
  -only-testing:BoardScannerUITests/AccessUITests/testLandscapeScanScrollsFocusedTileIntoView \
  -only-testing:BoardScannerUITests/AccessUITests/testScanPageLinkAndReturnWithoutLosingMessage \
  test CODE_SIGNING_ALLOWED=NO
```

**Final compact-header results:** `Layout-Phone.xcresult` / `layout-phone.log` passed both landscape and page-navigation journeys, exit 0. The final landscape screenshot was visually reviewed: the full highlighted Toilet tile, its label and the arrow marker are visible; the compact header leaves room for the board.

A read-only review identified that pages with no layout must retain the original navigation row. `compactScan` now requires a layout. The navigation journey now visits an imported no-layout page in landscape, opens Pages, returns Home, and checks that scanning remains paused. `Navigation-Phone-2.xcresult` / `navigation-phone-2.log` passed, exit 0. It used the final compact-header command above with result path `Navigation-Phone-2.xcresult` and only the `testScanPageLinkAndReturnWithoutLosingMessage` selector. `Navigation-Phone` did not execute tests because of fixture-string indentation; that syntax error was corrected before the passing rerun.

Final `git diff --check` and explicit whitespace checks of the untracked standalone sources passed. The build continues to emit the existing test-framework deployment warnings (the installed XCTest frameworks require iOS 17 while the app retains 16.6) and skipped App Intents metadata extraction. Production app files and shared picker implementation were not edited by this milestone.


## Maximum-size layout follow-up

The maximum-text/2× button-size/rotation checks and changes are recorded in [EXTREME-LAYOUT.md](EXTREME-LAYOUT.md). The earlier landscape results above predate this follow-up.

VoiceOver traversal and explicit spoken command names are covered in [VOICEOVER.md](VOICEOVER.md), including the distinction between traversal evidence and unverified VoiceOver activation.
