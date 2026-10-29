# iPhone Duo readiness

Reviewed against the working checkout on **24 October 2026**. This replaces the 10 October source audit at `f8100ab`: several of its proposed fixes are now implemented. This review inspected source and target membership only; it did not build, launch or test either app. Implementation is not proof of runtime readiness.

## Current implementation

| Area | Current source evidence | What still needs verification |
| --- | --- | --- |
| Navigation | `Views/ContentView.swift` delegates to `Views/ContentViewCompactOrSplit.swift`. The old 1,024-point gate is gone. Compact, Classic and Modern presentations use scoped bindings into one `NavigationModel.path`; the model also owns selected card IDs, selection mode and board page. | Compact/split branches still have different view hierarchies. Exercise unsaved card edits, zoom, sheets and imports through size-class changes; centralized navigation alone does not prove all local state survives. |
| Editor actions | `Views/Pages/PhotoListView2.swift` has individual symbol-labelled native toolbar actions, plus a custom portrait action row. Toolbar placement follows landscape state. The explicit ellipsis menu is retained; `ToolbarOverflowMenu` is commented out with a placement rationale. | Discoverability, overflow order, keyboard, long labels and vertical-bar behavior in both variants and Classic. Do not reintroduce the old recommendation as if no native action path exists. |
| UIKit presentation | `Extensions/View+selectPhotos.swift` has `ScenePresentationContext` and a controller anchor. Photo, camera and editor entry points take a presenting controller. | Presentation continuity and correct anchoring during display transitions; physical camera capture. |
| Image editor | The app's Close override now uses `safeAreaLayoutGuide.layoutFrame` and relayouts when insets change. | The current ZLPhotoBrowser revision's crop, text, zoom and focal-point continuity. The old audit's package revision and raw-edge Close finding are obsolete. |
| Communication | `Views/Pages/ChoiceBoardView.swift` has a horizontal sentence scroll view and active division-region handling. | Long sentences, dense boards, partial folds, controls and stable card/page positions. |
| Import overlay | `Extensions/SystemPhotoPickerPresenter.swift` constrains status to safe areas and handles active division regions. | Reachable cancel/progress through fold, rotation and keyboard transitions. |
| Rendering | `Classes/BoardPageViewport.swift` and `BoardPageRenderModel.swift` use card-aware fitting and coalesced raster preparation. | Live window resizing, scroll/zoom retention and responsiveness. See [editor verification](Scripts/BoardEditor/README.md). |

Paths above are relative to `PECS Maker/`. The active navigation source is `ContentViewCompactOrSplit.swift` in both production targets. The similarly named `ContentViewIOS16Split 2.swift` is not the implementation to edit.

## Remaining acceptance work

Use the current source, resolved package revisions and installed SDK declarations for any further changes. Do not edit downloaded package caches. Keep production deployment at iOS 16.6 and availability-gate newer APIs. Use `onGeometryChange` for SwiftUI measurements, observing only needed values independently of the layout they update.

| Situation | Required checks |
| --- | --- |
| Outer portrait and landscape | Reachable completion/navigation actions, bounded forms, usable sentence strip and software keyboard. |
| Inner orientations and partial folds | Content and essential controls clear of active division regions; stable board order and print geometry. |
| Opening/closing during work | Preserve board/card, draft label/image, selection, page, scroll/zoom, pending import and speech state. |
| Narrow and resized iPad windows | Correct safe areas and presentation anchors; no dropped sheet or oscillating layout. |
| Accessibility and localization | English/Spanish, large text, VoiceOver, Reduce Motion, predictable card positions and reachable controls. |
| Photo, symbol, camera, share and print | Confirm/cancel through transitions; physical camera and printer checks separately from simulator coverage. |

Review Classic, topic selection, card detail, ARASAAC/AAC/Dynavox/AI pickers, settings and shared package prompts as part of that matrix. The former package table described old pins and is removed; it cannot establish current dependency behavior. The [OpenSymbols client](OpenSymbols-symbol-search.md) remains unlinked and has no production picker UI to test.

The separate `Boardlet/Boardlet.xcodeproj` rebuild needs its own adaptation and Plus verification. Its [2 October results](BoardletRebuild/VERIFICATION.md) do not validate subsequent production changes or Duo poses. Its [migration limitation](BoardletRebuild/UPGRADE-PATH.md) also remains a release blocker.

## Verification procedure and evidence limits

Use the existing iPhone 18 Pro / iOS 27.0 for ordinary regressions, as required by `AGENTS.md`. Discover available Duo destinations and runtimes before pose testing with `xcrun simctl list devices available`; the original 10 October audit recorded Xcode 27.1 and Duo simulators, but that inventory is historical.

Build both production schemes, run the relevant editor and interface plans, and record exact commands/results. Use [the production picker matrix](Scripts/SystemPhotoPicker/README.md) and [shared harness](../PhotoPickerHarness/README.md) for tests needing a seeded Photos library. Never run historical `PECS MakerTests/SetupPhotos.swift` on a personal simulator. Review build-generated plist and SwiftGen changes separately.

No new runtime readiness claim is made by this documentation update. In particular, the old static audit and dated passing tests cannot substitute for fold transitions during active editing, accessibility checks or hardware validation.

## What’s New restoration — 26 October 2026

`StartupWhatsNewView` restores the previous FeatureFramework presentation style: themed centred heading, opal secondary text, 40-point blue feature icons aligned to the top of each text section, alert background and the shared primary `CapsuleButton`. The app-owned wrapper keeps Welcome sequencing, once-per-app-version release notes and rating/voting deferral. This restores the appearance, not the old `lastModified`-based display policy.

The sheet fits its natural content using `onGeometryChange` on the inner stack. A `ScrollView` keeps longer content and Continue reachable when the system caps the sheet height. The old framework implementation used a non-scrolling stack and its shared auto-height modifier; those constraints are not reinstated. The theme is explicitly supplied to the sheet in both production variants.

Xcode 27.1 supplies the iOS 27.1 SDK; the deployment target remains iOS 16.6. Remaining Duo risks are content-height/detent updates during live width changes, the shared theme’s custom heading fonts at accessibility sizes, and placement during partial folds. The sheet and scroll view use system containers and foreground content respects safe areas, but that alone does not verify all poses. Validate inner/outer transitions, rotation, narrow Split View and large text with Continue reachable throughout.

Verification commands (run from repository root):

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath .build/board-editor/DerivedData -skipMacroValidation -testPlan 'PECS Maker' -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS="$PWD/.build/board-editor/DerivedData/SourcePackages/checkouts" '-only-testing:PECS MakerUITests/WhatsNewUITests' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=A6BB8AD2-DBB8-4B88-BB65-C1850770A270' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipMacroValidation -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS="$PWD/.build/board-editor/DerivedData/SourcePackages/checkouts" '-only-testing:Easy PECS Plus UI Tests/WhatsNewUITests' test
```

Standard: build and one UI test passed on iPhone 18 Pro / iOS 27.0. The test covers presentation, dismissal and persistence after relaunch. A simulator screenshot was also inspected. The initial sandboxed invocation could not access package caches or Simulator services; the successful run used approved access. The first Plus invocation named the Standard test target and was rejected before building; the corrected command above selects the Plus UI test target.

A second Plus attempt encountered a build-database lock from concurrent work. An isolated local build then ran out of disk space. At the user’s request, temporary build outputs now use `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/DerivedData` on the external SSD, while reusing the resolved package sources. Source edits remain in the existing checkout.

The external-SSD Plus build completed successfully, but its filtered test invocation ran **zero tests** (confirmed with `xcresulttool get test-results summary`). This is build verification only; `WhatsNewUITests` is not included in the Plus test target.

Duo UI verification uses the Standard target that contains the test:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=A6BB8AD2-DBB8-4B88-BB65-C1850770A270' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipMacroValidation -testPlan 'PECS Maker' -parallel-testing-enabled NO BOARDLET_PACKAGE_CHECKOUTS="$PWD/.build/board-editor/DerivedData/SourcePackages/checkouts" '-only-testing:PECS MakerUITests/WhatsNewUITests' test
```

Standard on iPhone Duo / iOS 27.1: one What’s New UI test passed (presentation, dismissal and relaunch persistence). This does not exercise opening/closing the device, partial folds, Split View or large text. A subsequent user-requested change top-aligns the feature icons; the same command is rerun for that final layout.

Final top-aligned layout: the Standard What’s New UI test passed on the Duo destination (one test, 47.780 seconds). Final Plus build command:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=A6BB8AD2-DBB8-4B88-BB65-C1850770A270' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipMacroValidation BOARDLET_PACKAGE_CHECKOUTS="$PWD/.build/board-editor/DerivedData/SourcePackages/checkouts" build
```

Final Plus build: **BUILD SUCCEEDED**. Build-script changes to app `CFBundleVersion` values were reviewed; other concurrent checkout changes were preserved. Final verification logs are in `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/`.
