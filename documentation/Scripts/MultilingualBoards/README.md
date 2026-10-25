# Multilingual board documents

Starter boards and editable boards use the same format. A board directory contains
`index.json`, shared images, and `locales/<BCP-47-language>/` resources. The index
owns identity, card order, layout, formatting and settings. Each card contains a
`localizedTitle` reference with an independent stable `key` and `sourceLanguage`.
The board has its own title reference in `localization.title`. English has no
special role in the format; new Spanish cards can have Spanish as their only text.

The localization schema below was introduced in version 2 and remains valid in version 3. Existing v1/v2 boards open without an indexing-time rewrite. The app now saves version 3 with a fresh `contentRevision` and `hierarchy.childOrder`; bundled starter resources may remain version 2. See [board hierarchy and search](../../BoardHierarchyAndSearch/README.md) for structural metadata and current verification limits.

Example version-2 localization fields (also valid in version 3, in addition to layout and topic metadata):

```json
{
  "version": 2,
  "id": "board UUID",
  "localization": {
    "title": {"key": "board.title", "sourceLanguage": "es"},
    "languages": ["en", "es"],
    "preferredLanguage": "es-MX"
  },
  "photos": {
    "photoItems": [{
      "id": "card UUID",
      "localizedTitle": {"key": "independent stable key", "sourceLanguage": "es"},
      "imageFileName": "images/shared.png",
      "imageOverrides": {"es": "locales/es/images/replacement.png"}
    }]
  }
}
```

Each string table maps keys to strings. An absent key is different from `""`.
Bundled tables use `locales/<language>/strings.json`. Saved documents use immutable
`strings-<SHA256>.json` snapshots, referenced by `localization.tableFiles`. The
index is atomically committed after resources are written, and legacy-image
cleanup runs only after that commit. Prior table snapshots remain until the atomic index commit, so a
failed save cannot destroy the previous index's strings. Image replacements also
use new filenames. After the commit, unused managed resources are removed so
sharing does not expose deleted translation or image revisions. Standalone Codable operations embed string values to remain self-contained;
normal board saves use the external tables.

## Viewing and editing

The default preference is Follow app language (missing `preferredLanguage`). The
board's language menu can select a language independently of the app. Resolution
checks the selected BCP-47 tag, broader tag/script forms, then the particular
field's source language. For example, `zh-TW` can use `zh-Hant`, and `es-MX` can use
`es`. It never searches unrelated translations. Resolution cost is bounded by the
language tag, independently of whether the board has two or twenty languages.

Image attribution, asset identifiers and photo/blank state follow their image override.
Images resolve independently: selected override, broader-language override,
shared base. An English image is not a mandatory fallback resource. Speech uses
the language that actually supplied the text; a fallback in another language does
not inherit an incompatible explicitly selected voice.

Editing writes only the active language. Displaying fallback text does not create
a translation. New cards take their source language from their destination board's
authoring context. Duplicating a card copies all translations and resource
references, with a new card ID and text key. Structural changes are shared.
Normal saves and editable board copies/exports retain every language, while print
and rendered-image exports use the selected language. Covers can have language
overrides; generated board-list thumbnails resolve the current content without
writing translations.

## Legacy boards and starter identities

Version-1 literal titles become independent source strings tagged `und` (unknown),
not whatever language happens to be active at load time. They display in every
language until translated. Opening a legacy board does not ask for a language or
write a migration. Its next save writes version 2. Unsupported future versions
are rejected instead of silently rewritten.

`StarterBoards/legacy.json` records the old English and Spanish directory names,
card IDs, original text and image hashes. A recognized legacy field gains bundled
translations only when its original identity, text and image hash match. Changed
cards remain unknown-language source content. The title is matched independently.
No cards are added during upgrade, so deletions and order survive. Existing copies
in both languages remain separate; they are never merged.

The original `.starter-boards-v1.json` installation ledger is retained. Its old
identities map to canonical catalog identities, including entries for deleted
boards. Automatic installation respects those entries. Explicit Add Starter
Boards can restore missing catalog identities, but an existing copy under either
old language identity prevents an extra copy. Saved user ordering still takes
precedence, and old aliases occupy their catalog position.

## Resource conversion

`python3 documentation/Scripts/MultilingualBoards/convert-starters.py <legacy-root> <new-output-directory>` converts paired legacy
English/Spanish assets. It verifies topic correspondence, card counts and every
paired card image hash before sharing images. It retains the original catalog
order and includes any additional folders after it. The current catalog contains
24 boards with 20 cards each. The bundled catalog has one set of 480 card PNGs
and 24 covers (7,589,799 bytes total), plus both language tables
and the legacy identity map. Its PNGs have been cropped to the bounds of their
nonzero alpha pixels. Their visible pixels and transparency are unchanged;
packaging from the original source boards may produce images with the former
margins.
Run from the repository root with a new output directory. The [screenshot-board packaging workflow](../../../ScreenshotBoards/README.md) calls this converter for production resources. The separate Boardlet rebuild importer accepts only version 1; see [its upgrade boundary](../../BoardletRebuild/UPGRADE-PATH.md).

## Verification

`MultilingualBoardTests` covers source fallback, scripts/regions, more than twenty
languages, empty translations, edits, overrides, reloads, unsaved image switching,
covers, copied documents/cards, framework duplication, legacy upgrades, unknown
source content and deletion-ledger migration. `StartupUITests` includes an
English → Spanish edit → English → Spanish relaunch journey using an isolated
board library. Existing persistence and rendering tests continue to run.

Use `BOARDLET_PACKAGE_CHECKOUTS=/Users/andy/dev/PECSMaker/.build/SourcePackages/checkouts`
when building tests with `-derivedDataPath .build`, as described in the picker test
documentation. The full picker-dependent UI suite must use the documented seeded
disposable simulator workflow, never the historical destructive Photos setup.


## Resource-path and restore repair — 23 October 2026

Post-save cleanup compares canonical resource paths after resolving symlinks.
Raw prefix trimming was unsafe because file enumeration can resolve `/var` to
`/private/var`, causing referenced images and language tables to be removed.
Regression coverage saves every starter board repeatedly through a symlink and
compares image bytes and both language tables after reload.

Explicit restoration validates existing starter documents. Unreadable folders no
longer hide missing boards; originals are retained under
`Documents/.starter-board-recovery/<UUID>/` before a bundled replacement is copied.
Readable user-edited boards are retained. Automatic startup still preserves any
existing folder and the installation/deletion ledger. The success count is checked
against the refreshed visible library. Existing readable boards are not expanded
or replaced by the content revision.
