# Optional Classic interface

Boardlet uses **Classic** and the **Paper** layout destination, including on existing installations and after welcome. Configuration → Interface is hidden in Boardlet. The Paper Size section header shows a plain **Paper** label in Boardlet and a **Paper/Screen** picker in Boardlet+; no locked controls or upgrade messages are displayed. Boardlet+ retains interface switching and defaults to **New (default)** with **Screen** on first launch. The app-wide `pecsInterfaceStyle` preference is independent of Choice Board mode and board files. Changing it saves the current board and clears the old interface's navigation destinations. The setting is also reachable from the new editor's menu.

Classic restores the pre-editor workflow from `d0dde9e`: Main Menu, shared PhotoListView2 editor, paged Preview and Print, and the persistent iPad menu/detail columns. Both production targets currently define `AppHasTopics`, so both show Topics/Menu/Detail on wide iPad windows. Layout and Format use the current shared screens. Photo import, card editing, data, persistence, and rendering/export remain shared.

Classic shares the board hierarchy/search wrapper and lazy library catalogue with the modern editor. Its Main Menu hides Home, Search and Organize, without reserving space for those controls; parent and child board links remain available. Choice Board and the modern editor retain the library controls. Changing parent/child boards preserves the interface choice and communication sentence. Hierarchy links remain outside Classic's printable vocabulary pages. See [board hierarchy and search](../../BoardHierarchyAndSearch/README.md) for storage and management operations.

The non-split Main Menu places its photo card on the left and Layout, Titles, and Preview/Print on the right in compact height. Regular-height menus stay stacked, and split-view menus retain their existing arrangement. Tapping a thumbnail opens that photo directly in the shared editor; closing it returns to Main Menu. Change Selections opens `PhotoListView2`, as does Photos in the split view. In Classic, the shared editor hides Layout, formatting, Share and Print action buttons and the Titles menu action in both orientations. Selection actions and the Plus Use Board action remain available. Layout, Titles and Preview/Print remain accessible from Main Menu.

The large action cards and Photos section use a faint 1-point VeryBrightBlue outline at 25% opacity. Their 46-point icon backgrounds use Glacier Blue (`#E3F2FD`) and a 12-point continuous corner radius to visually match the proportions of the large cards. The Classic menu uses `mfPaleBlue` in light mode and retains its existing dark-blue background in dark mode. The shared `mfPaleBlue` source is now Ice Mist (`#F5F7FA`), so all its consumers inherit that colour. Glacier Blue and Ice Mist also remain separately named colours in SharedSwiftUI.

The card surfaces share `Theme.boardCardCornerRadius` (16 points); inset icons and photo thumbnails share `Theme.boardContentCornerRadius` (12 points). `BoardPhotoCard` handles empty/populated state, with populated content and thumbnail buttons in separate views.

The Inspire Me menu action is available only in Boardlet+, in both Classic and the modern editor. Regular Boardlet omits it entirely. The modern editor’s Board language menu is also Plus-only.

## Print preview layout

Classic Preview and Print fits the whole printable page into the remaining safe area. Compact-height windows horizontally center the page and a 192-point action rail together with a 24-point gap. The compact action rail aligns to the bottom of the preview viewport. Format and save actions share a neutral grouped surface, above a prominent Print button. Regular-height windows use a short row of labelled icons below the page, with Print beneath it. Accessibility text sizes switch the secondary controls to rows; actions can scroll when their content exceeds the available height. Plus retains Save PDF, and both variants retain formatting, saving to Photos, and single-photo repeat.

`ClassicCollageView` measures an independent viewport with `onGeometryChange`, then aspect-fits a resizable page inside its overlay. The fitted page never sets the viewport's maximum height, so returning from landscape restores portrait size. The raster is rendered at the environment display scale, keeping artwork sharp at its fitted size. The pager retains its selected index across layout changes. Single pages hide the page dots; multiple pages reserve a strip below the artwork for them. Export rendering is unchanged.

## Ownership and removal

- `PECS Maker/Views/Classic/` contains every Classic-only view; each type is prefixed `Classic`.
- The photo editor floating bar lives in `Components/PhotoBottomActionBar.swift`; retain it if Classic is removed.
- `PECS MakerUITests/Classic/` contains Classic-only UI journeys.
- `InterfaceStyleUITests` tests switching/default/persistence and can be removed with the preference.
- Integration points are `ContentView`, `MainMenuViewOrChoiceBoardView`, `NavigationModel`, and the Configuration action in `TopicSelectionView`. Search for `InterfaceStyle` to find them.
- To retire Classic: remove its folders and target memberships; remove `InterfaceStyle`, `InterfaceStyleSection`, their localization keys, and the debug `PECS_TEST_INTERFACE` initialization; simplify the integration points to the modern branch. Keep the shared Layout/Format screens, export renderer, `MainMenuAction`, voice helpers, and editor tests.
- `Views/Pages/MainMenuView.swift` now contains shared navigation/voice helpers, not the Classic menu view.

## Verification

`InterfaceModes.xctestplan` selects shared renderer and photo model unit tests, modern editor UI tests, Classic UI tests, and switching tests. `InterfaceModesPlus.xctestplan` selects the same UI journeys for Plus. Neither invokes the historical destructive `SetupPhotos` suite. Tests use bundled generated board fixtures and per-test repository directories; the simulator Photos library is untouched.

Run in this checkout with the existing iPhone 18 Pro:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation \
  -testPlan InterfaceModes -parallel-testing-enabled NO test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation \
  -testPlan InterfaceModesPlus -parallel-testing-enabled NO test
```

For the wide iPad path, use `-testPlan InterfaceModesIPad` with `PECS Maker`, or `-testPlan InterfaceModesPlusIPad` with `Easy PECS Plus`, and an existing iPad destination. These plans set `BOARDLET_TEST_ORIENTATION=landscape` in the test runner. Test reports, screenshots, command records, and build logs belong in ignored `.build/classic-interface/`.

[Historical pre-Classic checkpoint](CHECKPOINT.md) records rollback references only; it is not the current dependency inventory or test evidence.


### Compact-height menu verification (25 October 2026)

The focused UI test rotates from portrait to landscape, checks photos are left of the action buttons, opens a thumbnail directly in the editor, closes back to Main Menu, and checks the portrait stack returns. Run the shared test against each production app with its own UI test target:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation \
  -testPlan InterfaceModes -parallel-testing-enabled NO \
  '-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testClassicCompactHeightMenuAndDirectPhotoEditing' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation \
  -testPlan InterfaceModesPlus -parallel-testing-enabled NO \
  '-only-testing:Easy PECS Plus UI Tests/ClassicInterfaceUITests/testClassicCompactHeightMenuAndDirectPhotoEditing' test
```

Both commands passed on 25 October 2026 on the existing iPhone 18 Pro (iOS 27.0): one focused UI test per variant, zero failures. Logs are in ignored `.build/classic-interface/compact-menu-standard.log` and `compact-menu-plus.log`. This run did not exercise the iPad split-view path or the full interface suite.


### Main Menu library controls verification (25 October 2026)

The existing `testClassicBoardsToolbarAndNavigation` journey now asserts that Home, Search and Organize are absent from the Classic Main Menu. Both production variants compiled and passed this focused test on the existing iPhone 18 Pro (iOS 27.0), one test each with zero failures. The first Standard test launch stalled after compilation; its test-without-building rerun passed. This run does not cover iPad or child-board navigation.

Exact commands (run from the repository root):

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "PECS Maker" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO "-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testClassicBoardsToolbarAndNavigation" test

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "PECS Maker" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO "-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testClassicBoardsToolbarAndNavigation" test-without-building

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "Easy PECS Plus" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModesPlus -parallel-testing-enabled NO "-only-testing:Easy PECS Plus UI Tests/ClassicInterfaceUITests/testClassicBoardsToolbarAndNavigation" test

```

Logs are in ignored `.build/classic-interface/menu-controls-standard.log`, `menu-controls-standard-rerun.log` and `menu-controls-plus.log`.

### Card outline verification (25 October 2026)

Both production variants compiled with the 1-point, 25%-opacity VeryBrightBlue outlines. The focused compact-height menu test passed for Standard and passed on a Plus rerun. The first Plus run was interrupted by foregrounding Standard to capture the requested screenshot, causing its portrait-layout assertion to time out.

Exact commands, from the repository root:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO '-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testClassicCompactHeightMenuAndDirectPhotoEditing' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModesPlus -parallel-testing-enabled NO '-only-testing:Easy PECS Plus UI Tests/ClassicInterfaceUITests/testClassicCompactHeightMenuAndDirectPhotoEditing' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModesPlus -parallel-testing-enabled NO '-only-testing:Easy PECS Plus UI Tests/ClassicInterfaceUITests/testClassicCompactHeightMenuAndDirectPhotoEditing' test-without-building
```

Logs and the screenshot are in ignored `.build/classic-interface/outline-standard.log`, `outline-plus.log`, `outline-plus-rerun.log`, and `outline.png`.

The subsequent icon-corner adjustment passed the same Standard and Plus `test` commands above on 25 October 2026, one focused test per variant. Logs: `.build/classic-interface/icon-corners-standard.log` and `icon-corners-plus.log`.

### Shared pale-blue theme update (25 October 2026)

The shared `MyFamilyColorStrings.paleBlue` source in `../SharedSwiftUI` is now `#E3F2FD`, propagating to SwiftUI and UIKit theme consumers, including icon tiles and pale page backgrounds. Change Selections uses a 0.5-point outline through the shared CapsuleButton border-width parameter; other buttons retain its 1-point default. Both builds below succeeded. No tests were run, as requested. Screenshot: `.build/classic-interface/tile-colour.png`.

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation build
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation build
```

### Glacier Blue and Ice Mist (25 October 2026)

Supersedes the shared pale-blue replacement above: restored `MyFamilyColorStrings.paleBlue` to `#E7F8FF` and added `glacierBlue`/`iceMist` with UIColor and SwiftUI Color accessors in `../SharedSwiftUI`. Only the Classic menu background and shared BoardCardIcon tiles adopt the new colours.

Remaining pale-blue consumers include shared screen backgrounds (board library, Choice Board, photos, photo editing, layouts, titles, formatting, previews, settings, credits and welcome screens), the symbol-picker navigation background, shared header defaults, custom question/rename/text-input alert surfaces and cancel buttons, and the person tile in the empty-board illustration. SharedUITheme also defaults card backgrounds to pale blue, but production setup overrides that property with `Theme.cardBackgroundColor` (light blue).

Build commands (no tests):

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation build
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation build
```

Both builds succeeded. Logs: `.build/classic-interface/ice-mist-standard.log` and `ice-mist-plus.log`. Tests were not run.

### Pale Blue adopts Ice Mist (25 October 2026)

Supersedes the restoration above: `mfPaleBlue` now resolves to `#F5F7FA` at its shared source, and the Classic menu background again references `mfPaleBlue`. All other pale-blue consumers inherit the new value. Glacier Blue icon tiles and dark-mode backgrounds are unchanged. No tests were run.

Build commands:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation build
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation build
```

Both builds succeeded. Logs: `.build/classic-interface/pale-ice-standard.log` and `pale-ice-plus.log`; screenshot: `pale-ice.png`. No tests were run.


### Boardlet edition defaults and settings gates (25 October 2026)

Boardlet now applies Classic/Paper at startup, including for previously saved New/Screen preferences. Welcome also saves Classic/Paper. Interface and layout destination changes require Boardlet+. These controls are now completely hidden in Boardlet. Boardlet+ keeps its existing defaults and selectable preferences. The screen-only topic layout remains separate.

Both production variants built successfully on the existing iPhone 18 Pro (iOS 27.0). Standard passed nine startup unit tests and one UI test covering Classic/Paper, disabled controls and relaunch. Plus passed the interface-switching/shared-board/persistence UI test. The full suites and iPad layouts were not run.

Exact successful commands, from the repository root:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan 'PECS Maker' -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS="$PWD/.build/board-editor/DerivedData/SourcePackages/checkouts" '-only-testing:PECS MakerTests/StartupExperienceTests' '-only-testing:PECS MakerUITests/InterfaceStyleUITests/testDefaultSwitchPersistenceAndSharedBoard' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModesPlus -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS="$PWD/.build/board-editor/DerivedData/SourcePackages/checkouts" '-only-testing:Easy PECS Plus UI Tests/InterfaceStyleUITests/testDefaultSwitchPersistenceAndSharedBoard' test
```

The initial sandboxed attempt could not access dependency caches; the first unrestricted attempt failed to locate the SettingsFramework test identifier source. Explicitly setting `BOARDLET_PACKAGE_CHECKOUTS` resolved that reference. Logs: `.build/classic-interface/defaults-standard.log` and `defaults-plus.log`. Build-generated version increments were reverted.

### Shared Classic photos editor (25 October 2026)

Classic now routes both photo menu destinations to `PhotoListView2`. Its action filtering applies to portrait and landscape and avoids an empty bottom bar in Standard. The focused navigation test checks hidden editor actions in both orientations, the Titles menu action, selection mode and return navigation.

Exact commands, from the repository root:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS="$PWD/.build/board-editor/DerivedData/SourcePackages/checkouts" '-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testClassicBoardsToolbarAndNavigation' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModesPlus -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS="$PWD/.build/board-editor/DerivedData/SourcePackages/checkouts" '-only-testing:Easy PECS Plus UI Tests/ClassicInterfaceUITests/testClassicBoardsToolbarAndNavigation' test
```

Standard built and passed one test with zero failures on the existing iPhone 18 Pro (iOS 27.0). The initial Plus run built and passed the hidden-action assertions, then failed because the test's button helper checked the menu during a rotation transition. The test now waits for the menu after restoring orientation. Logs: `.build/classic-interface/shared-photos-standard.log`, `shared-photos-plus.log`, and `shared-photos-plus-rerun.log`. The initial sandboxed attempt could not access Xcode caches; verification used expanded access. Full interface suites and iPad were not run.

The Plus rerun passed one test with zero failures using the same command above. The initial failed Plus process stalled collecting results and was terminated after its test failure was recorded. Build-generated version increments were reverted.


### Hide Standard-only settings controls (25 October 2026)

Supersedes the disabled-control presentation above: regular Boardlet entirely omits the Interface section and layout destination picker, including the Boardlet+ requirement messages. Classic/Paper remain fixed. Boardlet+ retains its settings controls.

The focused Standard UI test passed with assertions that both controls are absent; the Plus build succeeded. Exact commands:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS="$PWD/.build/board-editor/DerivedData/SourcePackages/checkouts" '-only-testing:PECS MakerUITests/InterfaceStyleUITests/testDefaultSwitchPersistenceAndSharedBoard' test
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation build
```

Logs: `.build/classic-interface/hidden-standard.log` and `hidden-plus.log`. Full suites were not rerun.


### Shared Main Menu card styling (26 October 2026)

The photo section (`BoardPhotoCard`) and large action buttons (`BoardActionButton`) use `BoardCardSurface` for their background shape, outline, and shadow. Adjust those shared visuals in `PECS Maker/Components/BoardCardSurface.swift`; selected actions retain their stronger outline and selected/output actions retain their blue fill.

Both production schemes built and passed the focused compact-height menu UI test on the existing iPhone 18 Pro (iOS 27.0): one test per scheme, zero failures. This checks portrait/landscape layout and direct photo editing, not pixel-level appearance or iPad layout.

Exact commands, run from the repository root:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO '-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testClassicCompactHeightMenuAndDirectPhotoEditing' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModesPlus -parallel-testing-enabled NO '-only-testing:Easy PECS Plus UI Tests/ClassicInterfaceUITests/testClassicCompactHeightMenuAndDirectPhotoEditing' test
```

### Photo card decomposition verification (26 October 2026)

Both production variants compiled with the extracted content and thumbnail views. The Standard focused UI test reached the thumbnail tap, then stalled waiting for the app to become idle; it was interrupted and is not a pass. Plus was build-checked only. No iPad or iOS 16.6 runtime check was performed.

Exact commands, run from the repository root:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO '-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testClassicCompactHeightMenuAndDirectPhotoEditing' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation build
```

Logs: `.build/photo-card-refactor/standard.log` and `.build/photo-card-refactor/plus-build.log`. Removed one build-generated version increment per variant, preserving concurrent checkout edits. Project-file syntax validation and `git diff --check` passed.


### What’s New content (26 October 2026)

The shared startup release notes now highlight iOS 27 and iPhone Duo support, flexible photo positioning, symbol search, and text only cards, in that order. English and Spanish content lives in `PECS Maker/Assets/WhatsNew/WhatsNew_en.json` and `WhatsNew_es.json`; both production targets include these resources. The existing scrollable startup sheet presents the content in portrait and landscape.


Verification commands (existing iPhone 18 Pro, iOS 27.0):

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan 'PECS Maker' -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:PECS MakerUITests/WhatsNewUITests/testWhatsNewScreen' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation build
```

Standard built and passed the focused UI test (one test, zero failures); Plus built successfully. Final captures are in `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/content-final-captures/`. Landscape retains vertical scrolling. The first capture caught the rotation animation; the final test waits for landscape dimensions and the animation before capturing. Logs are `content-standard-retest.log` and `content-plus-build.log` in the same task output folder. Full suites and Spanish runtime appearance were not checked. Build-generated version increments were removed, preserving the pre-existing plist changes.


Follow-up wording correction (26 October 2026): flexible layouts now says “Choose the position of each photo on the board.” Symbol search says “Find symbols to add to your boards.” Spanish descriptions use the corresponding board terminology. The landscape grid is a proposal only; the implementation remains scrollable.

Reran the exact Standard test and Plus build commands above after this wording correction: Standard passed one focused UI test with zero failures; Plus build succeeded. Logs: `board-wording-test.log` and `board-wording-plus.log` in the external `whats-new` output folder. Build-generated version increments were removed.


### What’s New landscape layout (26 October 2026)

The approved landscape proposal is now implemented in `StartupWhatsNewView`. Compact-height windows use a smaller header and a two-column grid in reading order, with the footer and Continue button in a bottom safe-area inset. Portrait retains the single-column sheet. Accessibility Dynamic Type sizes use one scrollable column and a stacked footer; Continue remains outside the scrolling content. Natural portrait content height is still measured with `onGeometryChange`, independently of the sheet viewport. iOS 16.6 remains supported.

Verification used the exact Standard test and Plus build commands in the What’s New content section above. Standard built and passed one focused UI test with zero failures, now asserting the two-column arrangement and visibility of every feature title and Continue in landscape. Plus built successfully. Portrait and landscape screenshots were visually checked and are in the external `whats-new/landscape-grid-captures` folder. Logs: `landscape-grid-standard-final.log` and `landscape-grid-plus.log`. Two earlier compilation attempts exposed padding overload mismatches, which were corrected before the successful run. Build-generated version increments were removed. Accessibility text sizes, Spanish, iPad and iOS 16.6 were not runtime-tested in this change.


### Print preview resizing (26 October 2026)

Focused regression: `ClassicInterfaceUITests/testClassicPreviewResizesAfterRotation` checks the side-by-side compact-height layout, visible output actions, both landscape directions, original portrait page dimensions after each rotation, formatting presentation, and the print share sheet. It uses the isolated board fixture and never writes to the Photos library.

Exact verification commands, run from the repository root on the existing iPhone 18 Pro / iOS 27.0:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/print-preview/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testClassicPreviewResizesAfterRotation' -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/print-preview/standard-final.xcresult test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/print-preview/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan InterfaceModesPlus -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:Easy PECS Plus UI Tests/ClassicInterfaceUITests/testClassicPreviewResizesAfterRotation' -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/print-preview/plus.xcresult test
```

Both production schemes built and passed this focused test (one test each, zero failures). Standard was rerun after adding the minimum portrait preview height. The initial Standard run also passed. Portrait captures from both variants and the final Standard landscape capture were visually checked. Earlier landscape captures were taken before the simulator finished rotating its screenshot surface; the final test waits briefly after the geometry assertions and captures the whole screen.

Results and logs are in the external `print-preview` folder above (`standard-final.xcresult`, `plus.xcresult`, and matching `.log` files). The run did not exercise iPad, iOS 16.6, accessibility text sizes, multi-page selection retention, or saving into Photos. All four build-generated version increments (three Standard, one Plus) were removed while retaining the starting plist values. Project syntax and `git diff --check` passed.


### Compact action rail and portrait dock (26 October 2026)

The current layout supersedes the wide column of separate filled buttons described in the earlier verification. Compact height centers the page beside a 192-point rail; the group width follows the available height and the document aspect ratio. Secondary actions share a neutral material surface and Print remains prominent. Portrait uses horizontal icon-and-text actions and a separate Print button, giving more space to the page. Preview rasters now use `displayScale` for Retina detail. Neither geometry measurement depends on the fitted image size.

The focused test now uses a full 3 × 5 board, checks the horizontal portrait actions, limits the landscape rail width and gap, and asserts that captured landscape images are wider than they are tall. Plus runs this test in dark mode and Standard in light mode.

Verification commands:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/print-preview/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan InterfaceModesPlus -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:Easy PECS Plus UI Tests/ClassicInterfaceUITests/testClassicPreviewResizesAfterRotation' -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/print-preview/redesign-plus-verified.xcresult test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/print-preview/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testClassicPreviewResizesAfterRotation' -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/print-preview/redesign-standard.xcresult test
```

Both production variants built and passed one focused UI test with zero failures on the existing iPhone 18 Pro / iOS 27.0. The Plus dark-mode portrait and landscape captures, and Standard light-mode portrait and landscape-right captures, were visually checked. Standard's first landscape attachment caught blank artwork during the transition; the subsequent landscape-right and restored portrait captures show the complete board. The layout assertions do not measure transition rendering latency. The first two Plus attempts were interrupted during test-only setup/assertion problems: a redundant Back after automatic picker dismissal, then a strict gap check on intentionally adjoining portrait buttons. The final test compares button centers. No app changes were needed for those corrections.

Exported XCTest PNGs retain EXIF orientation, so viewers that ignore it can display a landscape capture as portrait. Delivered screenshots have the EXIF transform applied to their pixels (2622 × 1206 for landscape), without changing the app content. Build-generated version increments were removed (four Standard, three Plus), preserving the pre-existing plist values. `git diff --check` and project syntax validation passed. iPad, iOS 16.6 runtime, accessibility text sizes and later-page selection retention were not exercised in this refinement.


### Plus-only Inspire Me and Language menus (28 October 2026)

Regular Boardlet now omits Inspire Me from the Classic and editor menus and omits the editor's Board language menu. Boardlet+ retains these entries. Symbol search, automatic board suggestions, stored translations and language fallback are unchanged.

Both production variants built and passed two focused UI tests each on the existing iPhone 18 Pro running iOS 27.0. The tests check menu absence in Standard and presence in Plus, including Inspire Me in Classic. Initial Standard runs failed because the new tests expected custom identifiers on native iOS 27 overflow items; the final checks support their accessibility labels as well. Full suites were not run.

Exact successful commands (from the repository root):

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "PECS Maker" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/menu-gates/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts "-only-testing:PECS MakerUITests/InterfaceStyleUITests/testBoardMenuOptionsMatchEdition" "-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testClassicInspireMenuMatchesEdition" test

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "Easy PECS Plus" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/menu-gates/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan InterfaceModesPlus -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts "-only-testing:Easy PECS Plus UI Tests/InterfaceStyleUITests/testBoardMenuOptionsMatchEdition" "-only-testing:Easy PECS Plus UI Tests/ClassicInterfaceUITests/testClassicInspireMenuMatchesEdition" test
```

Logs and DerivedData are under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/menu-gates/`; successful logs are `standard-final.log` and `plus.log`. Existing plist changes were preserved; only this task's generated build-number increments were removed.


### FeatureFramework consolidation (28 October 2026)

Supersedes the app-owned implementation above: release loading, display policy and adaptive presentation now live in FeatureFramework. The app coordinates startup readiness only. See [the shared What’s New guide](../../WhatsNew.md) for release IDs, first-install behaviour, migration and verification.


### Compact buttons bottom alignment (28 October 2026)

The compact-height horizontal layout now uses bottom alignment, placing the action panel at the bottom of the preview viewport. Portrait layout is unchanged. Verification uses the existing rotation test.

Exact commands:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/print-preview/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testClassicPreviewResizesAfterRotation' -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/print-preview/bottom-alignment/standard.xcresult test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/print-preview/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation build

```

Standard compiled, then its UI test failed in sample-layout selection before reaching Preview. A contemporaneous simulator capture showed Board Scanner in the foreground, so this run does not verify preview behavior. Plus built successfully without launching, to avoid interfering further with that session. Logs are `standard.log` and `plus-build.log` in the external `print-preview/bottom-alignment` folder. Build-generated version increments were removed and `git diff --check` passed.


### Paper/Screen section header (28 October 2026)

The destination now sits in the Paper Size section header above the rounded size card, not inside the card. Boardlet shows plain Paper text; Boardlet+ shows the Paper/Screen menu picker. Screen mode keeps that header visible so users can return to Paper. The header uses the same secondary colour and 12-point horizontal inset as Orientation and the other layout headings. The size menu has its own minimum 44-point tap area.

Both variants passed the header-position and portrait/landscape persistence UI tests (two tests each). Both builds passed again after the colour-only correction; UI tests were not repeated for that styling change. Full suites were not run. Exact commands:

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "PECS Maker" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/menu-gates/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan InterfaceModes -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts "-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testLayoutDestinationInSizeHeader" "-only-testing:PECS MakerUITests/ClassicInterfaceUITests/testPageLayoutColumnsAndBoardTitlePersistence" test

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "Easy PECS Plus" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/menu-gates/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan InterfaceModesPlus -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts "-only-testing:Easy PECS Plus UI Tests/ClassicInterfaceUITests/testLayoutDestinationInSizeHeader" "-only-testing:Easy PECS Plus UI Tests/ClassicInterfaceUITests/testPageLayoutColumnsAndBoardTitlePersistence" test

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "PECS Maker" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/menu-gates/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation build

/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "Easy PECS Plus" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/menu-gates/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation build
```

Logs are in `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/paper-header/`; these runs reuse the external `menu-gates/DerivedData` cache. This task's generated build-number increments were removed, preserving the pre-existing plist edits.
