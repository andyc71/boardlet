# Boardlet app implementation handoff

Implement a complete native SwiftUI replacement for Boardlet in this existing repository. The user wants a fresh app architecture based on the reviewed UI concepts, with excellent usability on iPhone, iPhone Duo, and iPad in portrait and landscape. This is authorization to implement the app, not just produce a plan or another prototype. Keep the existing app available while building and validating its replacement.

## Decisions and boundaries

- Work in `/Users/andy/dev/PECSMaker`. The user corrected an earlier reference to `dev3`; it is not the destination. The saved Codex project is named Boardlet.
- Create a clean project at `Boardlet/Boardlet.xcodeproj`, with new sources and tests beneath `Boardlet/`. Keep the existing `PECS Maker.xcodeproj`, app sources, and tests intact. Do not create a nested Git repository, clone the checkout, or work in a temporary copy.
- Use one implementation owner for project settings, model contracts, integration, and final verification. Delegate independent, bounded tasks only when useful and authorized, with explicit file ownership. Avoid multiple agents editing the project file or core models concurrently.
- Read `/Users/andy/dev/AGENTS.md` and the repository `AGENTS.md` before starting. The parent file contains general SwiftUI guidance and some MyMusic-specific instructions; the repository-specific Boardlet instructions govern this app. No root Xcode project was visible in the inspected `/Users/andy/dev` listing; its `AGENTS.md` supplies instructions rather than Xcode build settings.
- Preserve iOS 16.6 support unless the user explicitly changes that requirement. The parent's preference for a newer deployment target does not override the repository requirement. Use modern Swift and concurrency where supported without silently raising deployment targets or upgrading existing packages. Observation and SwiftData require availability consideration; they are not a reason to drop iOS 16.6.
- Do not automatically inherit the old app's dependency graph or script phases. Add only the existing components that have a clear purpose. Follow the parent instruction to ask before introducing new third-party frameworks or upgrading existing packages' iOS or Swift requirements.
- The app must remain useful offline for existing boards and locally available media. Cloud accounts, synchronization, subscriptions, new analytics, and a new backend are not part of the agreed scope.

## Working tree baseline

At handoff on 2 October 2026, the checkout was on `main` at `4774cf2d5f625c2b0e708d7fbbcc86f396620282`, with substantial pre-existing tracked and untracked changes. `baseline-status.txt` records status immediately before this handoff was added. Recheck live status; it may change after handoff.

Those changes belong to the user. Do not discard, stash, reset, clean, or include unrelated changes in a sweeping commit. Establish a clear baseline and protect existing edits before implementation. A local implementation branch is appropriate if it can be created without disturbing other work; do not infer permission to create a worktree from this instruction. The repository explicitly asks work to stay in this checkout.

The design review itself made no production app changes. This directory contains the handoff, baseline record, and copies of the concept mockups only. No native builds or tests were run as part of the UI review. The installed Xcode was observed as 27.0; recheck the installed SDKs and destinations before making platform claims.

## Design references

The user reviewed seven screens and explicitly requested an iPad landscape version. The selected direction is a calm, board-centred interface with a Boards library, an editor, a focused Use mode, and Print and Share. The user has authorized implementation of this direction; every visual detail has not been approved individually.

- `mockups/boardlet-workspaces.html` contains the original seven-screen interactive concept, with device and orientation controls.
- `mockups/boardlet-ipad-landscape.html` opens all seven concepts as iPad landscape examples.
- The original conversation artifacts are `/Users/andy/.codex/visualizations/2026/10/02/01a0fe10-c508-7af0-8dae-3afc85081400/boardlet-workspaces.html` and `boardlet-ipad-landscape.html` in that same directory.
- Existing screenshots under `screenshots/` and `PECS MakerUITests/BaseClass/__Snapshots__/` provide legacy UI references.

The HTML files are inline visualization fragments, not a production website or SwiftUI implementation. They can be wrapped for local viewing with the installed visualize skill's `scripts/render.py`. Use the relevant visualization skill if presenting or modifying them in chat. Do not implement the app as a WebView.

The concepts were inspected in a browser, including a 320px viewport and working layout, selection, and message-strip interactions. This is not native device verification. Emoji are placeholder artwork, several actions only announce a simulated system flow, and the mockups simplify persistence, templates, export, and accessibility. Replace these with real implementation. Do not carry over mockup pixel breakpoints, minimum heights, sample-only behaviour, incomplete undo, or inconsistent settings merely because they appear in the HTML.

Apple reference: https://developer.apple.com/design/human-interface-guidelines/designing-for-iphone-duo . Check platform documentation and installed SDK availability for actual APIs. Do not invent Duo APIs or assume a requested simulator is installed.

## Product structure

### Boards library

Make saved boards the home screen. Show recognizable previews and readable names, a prominent New board action, search, and optional pinned boards. Keep Settings available here. Existing boards should open directly into the relevant board workspace. Avoid a large intermediate menu of Photos, Titles, Layout, and Preview.

Support board creation, rename, duplicate, cover image selection, and recoverable deletion. Keep pinned ordering intentional. Do not reorder communication choices based on recent use while someone is using a board.

### New board

Offer a blank board and a small set of useful starters such as First and Then and Routine. These are proposed additions to make creation easier, not claims about existing templates. Make the templates functional rather than decorative choices. Naming and print setup must not obstruct adding the first card; supply sensible editable defaults.

### Board editor

Keep the board itself visible. Tap a card to edit it. Put board layout and style in contextual tools and an inspector. Retain a fast Edit all labels view for batch work. Support reorder, multi-selection, duplicate, copy to another board, remove, undo and redo, and autosave. Provide accessible alternatives to dragging or long pressing.

The visible actions should primarily be Add, Board controls, Use, and Print or Share. Avoid presenting global Settings, More Apps, rating prompts, or diagnostics as board-editing actions. Show meaningful empty, importing, saving, and error states without introducing artificial steps.

### Add cards

Bring Symbols, Photos, and Camera together through one Add entry point. Support multi-selection, a visible selection count, cancellation, progress, retry, and partial failures without losing valid selections. Photos must use the existing shared system picker by source reference. Keep the selected provider and its credits understandable. Preserve source attribution in persisted data and exports where required.

ARASAAC is currently enabled by default. Plus also exposes Dynavox and AI symbol creation. Audit actual target membership, flags, entitlements, configuration, and current behaviour before deciding how these integrations are exposed. The mockups' three source choices do not authorize silently removing existing variant capabilities. Keep AI secondary and optional; do not expose technical configuration or secrets in the main user flow.

### Card details

Combine picture, label, and voice settings in one place. Retain crop, background removal where supported, replacement, duplication, and reversible image edits. Imported symbols should supply editable labels. Inspect whether existing recorded audio can be edited or only played; preserve existing recordings regardless. If offering recording in the new UI, implement permission handling, recording, playback, cancellation, and persistence rather than a placeholder.

Keep voice source separate from the board's tap behaviour. A person should not have to guess whether tapping a card speaks, adds it to a message, or does both. Configure this clearly and consistently. Support appropriate voice language selection and the existing default, enhanced, and Personal Voice capabilities where available.

### Use board

Make this a quiet communication surface with large cards, clear feedback, and no editing clutter. Offer simple tap-to-speak and optional message building with Speak, remove-last, and Clear. Handle repeated cards, long messages, interruptions, missing media, and unavailable voices. Provide optional protection against accidental editing with an accessible exit; do not require an undiscoverable gesture.

Preserve learned card positions and groups during use. Device rotation or folding must not spontaneously reorder communication cards. Adapt controls and scale within usable limits; for dense boards, use intentional pagination or a configured layout rather than shrinking targets until they are unusable. Clear or retain the message on board changes according to one documented, understandable rule.

### Print and Share

Provide a faithful page preview and real Print, Share PDF, and Save image actions. Preserve paper size, page orientation, grid, margins, borders, background, board title, card labels, font settings, multi-page output, and repeat-single-card behaviour. Show actual page count and useful physical measurements. Respect source credits and long or translated labels.

Paper orientation is a document setting. Device rotation must never change it. The mockup shows only a simplified page; do not limit the real implementation to six cards or one page. Reuse sound rendering calculations behind clean interfaces if appropriate, but remove dependencies on UI navigation state.

### Settings and visual design

Use a small settings area for communication defaults, print defaults, accessibility preferences where needed, help, credits, and support. Preserve English and Spanish. Reuse the Boardlet name and existing brand assets where appropriate; favour native typography, neutral surfaces, restrained blue emphasis, and meaningful labels. The audience includes adults, families, and professionals as well as children.

Honor Dynamic Type, VoiceOver, Voice Control, Switch Control, Reduce Motion, contrast, dark appearance, and at least 44-point interactive targets. Do not encode state through colour alone. Keep labels readable and essential actions available without hover, drag, or context-menu discovery.

## Adaptive behaviour

Use available container space, size classes, safe areas, and standard navigation containers. Do not create separate device-specific apps or depend on `UIScreen.main`, a global orientation, or a single width threshold like the legacy 1024-point split decision.

| Context | Intended behaviour |
| --- | --- |
| iPhone portrait and Duo outer display | A single clear navigation stack; card details as a screen and short contextual tools as sheets. |
| iPhone landscape | Use the shorter height deliberately; show useful adjacent controls when they fit and allow content to scroll without losing primary actions. |
| Duo inner display | Board and related tools can sit together; the library remains available without forcing three cramped columns. |
| Duo folding and unfolding | Preserve the active board, edit session, selection, message, and focused task; use supported system handling for reserved areas and folds. |
| iPad portrait | Show a useful canvas with optional tools; collapse secondary navigation when it competes with the board. |
| iPad landscape | Optional Boards sidebar, board canvas, and inspector when space supports all three. |
| Narrow iPad window and large text | Collapse to fewer panes while retaining all functionality and navigation context. |

Editor and library grids may adapt freely. Communication layout stability needs separate rules. Likewise, screen layout and printed page layout must have separate state.

## Suggested internal structure

Create `Boardlet/Sources/App`, `Features/Boards`, `Features/BoardEditor`, `Features/CardPicker`, `Features/Communication`, `Features/PrintExport`, `Features/Settings`, `Domain`, `Persistence`, `Services`, `SharedUI`, and `Resources`, plus tests. Adjust boundaries pragmatically rather than creating empty abstraction layers.

Use explicit board and card models, persistent identifiers, separately modelled print and communication settings, and a versioned storage format. Keep navigation state outside persisted content models. Keep an editing session, an undo history, and communication session state distinct. Inject storage, importing, audio, and export dependencies so core behaviour can be tested without a running UI. Make disk writes atomic, expose save failures, and ensure cancellation or app backgrounding does not corrupt work.

## Existing code to inspect

| Purpose | Starting points relative to repository root |
| --- | --- |
| Active build membership and variants | `PECS Maker.xcodeproj/project.pbxproj`, shared schemes, `PECS Maker/Classes/FeatureFlags.swift` |
| Navigation and current workflows | `PECS Maker/Views/ContentView.swift`, `ContentViewIOS16Split.swift`, `Classes/NavigationModel.swift`, `Views/Pages/MainMenuView.swift` |
| Legacy board storage | `PECS Maker/Classes/Persistence/PECSRepo.swift`, `PECSRepoFactory.swift`, `PhotoBrowserData.swift`, `PhotoItem.swift`, `PECSPersistenceSettings.swift` |
| Layout and export | `PECS Maker/Classes/PageLayoutState.swift`, `CollageFactory.swift`, `CollageFormatting.swift`, `PageMeasurements.swift`, `Views/Pages/PagePreviewView.swift` |
| Import and editing | `Shared/SystemPhotoPicker/`, `PECS Maker/Extensions/SystemPhotoPickerPresenter.swift`, `View+selectPhotos.swift`, `View+selectSymbols.swift`, `Views/Pages/PhotoListView2.swift` |
| Audio and symbol services | `Packages/MediaFramework/`, `Packages/ARASAACSymbols/`, `Views/Pages/ChoiceBoardView.swift`, voice UI currently within `MainMenuView.swift` |
| Other local packages | `Packages/OpenSymbols/`, `Packages/AACStandardSymbols/`; existence does not prove production membership or readiness |
| Photos verification | `PhotoPickerHarness/README.md`, `Scripts/SystemPhotoPicker/README.md`, `TestSupport/SystemPhotoPicker/` |

Paths in this table are starting points, not an instruction to transplant entire classes. Confirm active references before using similarly named files or any ` 2.swift` file. Both current production schemes have `AppHasTopics`; do not infer single-board behaviour from old comments in an inactive Standard implementation.

## Data compatibility and app identity

The current apps use `com.brightblue.EasyPECS` and `com.brightblue.EasyPECSPlus`. Develop with distinct provisional bundle identifiers so the replacement can be installed alongside them. Do not replace the production installations, delete app containers, or switch release identities during initial development.

Plan explicitly for eventual upgrades under the existing identities. A different development bundle identifier does not automatically give access to an old app's sandbox. Use fixture copies or a deliberate import path for development. Do not promise automatic migration between separate app containers without a supported transfer mechanism.

The existing format includes `index.json`, nested board metadata and photo collections, image files, optional audio files, formatting, source attribution, and base-directory-dependent decoding. Inspect exact keys and formats. Some IDs appear to be regenerated in memory, so do not assume they are persisted. Preserve ordering, custom covers, edits, labels, recordings, formatting, and provider metadata.

Implement an explicit importer or migration adapter with version checks and fixtures. Treat originals as read-only, stage new files, validate before completing, and retain a recovery path. Test repeated import, interruption, missing or corrupt assets, old optional fields, and migration failure. A failure must not erase valid old data or silently create an empty replacement board.

## Delivery sequence

1. Inspect the live checkout, instructions, target configurations, and reusable services. Protect the existing work. Record architecture, storage, variant, and dependency decisions concisely.
2. Create the clean project and a buildable app. Establish the new models and storage, design foundations, adaptive navigation, and real Boards library. Create, rename, duplicate, delete, and reopen a board across launches.
3. Complete real card import and editing, using the shared Photos picker and available symbol services. Connect layout controls, bulk labels, undo, autosave, and error handling to persistent content.
4. Complete communication and audio, and real multi-page export and printing. Finish localization, accessibility, settings, template behaviour, and variant parity. Build migration and recovery alongside storage work, not as an afterthought.
5. Verify the whole app on the required sizes and orientations, inspect actual screenshots, fix failures, and provide exact commands and results. Keep a progress record in this directory so another thread can continue without reconstructing decisions.

Do not stop at scaffolding, a sample-data demo, disabled primary actions, or a list of next steps. Continue toward a usable full app. If an external integration is genuinely blocked by credentials, licensing, missing SDKs, or permissions, complete independent work and identify the exact limitation. Never embed secrets or fake successful operations.

## Verification and completion criteria

- Build and test the new project using the existing iPhone 18 Pro running iOS 27.0 as the default destination. Discover its current identifier rather than assuming it. Keep build output in ignored `.build` locations unless documented scripts require otherwise.
- Exercise iPhone and iPad portrait and landscape, narrow windows, large text, keyboard presentation, long Spanish labels, empty boards, and boards spanning multiple pages. Validate Duo poses and continuity when the required SDK and simulator are available; clearly report any unavailable coverage.
- Add meaningful tests for model edits, ordering, undo and redo, persistence, migration recovery, import state, and export pagination. Add focused UI coverage for critical workflows and adaptation, rather than tests that merely repeat implementation details.
- Test local functionality offline, audio interruptions, cancellation, loading and save errors, duplicate cards in a message, and repeated migration.
- If changing shared production code or project settings, build both `PECS Maker` and `Easy PECS Plus` and run relevant existing tests. Shared picker changes must use the documented harness and matrix runners. Do not duplicate the picker implementation.
- Never run historical `PECS MakerTests/SetupPhotos.swift` against a personal simulator or photo library. It deletes Photos database content directly. Use the documented disposable-device scripts when required.
- Review build-generated Info.plist version and SwiftGen changes separately from intentional edits. Preserve unrelated changes. Report exact build and test commands, results, and concrete verification gaps.
- Completion means all seven screen families are connected to real app behaviour and persisted data, legacy data has a validated compatibility path, supported variants and localizations are accounted for, and the requested adaptive layouts have evidence. Native platform validation cannot be replaced by screenshots of the HTML concepts.
