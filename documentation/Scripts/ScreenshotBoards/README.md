# Screenshot and starter board tools

Run from the repository root. These tools maintain the source catalog in `ScreenshotBoards/`; the full [catalog guide](../../../ScreenshotBoards/README.md) covers artwork provenance, board contents and the expansion workflow. [Verification records](../../../ScreenshotBoards/VERIFICATION.md) are historical results.

| Tool | Purpose |
| --- | --- |
| `extract-symbols.swift` | Extract source symbol artwork into `ScreenshotBoards`; pass `--expansion` for the expansion set. |
| `prepare-expansion-symbols.py` | Prepare expansion artwork; requires Pillow. |
| `package-boards.py` | Rebuild paired English/Spanish source boards, archives, manifest and preview; invoke the multilingual converter and copy version-2 resources into the production starter catalog. |

Typical packaging command:

```sh
python3 documentation/Scripts/ScreenshotBoards/package-boards.py
```

Packaging writes source-board artifacts and `PECS Maker/Resources/StarterBoards`. Review existing changes before running it. It is not a read-only validator. The converter requires paired language content and matching card image hashes; see [multilingual documents](../MultilingualBoards/README.md).

All script-relative repository paths account for the move into `documentation/Scripts`. Command-line input/output paths remain relative to your working directory.

## Fitzgerald Key assignments

`ScreenshotBoards/fitzgerald-keys.json` explicitly assigns every catalog concept
(using its English label as the lookup key) to a non-`none` app category. Both
localized exports and the multilingual starter bundle share the same assignment.
The packager rejects missing labels and unsupported categories before writing.
When adding or renaming a catalog label, update this mapping too.

Assignments follow the card's communication meaning: objects, people, places and
named activities are nouns; action requests are verbs; feelings and descriptive
states are adjectives. Greetings, polite social responses, Yes/No, Help, Stop and
All done use `important`; direct questions use `question`. Phrase cards use their
main meaning rather than the grammatical class of their first word. For example,
“I'm hungry” is an adjective and “Help me dress” is a verb. Repeated concepts
have the same category on every board. The app stores one category per card,
shared by its translations.

The 25 October 2026 assignment updates all 480 bundled cards, the 960 localized
export records and both ZIPs. Existing installed user boards remain unchanged;
fresh installs and missing-board restores receive the assigned keys. Existing
Fitzgerald border display preferences still control whether colours are shown.

Verification on 25 October 2026: JSON validation passed for all 72 board
indices (480 bundled cards and 960 localized records), checked both ZIPs against
the localized indices, and compared each index against Git HEAD with the key
field excluded to confirm no other document content changed. `git diff --check`
passed. The following app checks both exited 74 before building/tests:

```sh
BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/SourcePackages/checkouts xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'PECS Maker' -destination 'platform=iOS Simulator,name=iPhone 18 Pro,OS=27.0' -derivedDataPath .build '-only-testing:PECS MakerTests/StarterBoardTests' test
xcodebuild -project 'PECS Maker.xcodeproj' -scheme 'Easy PECS Plus' -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/FitzgeraldPlus build
```

The first could not write SwiftPM/compiler caches under the session permissions;
the second could not resolve github.com for package dependencies.
`xcrun simctl list devices booted` also failed to connect to CoreSimulatorService.
These are not app build or test passes.
