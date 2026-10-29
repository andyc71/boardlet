# Shared What's New flow

As of 28 October 2026, both production apps use `../EngagementKit` for the entire What's New flow. See [EngagementKit integration](EngagementKit.md) for current policy and verification; the earlier FeatureFramework verification below is historical. Its `WhatsNewViewModel` owns loading and eligibility, and `whatsNewOverlay` owns the sheet, layout, sizing, and dismissal. See [the package guide](https://github.com/andyc71/EngagementKit#readme) for its public API and policy.

## App integration

`PECS_MakerApp` constructs the model after `StartupExperience.prepare` has identified a new or existing installation, before starter boards are installed. `BoardletRootView` retains the model and supplies readiness once welcome and its completion alerts have finished. Pending release notes block solicitations, and a shown release suppresses them for the entire process session. Blocked opportunities are discarded rather than queued.

`StartupExperience` now decides only welcome versus content. The app-owned `ReleaseNotes` loader and `StartupWhatsNewView` renderer have been removed. The old `startup.lastSeenVersion` key is read solely as one-time migration evidence; it is no longer updated or used as an ongoing display policy.

Both localized JSON files under `PECS Maker/Assets/WhatsNew` declare `releaseID: 2026-10-ios27`. Use the same ID across languages. A fresh installation baselines that ID silently. An existing user's unseen ID appears until Continue is pressed. Subsequent copy, locale, marketing-version or build-number changes do not re-present it; publish a new releaseID for a new announcement.

Migration preserves the old package's `lastDisplayedFeatureSet` date. For PECSMaker, a saved `startup.lastSeenVersion` matching the current marketing version marks the current release seen; an older saved version leaves it eligible. The app version record takes precedence over an older date record. Existing app data without either record is eligible. All these decisions live in EngagementCore and run only before its own state is initialized.

## Layout

The package keeps the current theme, single-column portrait layout, compact-height two-column layout, and pinned footer. Accessibility text sizes use a single scrollable column with footer text in the scroll area and only Continue pinned. The package retains iOS 15 support with a standard sheet; iOS 16+ adds fitted detents using `onGeometryChange`. All What's New entry points use the same renderer. Voting shares the feature row component and now uses the EngagementKit campaign policy.

## Historical FeatureFramework verification

Use the existing iPhone 18 Pro by default. For this run the default device was concurrently controlled by BoardScanner tests (focus and orientation changed mid-test), so UI verification uses the existing **Boardlet iPhone 18 Pro**, `F07A3387-2B7B-40E5-8B4A-576062F5A9DC`, on iOS 27.0. No simulator was created or erased.

Build output and logs are under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/`.

Package tests require a workspace that exposes the package as a root while retaining the app's existing local dependency overrides. `FeatureFrameworkVerification.xcworkspace/contents.xcworkspacedata` in that output directory contains:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Workspace version="1.0">
  <FileRef location="absolute:/Users/andy/dev/PECSMaker/PECS Maker.xcodeproj"/>
  <FileRef location="absolute:/Users/andy/dev/FeatureFramework"/>
</Workspace>
```

Run from the PECSMaker repository root:

```sh
xcodebuild -workspace /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/FeatureFrameworkVerification.xcworkspace -scheme FeatureFramework -configuration Debug -destination 'platform=iOS Simulator,id=F07A3387-2B7B-40E5-8B4A-576062F5A9DC' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -parallel-testing-enabled NO -collect-test-diagnostics never test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -configuration Debug -destination 'platform=iOS Simulator,id=F07A3387-2B7B-40E5-8B4A-576062F5A9DC' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan 'PECS Maker' -parallel-testing-enabled NO -collect-test-diagnostics never BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:PECS MakerTests/StartupExperienceTests' '-only-testing:PECS MakerUITests/WhatsNewUITests' '-only-testing:PECS MakerUITests/StartupUITests/testBlankWelcomeOpensEditorAndPersistsAcrossLaunches' '-only-testing:PECS MakerUITests/StartupUITests/testExistingUserSeesReleaseNotesOnce' test

xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -configuration Debug -destination 'platform=iOS Simulator,id=F07A3387-2B7B-40E5-8B4A-576062F5A9DC' -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/whats-new/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan 'Easy PECS Plus' -parallel-testing-enabled NO -collect-test-diagnostics never BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts '-only-testing:Easy PECS Plus UI Tests/WhatsNewUITests' '-only-testing:Easy PECS Plus UI Tests/StartupUITests/testBlankWelcomeOpensEditorAndPersistsAcrossLaunches' '-only-testing:Easy PECS Plus UI Tests/StartupUITests/testExistingUserSeesReleaseNotesOnce' test
```

### Results — 28 October 2026

All three commands above completed with `TEST SUCCEEDED` on the existing Boardlet iPhone 18 Pro (iOS 27.0):

- FeatureFramework: 14 XCTest tests and seven Swift Testing tests (14 parameterized cases), zero failures. Log: `final-0.log`; result: `Test-FeatureFramework-2026.10.28_11-04-09-+0000.xcresult`.
- PECS Maker: nine startup unit tests and four UI tests, zero failures. Log: `final-1.log`; result: `Test-PECS Maker-2026.10.28_10-56-16-+0000.xcresult`.
- Easy PECS Plus: four UI tests, zero failures. Log: `final-2.log`; result: `Test-Easy PECS Plus-2026.10.28_11-01-09-+0000.xcresult`.

Result bundles are in `DerivedData/Logs/Test` under the output directory above. Standard-app screenshots are in `verified-screenshots`; its manifest names the portrait, landscape and accessibility captures. Plus now includes the same What's New UI test source by target membership.

Verification corrected a stale first-install editor identifier and an accessibility layout issue: footer text now scrolls at accessibility sizes while Continue stays pinned. Earlier failed runs and an interrupted package diagnostics collection are superseded by these completed runs. Build-generated CFBundleVersion increments were restored to their pre-run values. Minimum supported OS versions were retained but were not runtime-tested on older simulators in this run.
