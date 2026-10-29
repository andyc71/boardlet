# Documentation table of contents

Start here before changing the app. Reviewed against the working checkout on **24 October 2026**. Paths in commands are relative to the repository root unless a guide says otherwise.

`PECS Maker.xcodeproj` contains the production `PECS Maker` and `Easy PECS Plus` schemes; the Standard app is branded Boardlet. `Boardlet/Boardlet.xcodeproj` is a separate development rebuild, not the shipping project. Both retain iOS 16.6 deployment support.

## Production guides and tooling

The former root `Scripts/` directory now lives in **`documentation/Scripts/`**, including its executable tools. Update local command aliases accordingly. The harness's `PhotoPickerHarness/Scripts/` and rebuild's `Boardlet/Scripts/` remain with their own projects.

| Guide | Contents |
| --- | --- |
| [Board editor](Scripts/BoardEditor/README.md) | Current rendering/viewport behavior, focused test plans and dated implementation results. |
| [EngagementKit](EngagementKit.md) | Shared ratings, voting/feedback, What’s New and optional TipKit policy, migration and verification. |
| [What’s New](WhatsNew.md) | Release content, migration, presentation and historical verification. |
| [Classic interface](Scripts/ClassicInterface/README.md) | Interface preference, ownership, removal boundaries and phone/iPad test plans. |
| [Multilingual boards](Scripts/MultilingualBoards/README.md) | Version-3 saves with v1/v2 reads, language fallback, starter migration/restore and conversion tool. |
| [Board hierarchy and search](BoardHierarchyAndSearch/README.md) | Nested-board storage, lazy catalogue, indexed multilingual search, implementation contract and current verification status. |
| [System Photos picker](Scripts/SystemPhotoPicker/README.md) | Shared production integration, disposable simulator matrix, reusable builds and result validation. |
| [App Store captures and exports](Scripts/AppStoreScreenshots/README.md) | Fastlane/XCTest captures, attachment import, October artwork renderer and gallery packaging. |
| [Screenshot-board tools](Scripts/ScreenshotBoards/README.md) | Symbol extraction/preparation and catalog packaging into production starter resources. |
| [ARASAAC symbol search](ARASAAC-symbol-search.md) | Both-target integration, selection, attribution and contextual suggestions. |
| [OpenSymbols client](OpenSymbols-symbol-search.md) | Standalone client, token-service boundary and tests; not linked into production. |
| [Duo readiness](iPhone-Duo-readiness-audit.md) | Implemented changes since the original audit and remaining transition validation. |

## Separate Boardlet rebuild

| Document | Contents and status |
| --- | --- |
| [Project entry point](../Boardlet/README.md) | Development identities, project generation and build commands. |
| [Progress](BoardletRebuild/PROGRESS.md) | Implementation and integration record; results date from 2 October. |
| [Upgrade path](BoardletRebuild/UPGRADE-PATH.md) | Recovery and identity boundaries. **Importer accepts version 1 only; current multilingual version 2 is unsupported.** |
| [Verification](BoardletRebuild/VERIFICATION.md) | Exact historical commands, retained native screenshots, test summary and coverage gaps. |
| [Original design brief](BoardletRebuild/HANDOFF.md) | Historical requirements and acceptance criteria; do not restart completed creation steps. |
| [Seven-screen concepts](BoardletRebuild/mockups/boardlet-workspaces.html) | Interactive design reference, not native implementation evidence. |
| [iPad landscape concepts](BoardletRebuild/mockups/boardlet-ipad-landscape.html) | Landscape design reference. |

## Historical records

- [Photos migration results, September 2026](Scripts/SystemPhotoPicker/RESULTS.md): the former 62-case production suite, not the current runner's expected inventory.
- [Pre-Classic checkpoint, 9 October](Scripts/ClassicInterface/CHECKPOINT.md): historical commit references, not current dependency pins.
- Editor follow-up results are dated within the [editor guide](Scripts/BoardEditor/README.md).

Historical results do not verify current uncommitted code. References to ignored `.build` or temporary result bundles may not exist in another checkout. The obsolete rebuild working-tree status dumps were removed; inspect live `git status` instead.

## Related documentation retained beside its owner

- [Board Scanner communication layout and source colours](../BoardScanner/COMMUNICATION-LAYOUT.md): compact communication controls, exported grid sizing and colours, symbol transparency, compatibility and focused simulator verification.
- [Repository instructions](../AGENTS.md).
- [Board Scanner](../BoardScanner/README.md): standalone screenshot-to-choice-board app with AAC speech and accessible cancellation, keyboard and scanning access, viewport-bounded communication layouts and large-text speech controls, message correction and reusable phrases, native board/page/button authoring, picture and link editing, and a recoverable multi-board library, TD Snap page-set hierarchy import with native WMF/EMF artwork rendering and remembered symbol libraries for automatic artwork recovery, Vision detection/OCR, crop review and verification.
- [Photo picker harness](../PhotoPickerHarness/README.md) and [historical harness validation](../PhotoPickerHarness/VALIDATION.md).
- [Screenshot board catalog](../ScreenshotBoards/README.md) and [catalog verification](../ScreenshotBoards/VERIFICATION.md).
- [Screenshot editor](../AppStoreScreenshots/README.md) and [end-to-end testing](../AppStoreScreenshots/docs/testing/e2e.md).
- [ARASAAC package](../Packages/ARASAACSymbols/README.md), [OpenSymbols package](../Packages/OpenSymbols/README.md), [MediaFramework](../Packages/MediaFramework/README.md), [AAC Standard](../Packages/AACStandardSymbols/README.md) and [its integration guide](../Packages/AACStandardSymbols/INTEGRATION.md).
- [Fastlane](../fastlane/README.md).

Update the relevant guide and this index when workflows or document locations change. Keep historical verification explicitly dated, and record new commands/results rather than silently relabelling old passes.

- [Shared voice picker](../Packages/VoicePickerUI/README.md): shipping Boardlet and Board Scanner voice selection, previews and localized help.
