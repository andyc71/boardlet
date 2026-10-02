# Project guidance

## What this repository contains

- This is an iOS SwiftUI app with two production schemes, `PECS Maker` and `Easy PECS Plus`, in `PECS Maker.xcodeproj`. Both production targets currently deploy to iOS 16.6 and use Swift 5. Check both targets when changing shared app code or project settings.
- App code is under `PECS Maker/`: `App Lifecycle` contains the entry point, `Views/Pages` contains screens and layout flows, `Components` and `SharedUI` contain reusable UI, and `Classes/Persistence` contains board and photo models.
- The system Photos picker implementation is shared by source reference from `Shared/SystemPhotoPicker`. `PhotoPickerHarness` is a standalone app and test project for that implementation; `TestSupport/SystemPhotoPicker` contains the reusable UI test driver. Do not copy these sources into separate implementations.
- `PECS MakerTests` and `PECS MakerUITests` cover the production app. `Scripts/SystemPhotoPicker/README.md` and `PhotoPickerHarness/README.md` describe the picker test setup and its current behavior.

## Working in this checkout

- Use the existing source checkout at `/Users/andy/dev/PECSMaker` for edits, builds, and tests. Do not clone or copy the project into a temporary folder to work on it; run package commands from their directories in this checkout. Keep generated build artifacts in the package's ignored `.build` directory unless a documented test script requires another location.
- Check `git status` before editing. This checkout may contain user changes, generated files, and test artifacts. Preserve unrelated changes and do not clean or reset the working tree.
- Some files have similar names with a ` 2.swift` suffix or conflict-style suffixes. Confirm Xcode target membership and call sites before editing or removing one; filenames alone do not establish which implementation is active.
- When adding a source file, resource, or shared file reference, update the relevant target membership in the Xcode project. Check both production variants and the harness when the change crosses those boundaries.
- Keep the iOS 16.6 deployment target unless the task explicitly changes platform support. Check availability for APIs introduced later.
- Localized strings live in `PECS Maker/Resources/en.lproj` and `es.lproj`. `PECS Maker/SwiftGen/Strings.swift` is generated from the English strings using `PECS Maker/SwiftGen/swiftgen.yml`; update source strings and regenerate when applicable. BartyCrouch configuration is in `.bartycrouch.toml`.
- Production Xcode builds have script phases that increment `CFBundleVersion` in the app Info plists and may run SwiftGen. Review the diff after building so build-generated changes are not mistaken for intentional edits.

## Verification

- Use the existing iPhone 18 Pro simulator running iOS 27.0 by default for app builds and tests until told otherwise. Do not create a disposable simulator for ordinary app tests; use one only when a documented script or a test's destructive setup requires it.
- For app changes, build the affected production scheme and run the relevant `PECS MakerTests` or `PECS MakerUITests` tests on an available iOS simulator. `PECS Maker.xctestplan` defines the main test targets; `SystemPhotoPickerMatrix.xctestplan` defines picker orientation configurations.
- For shared picker changes, follow `PhotoPickerHarness/README.md`; its disposable-simulator entry point is `PhotoPickerHarness/Scripts/test.sh`. For production picker integration, follow `Scripts/SystemPhotoPicker/README.md` and its matrix runner. These scripts create their own test devices and artifacts.
- Do not run the historical `PECS MakerTests/SetupPhotos.swift` against a personal simulator or photo library; the picker documentation says it deletes Photos database content directly. Use the disposable simulator scripts instead.
- Report the exact build or test command and result. If simulator services, signing, package resolution, or dependencies prevent verification, state that limitation rather than implying a pass.
