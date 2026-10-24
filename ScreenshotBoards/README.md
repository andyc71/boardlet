# Screenshot boards

48 native PECS Maker / Boardlet topic folders: 24 English and 24 Spanish,
with 20 cards per board (4 × 5, A4 portrait). The 216 original and 192 additional symbol PNGs
have genuine alpha transparency. English and Spanish use identical artwork;
labels remain editable text in each board's `index.json`.

## Files

- `en/topics/` — English board directories.
- `es/topics/` — Spanish board directories.
- `ScreenshotBoards-en.zip` and `ScreenshotBoards-es.zip` — each contains a
  `topics/` folder with 24 self-contained native boards.
- `preview.html` — open locally in a browser to review either language;
  “Toggle colour behind symbols” demonstrates transparent backgrounds.
  This is a catalogue preview, not a capture of the app UI.
- `manifest.json` — maps board titles to directory UUIDs.
- `catalog.json` — bilingual labels and artwork concepts, in requested order.
- `symbols/` — 408 reusable transparent PNGs, including the themed expansion.
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
On the first normal launch after this update, they copy 24 boards matching the
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

English topics: **3,053,757 bytes (3.05 MB / 2.91 MiB)**, including JSON,
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
swift -module-cache-path .build/ModuleCache documentation/Scripts/ScreenshotBoards/extract-symbols.swift ScreenshotBoards
python3 documentation/Scripts/ScreenshotBoards/package-boards.py
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

## PNG-8 conversion (22 October 2026)

All 171 extracted symbols use 8-bit indexed PNG with up to 256 palette entries,
including alpha transparency. Converted using Pillow FASTOCTREE, matching the
reviewed Breakfast preview, without resizing. Palette reduction is lossy.
The English and Spanish boards, both ZIPs, and both bundled starter-board
languages were regenerated from these symbols.

- Original symbols: 23,782,325 bytes; PNG-8 symbols: 2,710,353 bytes (88.6% smaller).
- `originals-before-png8.zip` preserves the exact pre-conversion symbols, localized
  board folders, bundled starter boards, board archives, and alpha report, with
  paths relative to the repository root. Every entry was verified against its
  original using SHA-256 before conversion. Keep this backup outside the app bundle.
- `png8-conversion.json` records individual before/after symbol sizes.
- `alpha-validation.json` describes the converted symbols.
- All 931 PNG copies were decoded and verified as 8-bit indexed PNG; source
  dimensions and transparency were checked. Packaging validated 38 boards,
  342 card records, all image references, and both ZIP archives.

Running the Swift extractor again recreates full-colour symbols from the unchanged
source sheets; reapply palette conversion before packaging to retain PNG-8 output.

## Home, School, Work, Technology and Health — 23 October 2026

Five new nine-card boards are included in both languages, the preview, ZIPs and
bundled starter boards. Artwork was generated using the built-in image generation
tool; exact prompts are in `artwork/prompts.json`.

`originals-new-boards-png24.zip` preserves five source sheets and 45 extracted
symbols as full-colour RGB plus alpha PNGs (24-bit colour plus 8-bit alpha).
The backup was verified byte-for-byte against the extracted originals. App assets
use 256-colour PNG-8, with no resizing; palette alpha values of 250–255 are
normalized to opaque. `new-boards-png8-conversion.json` records sizes.

Validation: the Swift extractor verified all 45 symbols;
`python3 documentation/Scripts/ScreenshotBoards/package-boards.py` passed for 48 boards,
432 card records, image references and both ZIP archives. English topics total
3,791,543 bytes. Simulator verification was unavailable: `xcrun simctl list
devices booted` failed with a CoreSimulatorService connection error.

The earlier `originals-before-png8.zip` backup is stored with Git LFS because
it exceeds GitHub's regular file-size limit.

## Expanded Starter Boards — 23 October 2026

All 24 topics now contain 20 cards (480 cards with English and Spanish labels).
The original nine cards retain their order, IDs, labels and images. Eleven related
choices or communication requests are appended to each board using existing
artwork with its original translations. No new artwork or relabelled symbols are
introduced. The catalog's optional seventh field lists source symbol paths, so
shared artwork need not be duplicated in `symbols/`; the packager copies it into
each self-contained board and generates a preview using those same paths.

Boards use a 4 × 5 portrait layout. The localized exports, ZIPs, preview and
multilingual production bundle are regenerated together. Existing installed
boards are preserved by the installer, including user edits and deleted cards;
this content expansion applies to fresh installs and missing boards restored via
Add Starter Boards.

Validation: `python3 documentation/Scripts/ScreenshotBoards/package-boards.py` checks 48 localized
boards, 960 card records, bilingual label counts, duplicate labels, image
references and both ZIP archives. English topics total 7,821,380 bytes.


## Theme correction and resource recovery — 23 October 2026

The broad additions above were revised. Sixteen topics now have eleven new,
theme-specific cards each: Greetings, My Answer, Drinks, At Mealtimes, Getting
dressed, Playtime, Arts & crafts, Places to Go, At the shops, Transport, How I
Feel, Feeling unwell, Home, School, Work and Technology. What would Help now
contains calming activities and comfort choices. Food boards retain relevant food
and drink choices; I Need retains needs and support requests. Every topic still
has 20 bilingual cards, including the original nine in their original order.

The built-in image-generation tool produced sixteen 3 × 4 transparent sheets.
The 192 extracted symbols include 176 new cards and sixteen spare concepts.
Full-colour source sheets, bilingual concepts and prompts are in
`artwork/expansion/`; `revised-prompts.json` records accepted regenerated sheets.
Rejected drafts are not packaged. Assets are extracted through transparent gutters
and converted to PNG-8 without resizing, with alpha 250–255 normalized to opaque.

```sh
swift -module-cache-path .build/ModuleCache documentation/Scripts/ScreenshotBoards/extract-symbols.swift ScreenshotBoards --expansion
python3 documentation/Scripts/ScreenshotBoards/prepare-expansion-symbols.py
python3 documentation/Scripts/ScreenshotBoards/package-boards.py
```

The conversion command requires Pillow. Reports are `expansion-alpha-validation.json`
and `expansion-png8-validation.json`. Packaging removes superseded generated card
PNGs from localized exports, keeping ZIPs and the preview consistent with the
catalog. The final English topic payload is 7,821,451 bytes.

The app's resource cleanup now compares canonical file paths, preserving resources
when iOS resolves `/var` to `/private/var`. Explicit Add Starter Boards treats an
unreadable starter folder as missing. It keeps that folder unchanged under
`Documents/.starter-board-recovery/<UUID>/` before restoring the bundled board.
Readable edited boards and automatic-install deletion history are preserved.
