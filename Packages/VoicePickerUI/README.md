# VoicePickerUI

Reusable iOS 16+ SwiftUI voice-selection sheet extracted from shipping Boardlet's Change Voice UI. Consumed by both production targets (`PECS Maker` and `Easy PECS Plus`) and Board Scanner. The separate `Boardlet/` development rebuild is not the source of this picker.

The sheet includes language selection, system default, premium recommendations, voices grouped by locale, preview buttons, Personal Voice authorization/help (iOS 17+), and illustrated additional-voice installation help. English and Spanish strings are package resources. Existing Boardlet accessibility identifiers remain stable.

Pass bindings for the selected voice identifier and locale, and closures for default-voice resolution, preview playback and stopping previews. An empty identifier means system default. An empty locale means the environment's language. Host apps own persistence and audio policy; the package has no third-party dependencies. Hosts must supply `NSPersonalVoiceUsageDescription` to request Personal Voice access.

Boardlet retains its existing AppStorage keys and AudioHelper playback. Board Scanner stores an optional voice locale alongside its existing settings (older archives decode without that field) and uses SpeechController for preview and playback.

## Standalone Board Scanner

Board Scanner moved to [its own repository](https://github.com/andyc71/BoardScanner) and `/Users/andy/dev/BoardScanner` on 29 October 2026. It consumes this package through a pinned Boardlet submodule; the package remains maintained here. The commands below record pre-move verification.

## Verification, 28 October 2026

Board Scanner UI coverage: `SpeechStripUITests/testSharedVoicePickerSelectionAndPreview` exercises opening the sheet, language controls, selecting default, previewing without changing selection, and dismissal. Physical-device Personal Voice authorization is not exercised.

Build commands (run from repository root):

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination 'generic/platform=iOS Simulator' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-aac-audit/SEDerivedData build CODE_SIGNING_ALLOWED=NO
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'generic/platform=iOS Simulator' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts build CODE_SIGNING_ALLOWED=NO
```

The second production build uses the identical command with scheme `Easy PECS Plus`. Board Scanner's UI command uses the first command's project, scheme and DerivedData, destination `platform=iOS Simulator,id=EB5F9DF7-146D-4F70-9527-EC65EC70583A`, `-parallel-testing-enabled NO -collect-test-diagnostics never -only-testing:BoardScannerUITests/SpeechStripUITests/testSharedVoicePickerSelectionAndPreview test CODE_SIGNING_ALLOWED=NO`, and result bundle `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner-communication-layout/Shared-Voice-1.xcresult`. It passed.

All three builds passed (Board Scanner, PECS Maker / Boardlet, Easy PECS Plus). Board Scanner selection/preview/dismissal UI test passed. Build-generated CFBundleVersion changes in production plists are not part of the voice-picker behavior.

The standard target's existing `PECS_MakerUITests/testChoiceBoardVoicePicker` was skipped because Choice Board is Plus-only. Exact attempted command:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan 'PECS Maker' -parallel-testing-enabled NO -collect-test-diagnostics never BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:PECS MakerUITests/PECS_MakerUITests/testChoiceBoardVoicePicker' test CODE_SIGNING_ALLOWED=NO
```

The Plus rerun passed: **1 test, 0 failures, 0 skips, exit 0**. It uses the exact preceding command with scheme/test plan `Easy PECS Plus` and selection `-only-testing:Easy PECS Plus UI Tests/PECS_MakerUITests/testChoiceBoardVoicePicker`. This verifies the existing language/default/preview/help/voice-selection flow after extraction.
