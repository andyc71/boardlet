# Boardlet+ integration verification

Run from `/Users/andy/dev/PECSMaker`. These commands use the existing iPhone 18 Pro, iOS 27.0 simulator and cached dependency checkouts. `BOARDLET_PACKAGE_CHECKOUTS` overrides the UI test targets' default location to match `-clonedSourcePackagesDirPath`. Build artifacts remain under the package's ignored `.build` folder.

The Plus target alone links AACStandardSymbols. All imports, picker presentations, source buttons, and Settings credit entries are guarded by `EasyPECSPlus`. The shared persistence schema can decode AAC Standard provenance in either app variant. English and Spanish strings were regenerated with SwiftGen.

## Boardlet+ build

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath Packages/AACStandardSymbols/.build/production \
  -clonedSourcePackagesDirPath /Users/andy/Library/Developer/Xcode/DerivedData/PECS_Maker-gckgzretvnrfnscmrgvkuwgkoizh/SourcePackages \
  -disableAutomaticPackageResolution build CODE_SIGNING_ALLOWED=NO
```

Result: passed.

## Boardlet+ UI tests

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath Packages/AACStandardSymbols/.build/production \
  -clonedSourcePackagesDirPath /Users/andy/Library/Developer/Xcode/DerivedData/PECS_Maker-gckgzretvnrfnscmrgvkuwgkoizh/SourcePackages \
  -disableAutomaticPackageResolution \
  -parallel-testing-enabled NO \
  '-only-testing:Easy PECS Plus UI Tests/PECS_MakerUITests/testAACStandardAvailabilityIsPlusOnly' \
  '-only-testing:Easy PECS Plus UI Tests/PECS_MakerUITests/testAACStandardTopicPickerIsPlusOnly' \
  test CODE_SIGNING_ALLOWED=NO \
  BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/Library/Developer/Xcode/DerivedData/PECS_Maker-gckgzretvnrfnscmrgvkuwgkoizh/SourcePackages/checkouts
```

Result: 2 tests passed. Covers empty-board search, Add menu, topic-image picker, disabled Add with no selection, and cancellation preserving board contents.

## Standard Boardlet and shared persistence tests

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath Packages/AACStandardSymbols/.build/production \
  -clonedSourcePackagesDirPath /Users/andy/Library/Developer/Xcode/DerivedData/PECS_Maker-gckgzretvnrfnscmrgvkuwgkoizh/SourcePackages \
  -disableAutomaticPackageResolution \
  -parallel-testing-enabled NO \
  '-only-testing:PECS MakerTests/PhotoItemTests/testAACStandardSourceSurvivesCopyPersistenceAndImageEdit' \
  '-only-testing:PECS MakerTests/PhotoItemTests/testAACStandardTopicImageSourcePersists' \
  '-only-testing:PECS MakerTests/PhotoItemTests/testAACStandardCreditIsIncludedInPrintableBoard' \
  '-only-testing:PECS MakerTests/PhotoItemTests/testLegacySymbolSourceDecodesWithoutOptionalMetadata' \
  '-only-testing:PECS MakerTests/PhotoItemTests/testARASAACSourceSurvivesCopyPersistenceAndImageEdit' \
  '-only-testing:PECS MakerTests/PhotoItemTests/testARASAACTopicImageSourcePersists' \
  '-only-testing:PECS MakerTests/PhotoItemTests/testARASAACAttributionIsIncludedInPDFExport' \
  '-only-testing:PECS MakerUITests/PECS_MakerUITests/testAACStandardAvailabilityIsPlusOnly' \
  '-only-testing:PECS MakerUITests/PECS_MakerUITests/testAACStandardTopicPickerIsPlusOnly' \
  test CODE_SIGNING_ALLOWED=NO \
  BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/Library/Developer/Xcode/DerivedData/PECS_Maker-gckgzretvnrfnscmrgvkuwgkoizh/SourcePackages/checkouts
```

Result: passed. Standard Boardlet built successfully; all 7 persistence/export tests and 2 UI exclusion tests passed. In total, 11 focused app tests passed across both schemes.

These focused tests do not run the historical SetupPhotos test or modify the Photos library. UI tests use their existing isolated test-board storage. The metadata tests exercise source preservation through copy/save/reload, image edits, topic persistence, legacy decoding, and printed-board credit. ARASAAC tests cover the existing provider's persistence and PDF attribution.

UI integration tests open and cancel the real picker without contacting the remote service. Search, pagination, downloads, and cancellation have deterministic package test coverage; these app tests do not validate a live search-and-add transaction.
