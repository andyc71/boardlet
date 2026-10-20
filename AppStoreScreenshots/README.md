# Boardlet App Store screenshots

Created with the app-store-screenshots skill's editable Next.js template.
The existing production app is branded Boardlet; its Xcode scheme is PECS Maker.

## Design brief

- App: Boardlet, a picture-board creator for everyday communication.
- Features shown: organized boards; familiar photos and symbols; page/grid/orientation controls; print preview and PDF sharing.
- Font: the app's bundled Baloo 2 Bold, imported locally so exports do not depend on web fonts.
- Colours: bright blue #33C5FF, light blue #CEE6FF, pale blue #EDF6FF; supporting pink #FFAACC, yellow #FFDD33 and green #68DFA7. The artwork uses blue surfaces with dark teal #003C51 for contrast and yellow labels on dark slides.
- Copy: one short benefit headline and supporting subtitle per image. English only.
- Layout: alternating top/bottom captions, real app captures, straight-on Apple bezels. The short decks keep each device and its text within one image; the blue backdrop links the set.

## Run and edit

From /Users/andy/dev/PECSMaker/AppStoreScreenshots:

```sh
pnpm install --ignore-scripts
npm run dev -- --hostname 127.0.0.1
```

Open http://127.0.0.1:3000. Select iPhone, iPad or iPhone Duo outer.
Edit captions, colours and placements, then use **Export bundle** for each device.
The canonical editable state is app-store-screenshots.json. Captures and font are under public/.
Other device decks are empty; do not export placeholders.

## Deliverables and coverage

exports/ios contains upload PNGs, sorted by device, size, locale and sequence.
The ZIP contains upload images and this guide. Preview/contact-sheet images are for review only.

| Set | Pixels | Designs |
| --- | --- | --- |
| iPhone | 1320×2868, 1284×2778, 1206×2622, 1125×2436 | 4 per size |
| iPad | 2064×2752, 2048×2732 | 3 per size |
| Duo outer portrait | 1398×2034 | 4 |

Sizes checked against Apple's screenshot specifications:
https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/

The iPhone designs use existing iPhone 18 Pro captures within marketing canvases; exports at larger sizes do not imply native Pro Max captures.
The iPad library capture from the earlier capture run had a permission prompt, so it is excluded.
Duo inner display is NOT delivered: no usable native capture exists and the locked Mac prevents access to Device Hub fold controls. Do not substitute iPad/iPhone captures. Capture genuine 2007×2853 portrait or 2853×2007 landscape imagery after unlocking the Mac. Review Duo sets in App Store Connect's preview before submitting.

## Verification

- `node node_modules/typescript/bin/tsc --noEmit`: passed.
- Exported through the skill template's Export bundle control, with no missing-image warning.
- `node verify-exports.cjs`: validates all upload PNG dimensions, opaque RGB output and creates review contact sheets.
- Existing captures reused from screenshots/AppStore-2026-10/raw. No production Swift code changed and no new production build/test run was needed for this artwork-only task.
- Earlier capture commands/results remain in ../screenshots/AppStore-2026-10/verification.txt.
- `xcrun simctl list devices booted`: succeeded with simulator access; native UI inventory reported the Mac locked. Inner capture remains pending.

Nothing has been uploaded to App Store Connect.
