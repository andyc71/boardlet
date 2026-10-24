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
