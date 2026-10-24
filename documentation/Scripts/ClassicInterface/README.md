# Optional Classic interface

Configuration → Interface defaults to **New (default)** when no preference exists. The app-wide `pecsInterfaceStyle` preference is independent of Choice Board mode and board files. Changing it saves the current board and clears the old interface's navigation destinations. The setting is also reachable from the new editor's menu.

Classic restores the pre-editor workflow from `d0dde9e`: Main Menu, Selected Photos grid, paged Preview and Print, and the persistent iPad menu/detail columns. Both production targets currently define `AppHasTopics`, so both show Topics/Menu/Detail on wide iPad windows. Layout and Format use the current shared screens. Photo import, card editing, data, persistence, and rendering/export remain shared.

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
