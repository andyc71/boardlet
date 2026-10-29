# EngagementKit integration

As of 28 October 2026, the production `PECS Maker` (Boardlet) and `Easy PECS Plus` targets use the independent [EngagementKit package](https://github.com/andyc71/EngagementKit#readme). Both remain on iOS 16.6. The separate Boardlet rebuild and BoardScanner are outside this change.

## App ownership

`PECS_MakerApp` creates one `EngagementCoordinator`, plus the voting and What's New models that share it. The app supplies conservative default policy, the marketing version, and existing launch flags that disable automatic ratings or voting for tests. Ordinary debug launches no longer reset rating history or lower its threshold.

The root owns the sole voting/mail presentation host. `TopicSelectionView` renders invitations **inside the library scroll view**, rather than an app-wide overlay. On library entry, it waits for scene attachment and supplies current navigation, selection, startup, modal and UIKit presentation facts. Returning from a modal does not create a new opportunity. A hidden or editing split-view library cannot solicit. What's New retains its own adaptive renderer and release-ID migration.

`PagePreviewView` and `ClassicPreviewAndPrintView` record successful UIActivity completions and photo-library exports; the modern preview also records confirmed system-print completion. `PhotoListView2` records completed board sharing. Cancellation and errors do not count. Operation UUIDs prevent duplicate callbacks from adding progress twice. Opening a share sheet, changing formatting, choosing photos, appearing and navigating no longer add engagement credit. Closing a success alert does not trigger a review prompt.

Settings exposes explicit feature voting, the App Store review page and separate private feature-request/problem-report mail. Explicit actions remain available on a fresh install and suppress automatic follow-ups. The Love It/Needs Work pre-screen and automatic legacy RatingFramework state machine are no longer linked or invoked. Inactive historical duplicate sources are left alone.

## History and content

See the package guide for the full defaults and migration contract. Current voting JSON declares `campaignID: boardlet-feature-priorities-2026` in both languages. Do not change this for copy/date changes. Existing dismissals and votes bind to this campaign once. What's New continues to use `releaseID: 2026-10-ios27` and the original seen-release keys. Each installed app uses its own defaults store.

The optional TipKit module is compiled by package verification but is not linked into the production umbrella product. Existing inline help stays available on iOS 16; this task adds no tour.

## Test fixtures

`PECS_TEST_ENGAGEMENT=fresh|eligible|legacyDismissed` seeds explicit integration scenarios in DEBUG only, and only when a `-mfDocDoc:<isolated library>` argument is present. Omit that variable on relaunch to test persistence. These fixtures do not change production policy thresholds. `FeatureVotingUITests` replaces the obsolete five-navigation-events assumption with fresh-install, eligible-inline, persisted-dismissal, legacy-migration, What's New suppression and explicit-voting checks.

## Exact verification commands

Run from `/Users/andy/dev/PECSMaker`. Use the existing iPhone 18 Pro, iOS 27.0, `BB33297D-F833-464B-B43D-14CBD0DA3021`. Build outputs stay on the external SSD. No device is created or erased. Package tests need a workspace exposing the package as a root while retaining the app's local dependency overrides:

```xml
<!-- /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/EngagementVerification.xcworkspace/contents.xcworkspacedata -->
<Workspace version="1.0">
  <FileRef location="absolute:/Users/andy/dev/PECSMaker/PECS Maker.xcodeproj"/>
  <FileRef location="absolute:/Users/andy/dev/EngagementKit"/>
</Workspace>
```

The package includes its shared `EngagementKit` Xcode scheme with the test target explicitly configured.

```sh
xcodebuild -workspace /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/EngagementVerification.xcworkspace -scheme EngagementKit -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -parallel-testing-enabled NO -collect-test-diagnostics never test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan 'PECS Maker' -parallel-testing-enabled NO -collect-test-diagnostics never BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:PECS MakerTests/StartupExperienceTests' '-only-testing:PECS MakerUITests/FeatureVotingUITests' '-only-testing:PECS MakerUITests/WhatsNewUITests' '-only-testing:PECS MakerUITests/StartupUITests/testBlankWelcomeOpensEditorAndPersistsAcrossLaunches' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan 'Easy PECS Plus' -parallel-testing-enabled NO -collect-test-diagnostics never BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:Easy PECS Plus UI Tests/FeatureVotingUITests' '-only-testing:Easy PECS Plus UI Tests/WhatsNewUITests' '-only-testing:Easy PECS Plus UI Tests/StartupUITests/testBlankWelcomeOpensEditorAndPersistsAcrossLaunches' test
```

The completed results below supersede earlier failed development iterations. Logs live under the `engagement` output directory; result bundles are in `DerivedData/Logs/Test`. Simulator tests verify app integration and package behavior, not Apple displaying/submitting a review or physical printer output. Minimum-version deployment settings are retained; an iOS 16 runtime is not installed for runtime verification.


## Results — 28 October 2026

All final commands completed with `TEST SUCCEEDED` on the existing iPhone 18 Pro, iOS 27.0:

| Run | Result | Log | Result bundle |
| --- | --- | --- | --- |
| Package, including optional TipKit compilation | 24 Swift Testing tests in 4 suites, including parameterized cases; zero failures | `verified-package.log` | `Test-EngagementKit-2026.10.28_18-43-38-+0000.xcresult` |
| Boardlet full selected regression suite | 9 startup unit tests and 8 UI tests; zero failures | `final-standard.log` | `Test-PECS Maker-2026.10.28_18-32-12-+0000.xcresult` |
| Easy PECS Plus full selected regression suite | 8 UI tests; zero failures | `final-plus-2.log` | `Test-Easy PECS Plus-2026.10.28_18-37-50-+0000.xcresult` |
| Boardlet final targeted control checks | 2 UI tests; zero failures | `verified-standard.log` | `Test-PECS Maker-2026.10.28_18-44-18-+0000.xcresult` |
| Easy PECS Plus final targeted control checks | 2 UI tests; zero failures | `verified-plus.log` | `Test-Easy PECS Plus-2026.10.28_18-45-48-+0000.xcresult` |

The final targeted checks cover inline invitation dismissal across relaunch and actual user-initiated feature voting. They validate the final contrast, 44-point control targets and button accessibility changes after the broader regression passes. Final package tests additionally cover migration of the shared voting cooldown for ratings-only clients. StoreKit requests are tested with an injected action, verifying that the attempt is recorded before invocation; no test claims a submitted or displayed App Store review.

Exact targeted follow-up commands (the package command is unchanged from above):

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -parallel-testing-enabled NO -collect-test-diagnostics never -testPlan 'PECS Maker' BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:PECS MakerUITests/FeatureVotingUITests/testEligibleInvitationIsInlineAndDismissalSurvivesRelaunch' '-only-testing:PECS MakerUITests/FeatureVotingUITests/testUserInitiatedVotingRemainsAvailableOnFreshInstall' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -parallel-testing-enabled NO -collect-test-diagnostics never -testPlan 'Easy PECS Plus' BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:Easy PECS Plus UI Tests/FeatureVotingUITests/testEligibleInvitationIsInlineAndDismissalSurvivesRelaunch' '-only-testing:Easy PECS Plus UI Tests/FeatureVotingUITests/testUserInitiatedVotingRemainsAvailableOnFreshInstall' test

```

Visual verification inspected the final Boardlet inline invitation capture in `verified-standard-attachments/A605BF5A-C28A-463C-9F08-CC99FF667582.png` under the output directory. It is inside the library, with black controls on yellow and a separate dismiss button. Release-note portrait, landscape and accessibility journeys passed in both apps.

Removing legacy wrapper dependencies exposed direct SettingsFramework and LogFrameworkFirebase requirements; the project now declares them explicitly for the affected targets. The final app graphs do not link RatingFramework or FeatureFramework. Earlier package-scheme, target-dependency and UI-fixture/identifier failures were corrected and are superseded by the successful runs listed above.

`git diff --check` passed. Build-generated version increments were removed by counting this task's Increment Build Number script executions, preserving pre-existing and concurrent unrelated edits. No source checkout was copied, no simulator was created or erased, and BoardScanner work was not changed.
