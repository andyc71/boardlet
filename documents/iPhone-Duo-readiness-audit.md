# iPhone Duo suitability audit

PECS Maker and Easy PECS Plus have a useful adaptive foundation, but they need navigation, toolbar, image-editor, and presentation changes before their Duo experience can be considered ready. The highest priorities are keeping work intact as the available space changes, making essential actions usable in vertical bars, and keeping precise controls away from unsafe edges and the fold.

Audit date: 10 October 2026. Source baseline: commit `f8100ab`. Scope includes both production schemes and Modern/Classic interfaces, the separate Boardlet rebuild, shared Photos picker and harness, four local packages, and the reachable UI in associated remote packages. It is a source audit. The code patterns below are confirmed; pose-dependent clipping, fold obstruction, and state loss have not been reproduced at runtime. No application or package source was changed.

## Platform and project baseline

The installed toolchain is Xcode 27.1 (`27A9275`), and the simulator SDK reports 27.1. Both production targets use `SDKROOT = iphoneos`, iOS 16.6 deployment, Swift 5, and device families 1 and 2. This environment can build for the full-display Duo tier; the SDK used for the currently distributed binary was not established. An iOS 27.1 SDK build enables the new display and bar behavior, so recompilation must be accompanied by layout validation. Keep the deployment target at 16.6 and gate newer APIs. [Apple SDK behavior guidance](https://developer.apple.com/iphone-duo/prepare/?cid=261006-hello-li-duoprep&trk=article-ssr-frontend-pulse_little-text-block).

Both production Info plists declare launch storyboards, `UIRequiresFullScreen = false`, all four orientations in the general declaration, and single-scene operation. Target build settings also specify all four iPad orientations and portrait for iPhone. Reconcile those declarations and inspect the processed build plist before changing outer-display orientation policy. There is no launch-screen or fullscreen prerequisite blocking general resizing. Boardlet likewise has launch screens, four orientations, and iOS 16.6 deployment, with Swift 6.

Treat available space as the layout input. The supplied Duo skills describe compact outer-display width and regular inner-display width/height; inner-display rotation cannot be constrained by an iPhone portrait assumption. Validate both physical orientations and reduced app windows. Do not introduce an `isDuo` branch or derive ordinary layout from hinge angle.

The source membership check matters: production uses `PECS Maker/Views/Pages/MainMenuView.swift`; the similarly named `Views/MainMenuView.swift` and ` 2.swift` duplicates are not interchangeable evidence. The Modern board route now goes directly to `PhotoListView2`. The active photo-selection UI is the shared system Photos picker; ZLPhotoBrowser remains active for image editing.

## Prioritized changes

P1 means address or explicitly validate before declaring Duo readiness. P2 means improve the experience after the P1 foundations. P3 is optional product enhancement. No demonstrated P0 crash or data-loss incident was established by this static audit.

### P1 Make navigation adaptive while retaining editing state

**Evidence:** [ContentView.swift:51](</Users/andy/dev/PECSMaker/PECS Maker/Views/ContentView.swift:51>) permits split navigation only above 1,024 points and substitutes a different view hierarchy. [NavigationModel.swift:13](</Users/andy/dev/PECSMaker/PECS Maker/Classes/NavigationModel.swift:13>) maintains independent compact and split paths. [PhotoListView2.swift:37](</Users/andy/dev/PECSMaker/PECS Maker/Views/Pages/PhotoListView2.swift:37>) owns selection, page, zoom, sheets, and focused-card navigation locally; [PhotoCellZoomed.swift:20](</Users/andy/dev/PECSMaker/PECS Maker/Views/Pages/Subviews/PhotoCellZoomed.swift:20>) owns unsaved title and image edits locally.

Every container at or below 1,024 points receives the compact route, even when regular-width space could support useful navigation. Crossing the current boundary reconstructs descendants without a compact/split route transfer. This is a structural continuity risk, not proof that ordinary Duo folding crosses that particular threshold.

Use one selection-driven `NavigationSplitView` that can collapse naturally. Retain board/card IDs, route, current page, zoom/scroll anchor, multiselection, draft edits, and pending presentation/import state above layout changes. Preserve the existing shared `PageLayoutState`; it already avoids recreating the board model for the same topic. Do not simply lower the breakpoint and expose the state handoff problem.

Boardlet has a related risk: [BoardsView.swift:65](/Users/andy/dev/PECSMaker/Boardlet/Sources/Features/Boards/BoardsView.swift:65) constructs separate editor instances in compact navigation and detail, while `BoardEditorView.swift:8` owns local selection and presentation state. Apply the same state-continuity requirement there.

**Acceptance:** begin editing an unsaved label, selecting cards, or importing images; resize, open/close, rotate, and restore width. The same board/card, draft, selections, route, and operation must remain active.

### P1 Give essential actions native vertical toolbar representations

**Evidence:** [PhotoListView2.swift:280](</Users/andy/dev/PECSMaker/PECS Maker/Views/Pages/PhotoListView2.swift:280>) embeds `BoardEditorActionButtons(vertical: false)` inside a toolbar group. [BoardEditorActionButtons.swift:10](</Users/andy/dev/PECSMaker/PECS Maker/Views/Pages/Subviews/BoardEditorActionButtons.swift:10>) supplies a custom horizontal layout with spacers and stacked icon/text labels. The alternate side controls depend on compact height plus phone idiom (`PhotoListView2.swift:52`), which does not describe all vertical-bar poses. Select, Select All, and Close are title-only (`:137`, `:156`, `:239`).

These custom views and title-only controls are not equivalent to independent semantic toolbar buttons. They can remain horizontal and consume content height instead of participating usefully in the vertical bar. The source does not prove that buttons disappear. [Apple toolbar guidance](https://developer.apple.com/videos/play/tech-talks/111462/).

Expose Layout, Format, Share, Print, and Use as individual toolbar items with titles and symbols. Preserve recognizable labels for accessibility. Keep Back/Close and completion actions prominent, and prioritize frequent actions over secondary ones. Move the custom ellipsis overflow into `ToolbarOverflowMenu` where available. Tune custom axis behavior only for views that actually fit a vertical bar; avoid a blanket vertical-bar opt-out.

Apply the same pass to Topic Selection, Choice Board, Classic controls, Boardlet, and the ARASAAC/AAC pickers. Existing `CancelToolbarButton` and `ConfirmToolbarButton` wrappers are useful semantic starting points. Availability-gate 27/27.1 customization and retain 16.6 behavior.

**Acceptance:** all essential actions remain discoverable and operable on outer portrait/landscape, inner orientations, with keyboard shown, and in overflow. Check English, Spanish, VoiceOver, and accessibility text sizes.

### P1 Repair active image-editor safe areas and resize continuity

**Evidence:** [View+selectPhotos.swift:49](</Users/andy/dev/PECSMaker/PECS Maker/Extensions/View+selectPhotos.swift:49>) presents the ZL editor. Its local subclass resets Close to 16 points from a raw horizontal edge at [:125](</Users/andy/dev/PECSMaker/PECS Maker/Extensions/View+selectPhotos.swift:125>). In pinned ZLPhotoBrowser, `Sources/Edit/ZLEditImageViewController.swift:597–676` uses top/bottom insets but places Cancel, Undo/Redo, Done, sliders, and tool rows against raw horizontal bounds. `ZLClipImageViewController.swift:319–344` has similar placement; `ZLTextStickerView.swift:213` sizes stickers from `UIScreen.main.bounds.width`.

The editor does react to size transitions, but `resetContainerViewFrame()` resets zoom to 1 (`ZLEditImageViewController.swift:733`). Editor/crop orientation overrides also assume portrait on phones (`:435` and `ZLClipImageViewController.swift:234`). Thus there is existing relayout support, but it does not establish a stable editing experience through folding.

Fix the maintained package source/fork and pin the resulting revision. Use each view's current safe-area layout rect, respecting all four edges independently; remove the app's conflicting raw-edge override. Preserve zoom and the image-space focal point on relayout, and keep crop/drawing/text edits intact. Handle safe-area changes as well as size changes. Use local canvas geometry for sticker sizing. Review crop handles and sliders against active fold regions.

**Acceptance:** enter crop/draw/text edit, zoom and pan, then resize/rotate/fold. Close, Done, handles, sliders, and editing content must stay reachable without losing the working viewport. Confirm capture behavior separately on hardware.

### P1 Protect communication targets and custom presentations from the fold

**Evidence:** [ChoiceBoardView.swift:81](</Users/andy/dev/PECSMaker/PECS Maker/Views/Pages/ChoiceBoardView.swift:81>) puts the message and speech/delete controls in custom horizontal stacks; its board uses a custom grid at `:124`. [SystemPhotoPickerPresenter.swift:39](</Users/andy/dev/PECSMaker/PECS Maker/Extensions/SystemPhotoPickerPresenter.swift:39>) centers import status/cancel against the full view. SharedSwiftUI's active rename path uses third-party Popovers (`Alerts/View+renameItem.swift:15`, `Prompts/View+askQuestion.swift:54`), and confirmations/success use centered custom content in a full-screen cover (`Alerts/View+successAlert.swift:65–99`). These paths contain no explicit division-region handling.

Prefer native alerts and text-entry sheets for rename/delete/confirmation. For indispensable custom content, inspect active division/occlusion regions in local coordinates and move related controls into a usable area. Safe areas alone do not describe the fold. Review the MediaFramework mute banner as another custom text/action overlay.

Preserve communication-board row, column, and page semantics. These are meaningful to AAC users and printed output; replacing them with a width-driven adaptive grid would change learned positions. Keep the canonical board and export geometry unchanged. Explore scrolling the active target clear of the fold, positioning a whole board viewport in a usable pane, or a deliberate gutter with a consistent coordinate mapping. Validate any change with accessibility and motor-planning needs. Boardlet explicitly promises stable communication positions in `BoardControlsView.swift:31`.

The production sentence strip also has no scrolling container around its sequence of 60-point items. Give it a bounded horizontal scroll area, retain the latest item visibly, and keep Speak/Delete reachable as sentences grow or the app narrows.

**Acceptance:** partially fold in both orientations with a dense board, long sentence, rename keyboard, destructive confirmation, or active import. No essential target/text/action should be trapped across the fold; board order and sentence state must remain stable.

### P2 Base density and supplementary panes on usable space

**Evidence:** [TopicSelectionViewPlus.swift:70](</Users/andy/dev/PECSMaker/PECS Maker/Views/Pages/TopicSelectionViewPlus.swift:70>) chooses 100-point phone versus 180/200-point iPad grid minimums by idiom. `ClassicSelectedPhotosView.swift:56` and Dynavox's `Views/DVSymbolPicker.swift:43` have comparable branches. These grids already adapt; the device-based minimum is the issue.

[PhotoCellZoomed.swift:61](</Users/andy/dev/PECSMaker/PECS Maker/Views/Pages/Subviews/PhotoCellZoomed.swift:61>) requires compact vertical size class for preview/properties columns, excluding regular-height inner-display space regardless of width. Boardlet's `CardDetailsView.swift:114` repeats that restriction. Classic preview sizing still reaches `UIScreen.main` through [PageLayoutState.swift:761](</Users/andy/dev/PECSMaker/PECS Maker/Classes/PageLayoutState.swift:761>) and `ClassicPreviewAndPrintView.swift:67`.

Choose library/grid minimums from legibility, touch size, and Dynamic Type. Use actual available component space for preview/properties arrangements; retain readable form widths. Replace Classic screen-based preview sizing with container input. Prefer `AnyLayout` for rearranging the same children; SharedSwiftUI's `Components/AdaptiveLazyStack.swift:39` currently swaps structural stack branches.

For a richer inner-display editor, consider an inspector or a dedicated preview/properties arrangement after these universal improvements. `ArrangementView` is an optional 27.1 tool for an appropriate two-part experience, not an app-navigation replacement. Respect its container restrictions. Boardlet's inline/sheet inspector threshold at `BoardInspector.swift:18` also needs a state-preserving handoff; a minimum-width threshold is not inherently wrong.

### P2 Make package dialogs usable at short heights and with the keyboard

`AISymbols/Sources/AISymbols/AISymbolPicker.swift:54–129` has a non-scrolling VStack, requests keyboard focus, and puts confirmation below its image. Dynavox's search/Cancel and Confirm are custom horizontal rows (`DVSymbolPicker.swift:89`, `:138`). `FeatureFramework/Views/FeaturesView.swift:35–120` puts variable content and Close in a non-scrolling stack; `WhatsNewModifier.swift:21` combines it with SharedSwiftUI's vertically fixed, measured-height sheet (`Popup/AutosizingSheet.swift:16`).

Add scrolling or a fitting fallback while keeping completion/dismissal in system chrome. Cap sheet content to available height. Use extra width for prompt/result or preview/properties when useful, without duplicating operation state. Keep ARASAAC and AAC Standard's existing adaptive grids; improve their title-only Cancel/Add and progress toolbar representations (`ARASAACSymbolPicker.swift:56`, `AACStandardSymbolPicker.swift:74`).

**Acceptance:** present every picker and What's New/voting screen with large text, long localized labels, keyboard, and short outer landscape space. Confirm and Cancel/Close must remain reachable during rotation and folding.

### P2 Bind UIKit presentations to the initiating scene

[View+selectPhotos.swift:35](</Users/andy/dev/PECSMaker/PECS Maker/Extensions/View+selectPhotos.swift:35>) chooses the first foreground scene/key window. Photo selection, camera, image editing, sharing, and printing use this presentation route. SharedSwiftUI rename keyboard handling similarly picks a global active scene and uses keyboard height rather than intersection in the presenting window (`View+renameItem.swift:133–162`).

Pass the initiating controller/scene or use local SwiftUI presentation. Convert keyboard frames into that view's coordinate space and react to frame changes. Anchor share/print to the initiating control when possible; review the print helper's iPad-only anchoring branch at `ActivityViewController.swift:64` against actual presentation behavior.

The production app currently declares single-scene operation, so this is not evidence of an existing multiple-window failure. Resolve this debt before offering multiple windows, and validate ongoing presentations across display transitions. Enabling multiple scenes is optional for Duo readiness.

### P1 Add Duo transition coverage to release validation

Existing tests are valuable but do not establish Duo readiness. `BoardPageRenderingTests.swift:547` tests continuous geometry resizing and `:559` cancellation; `PhotoSelectionScreenTests.swift:900` contains editor/rotation/zoom journeys. The shared picker matrix targets conventional phone/tablet configurations through iOS 27.0. Portrait and landscape runs do not substitute for folding while an operation is active.

The picker driver at `TestSupport/SystemPhotoPicker/SystemPhotoPickerDriver.swift:99–113` derives tappable grid bounds from top navigation and bottom toolbar assumptions. Rework those calculations from observed container/control intersections where Duo changes bar placement, rather than hardcoding device dimensions. Include BoardletPlus Use-mode coverage if the rebuild will ship; its current scheme/test setup does not provide equivalent coverage.

## Package coverage and ownership

All four local manifests/UI surfaces were reviewed. Cached remote sources were inspected at the application's resolved revisions, with active call paths separated from unused helpers. Remote paths above are relative to `/Users/andy/Library/Developer/Xcode/DerivedData/PECS_Maker-fyqawxsiikriqneycdivjyiqytao/SourcePackages/checkouts/<package>/`. Matching checkouts also exist under `.build/SourcePackages/checkouts`.

| Package or area | Audit result and work owner |
| --- | --- |
| Local ARASAACSymbols | Adaptive system-navigation picker; improve actions/progress and test short heights. Repository package change. |
| Local AACStandardSymbols | Adaptive system-navigation picker; same toolbar work, including large offline grids. Repository package change. |
| Local MediaFramework | Audio service plus active custom mute banner; retain playback through transitions and review banner positioning. |
| Local OpenSymbols | Client-only and no active production reference/import found. No Duo UI change identified. |
| SharedSwiftUI `ed180b9` | Active centered prompts, keyboard handling, measured sheets, branch-based adaptive stack. Fix maintained package and update its pin. |
| ZLPhotoBrowser 5.0.0 `a081f0d` | Active editor/crop/text workflow needs safe-area and viewport preservation work. Old photo-browser UI is not the production picker. |
| DynavoxSymbols `0ce5549` | Active Plus picker has idiom density and custom action rows. Workspace also references sibling `../DynavoxSymbols` at `31b1e2e`; both inspected versions have these findings. Verify the entry point used for package fixes. |
| AISymbols `a3c1f29` | Active Plus generator needs compact-height/keyboard fallback. Its declared `isIPad` property is unused and was not counted as a defect. |
| FeatureFramework `aa5eb13` | What's New height and voting-prompt presentation need validation/improvement. |
| SettingsFramework `2af3110`, RatingFramework | No specific high-priority geometry defect established in inspected active surfaces; include settings, logs, feedback, and ratings in presentation testing. |
| Popovers 1.3.2 `de44c4d` | Already window-scoped and updates on bounds changes. Custom centered callers lack fold avoidance; this is not a blanket static-sizing defect in the library. |
| SwiftUIX 0.3.1 `e175466` | Active utility helpers inspected; unrelated screen/window infrastructure was not treated as a reachable app defect. |
| Media 3.0.0 `84acbe8` | MediaCore linked, but no active app/local-package import or call found. MediaSwiftUI camera UI is not the active camera. Cleanup is dependency hygiene. |
| MailFramework, PersistenceFramework, LogFramework, LogFrameworkFirebase, ThemeFramework | Additional layout-pattern scan found no screen/orientation/idiom/safe-area layout hits. This does not certify every transitive dependency. |

SharedSwiftUI's old `Popup.swift:63` has screen-size assumptions, but no active app invocation was found. Device-info helpers, autofill fixture branches, and excluded duplicate source files should not inflate the production remediation list. Inspect and update maintained package repositories rather than editing downloaded build-cache checkouts.

## Acceptance matrix and implementation order

| Situation | What must remain correct |
| --- | --- |
| Outer portrait and landscape | Reachable toolbar actions; bounded forms and sentence strip; keyboard does not trap completion. |
| Inner orientations, flat and partially folded | Useful navigation/detail space; safe editing controls; readable content and targets clear of active fold. |
| Open and close during work | Same board/card, unsaved title/image, selections, page, scroll/zoom, import, sentence, and playback state. |
| Split View on both sides and intermediate widths | Independent left/right safe areas; correct presentation anchor; no oscillating layout or dropped sheet. |
| Accessibility and localization | English/Spanish, accessibility text sizes, VoiceOver focus, Reduce Motion, reachable targets and predictable card ordering. |
| Photo, symbol, camera, share and print flows | Selection/cancel/confirm work through transitions; camera tested on physical hardware; exported page geometry unchanged. |

First make the navigation/state and toolbar changes in both production variants, including Classic where retained. Then repair the editor and shared prompts in their owning packages. Add fold-aware behavior only where native containers and ordinary geometry cannot provide it. Finish the broader package/inner-display refinements and run the matrix against the actual 27.1 build.

Reuse the focused board renderer/editor suites and documented picker runners. Use the existing iPhone 18 Pro on iOS 27.0 for ordinary regression checks, then the installed Duo on iOS 27.1 for pose testing. Photos tests requiring destructive setup must use the documented disposable-device scripts; never run historical `PECS MakerTests/SetupPhotos.swift` against the personal simulator/library. Both production schemes must pass, and package changes must retain iOS 16.6 compatibility.

P3 ideas can follow: a tabletop board/message arrangement or a camera capture accessory that helps a child during a photograph. Hinge-angle-driven effects and an outer-display communication-board mirror are not baseline requirements. Keep ordinary layout independent of hinge angle; use supported camera accessory APIs only for the camera scenario, with hardware validation.

## Verification performed

The initial checkout was clean. The audit read source, target membership, plists, build settings in project files, package manifests/resolutions/checkouts, and existing test code/documentation. It also checked Duo API declarations in the installed SDK and consulted the iPhone Duo readiness, App Resizability, SwiftUI Duo, and SwiftUI review skills.

| Exact environment command | Result |
| --- | --- |
| `git rev-parse --short HEAD` | `f8100ab` |
| `git status --short` | Clean before the audit document was added. |
| `xcodebuild -version` | Xcode 27.1, build 27A9275. |
| `xcrun --sdk iphonesimulator --show-sdk-version` | 27.1. |
| `xcrun simctl list devices available` | Initial sandbox call failed to connect; permitted retry succeeded. Existing iPhone 18 Pro iOS 27.0 and two iPhone Duo iOS 27.1 simulators were listed, all shut down. |

No build or test command was run, and no app was launched. Historical passing results in repository READMEs were not counted as current validation. Build success, processed orientation declarations, pose behavior, visual accessibility, camera behavior, and live-resize performance remain release-validation work. On future builds, review generated plist version and SwiftGen changes separately from intentional edits.
