# Independent Swift packages

All reusable packages are sibling repositories under `/Users/andy/dev`, alongside PECSMaker and BoardScanner. Xcode uses local relative package references for coordinated development. Each repository has its own Git history and private GitHub remote; commit and push package changes in that repository separately.

From the PECSMaker root run `bash documentation/Scripts/bootstrap-packages.sh` to clone missing siblings without modifying existing checkouts.

- [SystemPhotoPicker](https://github.com/andyc71/SystemPhotoPicker) → `../SystemPhotoPicker`
- [VoicePickerUI](https://github.com/andyc71/VoicePickerUI) → `../VoicePickerUI`
- [BoardLibrary](https://github.com/andyc71/BoardLibrary) → `../BoardLibrary`
- [AACStandardSymbols](https://github.com/andyc71/AACStandardSymbols) → `../AACStandardSymbols`
- [ARASAACSymbols](https://github.com/andyc71/ARASAACSymbols) → `../ARASAACSymbols`
- [OpenSymbols](https://github.com/andyc71/OpenSymbols) → `../OpenSymbols`
- [EngagementKit](https://github.com/andyc71/EngagementKit) → `../EngagementKit`
- [MediaFramework](https://github.com/andyc71/MediaFramework) → `../MediaFramework`

SystemPhotoPicker exports the app implementation and a separate XCTest helper product, SystemPhotoPickerTestSupport. The PhotoPickerHarness app and integration tests remain here. MediaFramework reuses its existing repository; the other package histories were extracted from this repository. Historical verification reports retain their original paths.

[Migration verification and exact commands](PackageExtractionVerification.md).
