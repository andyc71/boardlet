# Package extraction verification — 29 October 2026

Run from `/Users/andy/dev/PECSMaker`. These are the migration checks, not a claim that every app test suite was run. Physical-device and VoiceOver activation checks were not run.

## production — BUILD SUCCEEDED

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "PECS Maker" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts build CODE_SIGNING_ALLOWED=NO
```

## plus — BUILD SUCCEEDED

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "Easy PECS Plus" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts build CODE_SIGNING_ALLOWED=NO
```

## boardlet — BUILD SUCCEEDED

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Boardlet/Boardlet.xcodeproj -scheme Boardlet -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/package-extraction/BoardletDerivedData build CODE_SIGNING_ALLOWED=NO
```

## boardlet-plus — BUILD SUCCEEDED

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project Boardlet/Boardlet.xcodeproj -scheme BoardletPlus -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/package-extraction/BoardletDerivedData build CODE_SIGNING_ALLOWED=NO
```

## scanner — BUILD SUCCEEDED

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project /Users/andy/dev/BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/package-extraction/ScannerDerivedData build CODE_SIGNING_ALLOWED=NO
```

## picker-harness — TEST SUCCEEDED

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project PhotoPickerHarness/PhotoPickerHarness.xcodeproj -scheme PhotoPickerHarness -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/package-extraction/HarnessDerivedData -parallel-testing-enabled NO -collect-test-diagnostics never "-only-testing:PhotoPickerHarnessTests" test CODE_SIGNING_ALLOWED=NO
```

## scanner-ui — TEST SUCCEEDED

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project /Users/andy/dev/BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/package-extraction/ScannerDerivedData -parallel-testing-enabled NO "-only-testing:BoardScannerUITests/SpeechStripUITests/testSharedVoicePickerSelectionAndPreview" test CODE_SIGNING_ALLOWED=NO
```

## Photos UI — TEST SUCCEEDED

Both selected tests passed on a disposable iPhone 18 Pro simulator; it was deleted by the runner.

```sh
RUN_DIR=/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/package-extraction/PickerUI RUNTIME=com.apple.CoreSimulator.SimRuntime.iOS-27-0 DEVICE_TYPE=com.apple.CoreSimulator.SimDeviceType.iPhone-18-Pro bash PhotoPickerHarness/Scripts/test.sh "-only-testing:PhotoPickerHarnessUITests/RealPickerTests/testOpenCancel" "-only-testing:PhotoPickerHarnessUITests/RealPickerTests/testSelectAndImport" CODE_SIGNING_ALLOWED=NO
```

## BoardLibrary — 34 tests passed

```sh
swift test --package-path /Users/andy/dev/BoardLibrary --scratch-path /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/package-extraction/BoardLibraryTests
```

## AACStandardSymbols — 26 tests passed

```sh
swift test --package-path /Users/andy/dev/AACStandardSymbols --scratch-path /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/package-extraction/AACStandardTests
```

## Production audio with Thread Sanitizer — failed

The native speech-start/cancellation test crashed with `ThreadSanitizer:DEADLYSIGNAL` and a read SEGV. The test runner restarted, and the other 15 tests passed. This run is not a passing sanitizer check.

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "PECS Maker" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan "PECS Maker" -parallel-testing-enabled NO -collect-test-diagnostics never BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts "-only-testing:PECS MakerTests/AudioHelperTests" test CODE_SIGNING_ALLOWED=NO
```

## Production audio without Thread Sanitizer — 16 tests passed

```sh
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project "PECS Maker.xcodeproj" -scheme "PECS Maker" -configuration Debug -destination "platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021" -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/engagement/DerivedData -clonedSourcePackagesDirPath .build/board-editor/DerivedData/SourcePackages -skipPackageUpdates -skipMacroValidation -testPlan "PECS Maker" -parallel-testing-enabled NO -enableThreadSanitizer NO -collect-test-diagnostics never BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/board-editor/DerivedData/SourcePackages/checkouts "-only-testing:PECS MakerTests/AudioHelperTests" test CODE_SIGNING_ALLOWED=NO
```

Logs are archived under `/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/package-extraction/logs`. Build-number increments generated by Xcode were reverted; unrelated pre-existing Finder metadata was preserved.
