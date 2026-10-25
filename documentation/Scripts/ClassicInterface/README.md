# Optional Classic interface

Configuration → Interface defaults to **New (default)** when no preference exists. The app-wide `pecsInterfaceStyle` preference is independent of Choice Board mode and board files. Changing it saves the current board and clears the old interface's navigation destinations. The setting is also reachable from the new editor's menu.

Classic restores the pre-editor workflow from `d0dde9e`: Main Menu, Selected Photos grid, paged Preview and Print, and the persistent iPad menu/detail columns. Both production targets currently define `AppHasTopics`, so both show Topics/Menu/Detail on wide iPad windows. Layout and Format use the current shared screens. Photo import, card editing, data, persistence, and rendering/export remain shared.

Classic shares the board hierarchy/search wrapper and lazy library catalogue with the modern editor. Its Main Menu hides Home, Search and Organize, without reserving space for those controls; parent and child board links remain available. Choice Board and the modern editor retain the library controls. Changing parent/child boards preserves the interface choice and communication sentence. Hierarchy links remain outside Classic's printable vocabulary pages. See [board hierarchy and search](../../BoardHierarchyAndSearch/README.md) for storage and management operations.

The non-split Main Menu places its photo card on the left and Layout, Titles, and Preview/Print on the right in compact height. Regular-height menus stay stacked, and split-view menus retain their existing arrangement. Tapping a thumbnail opens that photo directly in the shared editor; closing it returns to Main Menu. Change Selections still opens the full photo list.

The large action cards and Photos section use a faint 1-point VeryBrightBlue outline at 25% opacity. Their 46-point icon backgrounds use Glacier Blue (`#E3F2FD`) and a 9-point continuous corner radius to visually match the proportions of the large cards. The Classic menu uses `mfPaleBlue` in light mode and retains its existing dark-blue background in dark mode. The shared `mfPaleBlue` source is now Ice Mist (`#F5F7FA`), so all its consumers inherit that colour. Glacier Blue and Ice Mist also remain separately named colours in SharedSwiftUI.

## Ownership and removal

- `PECS Maker/Views/Classic/` contains every Classic-only view; each type is prefixed `Classic`.
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
