# Real screenshot validation — 27 October 2026

The six supplied originals were added to the **existing iPhone 18 Pro simulator, iOS 27.0**, UUID `BB33297D-F833-464B-B43D-14CBD0DA3021`. No Photos assets were deleted or replaced. Each screenshot was selected through Board Scanner's actual Photos picker, parsed, saved and inspected using the detection overlay. The shared repository picker driver was reused by source reference.

## Results

All six boards have **6 rows × 11 columns**. The saved iOS documents preserve occupied and empty positions exactly against the independently transcribed [expectations](Tests/Fixtures/screenshot-expectations.json).

| Photo | Board | Visible cards | Labels matching, ignoring case | Review flags |
| --- | --- | ---: | ---: | ---: |
| 1 | Animals | 28 | 28 | 0 |
| 2 | Descriptors | 60 | 60 | 2 |
| 3 | Places | 56 | 56 | 5 |
| 4 | Time | 58 | 58 | 1 |
| 5 | Home Page | 66 | 66 | 4 |
| 6 | Food & Drink | 28 | 28 | 0 |
| **Total** | | **296** | **296** | **12** |

Counts include card-shaped Home, navigation and category tiles within the board. The top toolbar and Speak/Clear/Delete/Share controls are excluded. Missing positions stay empty; they are not presented as editable cards.

**292 labels match case-sensitively.** Four have capitalization differences: `coW` versus `cow`, `Library` versus `library`, `Living room` versus `living room`, and `Like` versus `like`. No words are missing or substituted in the final saved outputs. Review flags remain visible for ambiguous picture text, low confidence or removed OCR punctuation; they should not be interpreted as failed label matches.

All six saved-image contact sheets were visually checked against the originals. Caption text is separated from the picture areas. Text that is part of an illustration, such as `NHS`, the large `a`, and `A-Z`, is retained. Minor source-background/rounded-corner pixels remain in some crops; extraction does not perform background removal or redraw the symbols.

## Problems found and fixed

The initial generated-fixture implementation did **not** parse these screenshots correctly. Its dark-line projections treated large blank regions and toolbar controls as grid boundaries; Food & Drink became two cards labelled Clear and sandwich pizza. Other boards lost rows or columns.

The fixes are generic image/geometry changes, with no screenshot-specific coordinate templates or label substitutions:

- Detect connected, filled card surfaces against the perimeter background before trying repeated edges and Vision rectangle/contour fallback. Group similarly sized cards into the lattice while preserving unoccupied positions.
- Retry missing/low-confidence OCR on an enlarged individual card. Vision's accurate recognizer omitted `is` and `it`; its fast recognizer recovered both.
- Preserve upper artwork text when a lower caption exists.
- Discard a standalone punctuation stroke before a readable caption, while retaining a review flag. iOS OCR returned `/ Feelings`; both separate-region and combined-region forms are now covered by a regression test.

## Native verification and retained evidence

Artifacts live at:

`/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27/`

- `Photos-validation-1.xcresult`: **all six real Photos-import UI tests passed**. The first complete label comparison found 295/296 matches, exposing `/ Feelings` despite passing transport/layout assertions.
- `Photos-descriptors-final-2.xcresult`: the affected Photos import passed again after the final punctuation fix, including a direct `Feelings` assertion. Its actual saved document replaced the earlier Descriptors result for the final comparison. The other five saved documents remain from the complete six-photo run.
- `Regression-final-2.xcresult`: **14 unit tests and 1 UI test passed, zero failures**, on the final code. Includes generated-image Vision tests, sparse-grid and punctuation regressions, and edit/save/relaunch UI verification.
- `food-final-native.png`: final native app screen, left open on the validated Food & Drink board using only the isolated test save slot. The ordinary user save was not overwritten.
- `ios-photo-1.boardscan` through `ios-photo-6.boardscan`: actual documents saved by the simulator after importing each original through Photos.
- `ios-final-comparison.json`: every-label, position and occupancy comparison; **296 matches ignoring case, zero mismatches under that criterion**. Casing differences are recorded separately.
- `ios-photo-1.png` through `ios-photo-6.png`: contact sheets rendered from those saved PNG crops and strings. These are extraction inspection artifacts, **not native app screenshots**.
- `photos-validation-1-evidence/` and `photos-descriptors-final-2-evidence/`: native Photos picker, reconstructed board and detection-overlay screenshots plus accessibility hierarchy attachments.
- `baseline/`, `surfaces/`, `refined/`, `final/`: diagnostic output from compiling the same parser sources as a macOS command-line program. These informed fixes; actual simulator saves above are the final label evidence.

[Animals crops](/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27/ios-photo-1.png) · [Descriptors crops](/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27/ios-photo-2.png) · [Places crops](/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27/ios-photo-3.png) · [Time crops](/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27/ios-photo-4.png) · [Home Page crops](/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27/ios-photo-5.png) · [Food & Drink crops](/Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27/ios-photo-6.png).

## Exact commands

Run from `/Users/andy/dev/PECSMaker`. The originals were added using:

```sh
xcrun simctl addmedia BB33297D-F833-464B-B43D-14CBD0DA3021 \
  /tmp/codex-remote-attachments/01a17a7b-47bc-71c2-98c4-cca273a18f71/03524B4E-C91D-4F55-A6FA-1B05E0BD957A/1-Photo-1.jpg \
  /tmp/codex-remote-attachments/01a17a7b-47bc-71c2-98c4-cca273a18f71/03524B4E-C91D-4F55-A6FA-1B05E0BD957A/2-Photo-2.jpg \
  /tmp/codex-remote-attachments/01a17a7b-47bc-71c2-98c4-cca273a18f71/03524B4E-C91D-4F55-A6FA-1B05E0BD957A/3-Photo-3.jpg \
  /tmp/codex-remote-attachments/01a17a7b-47bc-71c2-98c4-cca273a18f71/03524B4E-C91D-4F55-A6FA-1B05E0BD957A/4-Photo-4.jpg \
  /tmp/codex-remote-attachments/01a17a7b-47bc-71c2-98c4-cca273a18f71/03524B4E-C91D-4F55-A6FA-1B05E0BD957A/5-Photo-5.jpg \
  /tmp/codex-remote-attachments/01a17a7b-47bc-71c2-98c4-cca273a18f71/03524B4E-C91D-4F55-A6FA-1B05E0BD957A/6-Photo-6.jpg
```

Do not rerun addmedia on this simulator unnecessarily: it would create duplicates. The Photos labels were observed as `Photo, 27 October, 12:45` for exactly these six images, ordered newest-first (6, 5, 4, 3, 2, 1). The dedicated UI test deliberately asserts that group and checks parsed source identity after selection. A new seeding date/library requires updating the selection fixture from the actual picker hierarchy; this is not a generic personal-library selector.

```sh
xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerRealPhotos \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27/Photos-validation-1.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 90 \
  -test-timeouts-enabled YES test CODE_SIGNING_ALLOWED=NO

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScannerRealPhotos \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27/Photos-descriptors-final-2.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 90 \
  -test-timeouts-enabled YES \
  -only-testing:BoardScannerUITests/RealScreenshotUITests/testPhoto2Descriptors \
  test CODE_SIGNING_ALLOWED=NO

xcodebuild -project BoardScanner/BoardScanner.xcodeproj -scheme BoardScanner \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/DerivedData \
  -resultBundlePath /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27/Regression-final-2.xcresult \
  -parallel-testing-enabled NO -maximum-test-execution-time-allowance 90 \
  -test-timeouts-enabled YES test CODE_SIGNING_ALLOWED=NO

python3 BoardScanner/Scripts/compare-extractions.py \
  /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27 --ios
```

Use new result-bundle paths for future test runs. The comparison command exits 0 on the final six saved outputs.

The diagnostic CLI can be rebuilt without an Xcode project or copied app implementation:

```sh
xcrun swiftc -parse-as-library -swift-version 6 -target arm64-apple-macosx15.0 \
  BoardScanner/App/Analysis/*.swift \
  BoardScanner/App/Models/ScannedBoard.swift BoardScanner/App/Models/ScannedCard.swift \
  BoardScanner/App/Models/ScanError.swift BoardScanner/App/Models/GridOverride.swift \
  BoardScanner/App/Models/TextRegion.swift BoardScanner/Scripts/validate-screenshots.swift \
  -o /Volumes/Crucial-SSD-2TB/Developer/CodexWorktrees/PECSMaker/board-scanner/real-screenshots-2026-10-27/validate-screenshots
```

Pass an input image directory and output directory to that executable, then run `compare-extractions.py OUTPUT_DIRECTORY` without `--ios`. `render-validation.swift`, compiled with `ScannedBoard.swift`, `ScannedCard.swift` and `ScanError.swift`, accepts a `.boardscan` path and output PNG path to inspect its crops.

## Limits

This verifies the six supplied screenshots, not arbitrary AAC apps or photographed/perspective-distorted boards. Four capitalization differences remain editable. Dense boards scroll horizontally on the iPhone to keep each card readable; Detection shows the complete source. Labels can wrap or hyphenate at the current 100-point minimum card width (for example “breakfast”); the saved text is unchanged. Styles, navigation behavior and speech from the original AAC app are not reproduced. Tests used local simulator assets, not iCloud downloads, physical devices or iOS 16.6 runtime execution.
