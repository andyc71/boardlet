# Screenshot boards

38 native PECS Maker / Boardlet topic folders: 19 English and 19 Spanish,
with nine cards per board (3 × 3, A4 portrait). All 171 original symbol PNGs
have genuine alpha transparency. English and Spanish use identical artwork;
labels remain editable text in each board's `index.json`.

## Files

- `en/topics/` — English board directories.
- `es/topics/` — Spanish board directories.
- `ScreenshotBoards-en.zip` and `ScreenshotBoards-es.zip` — each contains a
  `topics/` folder with 19 self-contained native boards.
- `preview.html` — open locally in a browser to review either language;
  “Toggle colour behind symbols” demonstrates transparent backgrounds.
  This is a catalogue preview, not a capture of the app UI.
- `manifest.json` — maps board titles to directory UUIDs.
- `catalog.json` — bilingual labels and artwork concepts, in requested order.
- `symbols/` — the 171 individual reusable transparent PNGs.
- `artwork/` — transparent source sheets and exact generation prompts.
- `alpha-validation.json` — dimensions and transparent/opaque pixel counts.

## Use for screenshots

The ZIPs are transport archives, not a new app import format. Extract the chosen
language and copy its `topics/` folder into a screenshot-only document directory.
The existing app launch argument `-mfDocDoc:<absolute-document-directory>` selects
that directory (see `PECS Maker/Classes/LaunchArguments.swift` and the screenshot
UI test setup). The app expects `topics/<English name> - <UUID>/index.json` plus its PNGs.

For example, prepare an isolated English fixture directory from the repo root:

```sh
mkdir -p .build/ScreenshotBoards-en
cp -R ScreenshotBoards/en/topics .build/ScreenshotBoards-en/
```

Use the absolute `.build/ScreenshotBoards-en` path as the document directory for
a simulator screenshot launch. Spanish uses `ScreenshotBoards/es/topics` and a
separate destination. Board language is set by the selected files; select the
matching app UI language separately. Close the app before changing fixtures.
Keep this separate from personal documents and existing screenshot test fixtures.
Both production apps include the `PECS Maker/Resources/StarterBoards` folder.
On the first normal launch after this update, they copy 19 boards matching the
app language (Spanish, otherwise English) into the document library.
A per-library `.starter-boards-v1.json` ledger records successful installations.
Later launches add newly bundled boards and preserve edits and deletions; changing language does not add a
second set. Existing folders are never overwritten, and interrupted copies are
staged outside `topics`. Explicit `-mfDocDoc:` test libraries skip automatic setup.
The English board name prefixes every folder in both languages. Card PNGs are
prefixed by their localized label, with unsafe filename punctuation removed.
The packager regenerates the bundle payload as well as both ZIPs.

Each topic thumbnail uses its first card. Board formatting is omitted deliberately
so the app's existing decoder supplies its standard formatting. `hasPhoto: true`
is the persistence model's generic “has image content” flag; the images here are
all symbols, with no Photos asset IDs or third-party provider IDs.

English topics: **26,426,728 bytes (26.43 MB / 25.20 MiB)**, including JSON,
171 card PNGs and 19 topic thumbnails; excludes ZIP and source artwork.

## Artwork

Created with the built-in image generation tool on 19–20 October 2026. The prompts
request original accessible pictograms, simple outlines and recognisable shapes,
without copying ARASAAC or another symbol library. No ARASAAC images were used as
inputs. The initial white-background drafts were rejected and are not included.
All included sheets were regenerated with `transparent_background: true`.

The extractor finds clear gutters rather than cutting blindly at equal thirds,
and preserves the generated PNG alpha. It does not paint or remove backgrounds.
Some generated outlines include soft antialiased edges. The symbols have no
embedded labels, allowing both language versions to reuse them.

## Rebuild and validate

From the repository root, using macOS Swift and Python 3 (standard library only):

```sh
swift -module-cache-path .build/ModuleCache Scripts/ScreenshotBoards/extract-symbols.swift ScreenshotBoards
python3 Scripts/ScreenshotBoards/package-boards.py
```

Results on 19–20 October 2026:

- Swift extraction: passed for all 19 sheets / 171 symbols, with clear gutters,
  more than 10% fully transparent pixels per symbol and opaque artwork present.
- Python packaging: passed for 38 boards, 342 card records, unique UUIDs,
  all image references, and integrity/card counts of both ZIP archives.
- Visually reviewed all source sheets and sampled exported symbols.
- App integration verification is recorded in `VERIFICATION.md`.
- The automated browser preview was blocked because its URL policy disallows
  `file:` URLs. The self-contained HTML remains available for local review.
