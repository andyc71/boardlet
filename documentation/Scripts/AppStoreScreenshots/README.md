# App Store screenshot exports

The current app is branded **Boardlet** (production scheme `PECS Maker`).
Artwork uses the app's Baloo 2 Bold font, app icon and asset colours. Screens
are real simulator captures from bundled default boards, with no Photos imports.

Run all commands from the repository root. The scripts in this folder produce the fixed October 2026 artwork set; [AppStoreScreenshots](../../../AppStoreScreenshots/README.md) documents the separate screenshot editor.

## Capture

### Fastlane localized captures

`fastlane/Snapfile` captures iPhone 18 Pro, iPhone 18 Pro Max, iPad Pro 13-inch
(M5), and iPhone Duo in English and Spanish. Each device uses its newest
installed simulator runtime; Duo needs iOS 27.1. Devices and XCTest run
sequentially, without opening Simulator windows.

```sh
FASTLANE_XCODEBUILD_SETTINGS_TIMEOUT=120 bundle exec fastlane snapshot \
  --output_directory screenshots/Fastlane-2026-10-19 \
  --clear_previous_screenshots true \
  --derived_data_path .build/FastlaneScreenshots \
  --skip_package_dependencies_resolution true \
  --xcargs '-parallel-testing-enabled NO -jobs 4 -collect-test-diagnostics never ENABLE_THREAD_SANITIZER=NO'
```

Omit `--skip_package_dependencies_resolution true` on a first build. Use a
dedicated output directory: clearing screenshots removes previous PNGs inside
that directory. This runs Fastlane's capture action without the lane's separate
device-frame rendering step.

The screenshot scheme captures the current board library, board editor, layout
sheet, print preview, and dark-mode library from the production `Resources/StarterBoards` catalog (24 boards with shared images and English/Spanish string tables).
The editor and preview feature “Greetings” / “Saludos”; legacy Fruit/demo topics
are excluded. Both UI-test targets reference the production catalog directly.
It does not use the legacy Classic-interface journeys or modify Photos.
Duo captures use the simulator's active display; changing its fold state is
required for a separate inner-display capture.

### Attachment-based captures

The focused `ScreenshotTopicsScreenTests/testAppStoreMarketingScreens` test
captures the board library, Greetings / Saludos board, layout sheet and print preview. It
uses an isolated temporary repository and the default modern interface.
The screenshot test plan disables Thread Sanitizer because sanitizer startup
failed on the installed simulator runtime.

Run from the repository root:

```sh
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' \
  -testPlan 'Easy PECS Screenshots' -configuration Debug \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -derivedDataPath .build/DerivedData -disableAutomaticPackageResolution \
  -enableThreadSanitizer NO -parallel-testing-enabled NO \
  '-only-testing:PECS MakerUITests/ScreenshotTopicsScreenTests/testAppStoreMarketingScreens' \
  -resultBundlePath .build/AppStore-iPhone-New.xcresult \
  ENABLE_THREAD_SANITIZER=NO test
```

For subsequent devices use `test-without-building`, a fresh result bundle,
and the corresponding destination. Use the existing simulators:

- iPhone 18 Pro: `BB33297D-F833-464B-B43D-14CBD0DA3021`
- iPad Pro 13-inch (M5): `E4B44237-C067-4F3E-881A-58024523D11F`
- iPhone Duo: `A6BB8AD2-DBB8-4B88-BB65-C1850770A270`

Export and import captures:

```sh
xcrun xcresulttool export attachments \
  --path .build/AppStore-iPhone-New.xcresult \
  --output-path .build/AppStore-iPhone-New-export
python3 documentation/Scripts/AppStoreScreenshots/import-captures.py \
  .build/AppStore-iPhone-New-export iphone
```

Import device keys are `iphone`, `ipad`, `duo-outer`, and `duo-inner`. Capture
Duo's actual inner and outer screens separately; do not substitute an iPad
capture for its inner display.

## Render

`render.cjs` requires Node.js with `playwright` and `sharp`. Set `NODE_PATH`
if those packages are installed outside the checkout. It uses installed
Google Chrome in a temporary headless profile; `CHROME_PATH` can override it.

```sh
node documentation/Scripts/AppStoreScreenshots/render.cjs
```

The renderer writes to `screenshots/AppStore-2026-10/en-US/`, validates exact
pixel dimensions and absence of alpha, and writes `manifest.json` containing
source dimensions and caption copy. It skips missing source captures. Each
original app capture is proportionally fitted, without stretching or removing
controls. The 6.9-inch artwork uses the same iPhone 18 Pro capture in a larger
marketing canvas; it is not represented as a native Pro Max capture.

The renderer’s configured portrait canvas sizes (October 2026 artwork; recheck Apple’s specifications before uploading):

| Upload group | Pixels |
|---|---|
| iPhone medium Dynamic Island | 1206 × 2622 |
| iPhone large Dynamic Island | 1320 × 2868 |
| iPad 13-inch | 2064 × 2752 |
| iPhone Duo outer | 1398 × 2034 |
| iPhone Duo inner | 2007 × 2853 |

Source: [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).

Production builds increment `PECS Maker-Info.plist`. Restore only the build
number changed by the capture run, preserving pre-existing user changes.

## Contact sheet and gallery

After rendering, run `node documentation/Scripts/AppStoreScreenshots/package.cjs` from the repository root. It requires `sharp` and reads the renderer’s manifest to write `preview.png` and `index.html`. Inspect the manifest for actual coverage: missing captures are skipped by the renderer.
