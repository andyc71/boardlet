# Boardlet native rebuild

Open `Boardlet.xcodeproj`. Run **Boardlet** or **BoardletPlus**. Both use development identities and can coexist with the production apps. The deployment target remains iOS 16.6; this project uses Swift 6 strict concurrency and has been developed with Xcode 27.0.

The app implements a local Boards library, functional Blank/First and Then/Routine starters, card editing and bulk labels, imports, communication, PDF/image/print export, settings, English and Spanish, recoverable deletion, undo/redo, and atomic autosave. Communication positions and print layout have independent settings. Existing boards and downloaded media work offline.

## Project and dependencies

`project.yml` is the XcodeGen source. Regenerate with `xcodegen generate --spec Boardlet/project.yml` from the repository root after changing target membership. The generated project is included so XcodeGen is not needed to open or build it.

The only package is the existing local `Packages/ARASAACSymbols`. Both app targets reference `Shared/SystemPhotoPicker` directly. No production source or existing project file is changed by this rebuild. The project has no version-increment or SwiftGen build scripts. English/Spanish source text is maintained by `Scripts/localize.py`; plural resources are checked in separately.

Development identifiers:

- Boardlet: `com.brightblue.boardlet.development`
- BoardletPlus: `com.brightblue.boardlet.plus.development`

Select your signing team for physical-device builds. Simulator verification uses `CODE_SIGNING_ALLOWED=NO`.

## Storage and migration

`Documents/Boardlet/library.json` is a versioned manifest; immutable media lives in `Media`. A previous manifest is retained for recovery. Failed loads disable editing until recovered. Deleted boards remain in Recently deleted. Backups contain media and metadata, including deleted boards. No automatic media purge runs.

Use Settings to import a read-only legacy folder or a Boardlet backup. A development app cannot access a production app's sandbox. An in-place migration gate exists only for the two existing production identities and only before the first new manifest. Do not change bundle IDs as a substitute for release upgrade testing. See `../documents/BoardletRebuild/UPGRADE-PATH.md`.

Use-mode messages clear when leaving that mode; rotation and page changes preserve them. Fixed communication rows, columns and pages retain card positions; overflow scrolls. Editor/library grids adapt to available space.

## Plus integration status

Existing Dynavox and generated rasterized cards migrate and work offline. New Dynavox search is blocked by a missing Git LFS asset in the production-pinned dependency. The package is excluded from the working project, and Plus explains its unavailability.

Optional AI creation is connected through `AISymbolService`. Configure an application-owned HTTPS URL as `BoardletAIEndpoint` in **both** the relevant `project.yml` Info properties and generated app Info.plist before testing a deployment. The service posts `{"prompt":"…"}` and accepts either `image/*` bytes or JSON `{"imageBase64":"…"}`. There is no configured endpoint or live generation claim. Do not put provider API keys in the app.

## Verification

Run from `/Users/andy/dev/PECSMaker`:

```sh
xcodebuild -project Boardlet/Boardlet.xcodeproj -scheme Boardlet \
  -destination 'platform=iOS Simulator,id=BB33297D-F833-464B-B43D-14CBD0DA3021' \
  -destination 'platform=iOS Simulator,id=E4B44237-C067-4F3E-881A-58024523D11F' \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  -derivedDataPath Boardlet/.build/DerivedData \
  -resultBundlePath Boardlet/.build/release-candidate-check.xcresult \
  test CODE_SIGNING_ALLOWED=NO
```

Use a new result-bundle path for each run. UI tests write a unique test library using `--ui-testing` and `BOARDLET_TEST_RUN`; they never delete a Photos database. They do not use the historical destructive setup test.

Exact results, screenshot evidence and outstanding coverage are recorded in `../documents/BoardletRebuild/VERIFICATION.md`. Dynavox/AI integration and platform/hardware gaps prevent treating this as a release-ready replacement.
