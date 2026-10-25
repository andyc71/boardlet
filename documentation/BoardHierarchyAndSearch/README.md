# Board hierarchy and indexed search

The core implementation is present for Standard and Plus; acceptance remains incomplete. Storage, layout and test-fixture corrections have passing focused coverage alongside the full-run evidence. iPad search after submitting the query passes; direct result/Done tapping while the software keyboard remains open is unresolved. Earlier runs also encountered simulator stalls. [Verification](VERIFICATION.md) records actual outcomes and limits. The [implementation contract](IMPLEMENTATION-DESIGN.md) remains the acceptance reference.

## Documents and navigation

A board's immediate children live in `children/<UUID>/`. Images and localized tables belong to each containing board; a board named ES or Images has no special meaning. Existing root folder names remain valid. Readers accept versions 1–3 without rewriting them. Successful saves and hierarchy edits write version 3, a fresh `contentRevision`, and `hierarchy.childOrder`. Persisted IDs survive title changes and moves. Duplication/import assigns fresh board and card IDs throughout the subtree.

Child links have a cyan background, teal outline and folder badge outside the vocabulary grid. They scroll independently in one row above the board or one column beside it. Parent/Home controls remain pinned. Child-only boards use the remaining area for navigation. The current editing/communication mode and sentence are retained. Search selects the current card by ID without speaking it. Existing print/PDF/image rendering excludes navigation links.

Organize provides create/import child, move to another board or Home, duplicate/delete subtree and editable package export. Long-press a child to move it earlier. Moves reject cycles and use a durable operation journal. Imports stage and validate before publication. Parent saves do not clean child resources. Interrupted index updates leave `.index-pending` beside the document until catalogue acknowledgement.

## Catalogue and search

`Packages/BoardLibrary` owns a serial writer actor, lightweight metadata reader, SQLite/FTS5 catalogue and filesystem operations. A separate serial WAL read connection serves consistent query snapshots while indexing continues. App library screens use summaries; full repositories are opened on demand with a cache of at most three entries. Visible covers and search-result thumbnails use a shared bounded background thumbnail cache. Search results carry indexed image references, including language overrides, and never parse manifests or decode pixels during the query. SQLite/WAL files live in private Application Support outside board packages and are excluded from backup.

Indexing reads JSON and original string tables, not image pixels or Photos. One legacy compatibility exception hashes compressed image bytes to preserve the existing exact starter-card migration rule; it does not decode images. Unchanged documents use manifest/table metadata probes. Normal saves update one entry; foreground and file-presenter notifications reconcile external changes. Invalid/colliding documents are diagnosed and isolated from search, including their descendants. For a missing content-addressed default-title table, the app can restore its known original bytes only when their SHA-256 matches the referenced filename; it never guesses unknown translations or overwrites existing files. Missing, corrupt or older-schema catalogues rebuild in a separate resumable database generation. Completed reconciliation atomically promotes its pointer while existing WAL connections keep stable filenames; incomplete generations remain explicitly labelled and resume committed batches on relaunch. Search performs no folder traversal.

Search supports the whole library or a board and descendants, with current-language or all-language matching. Current-language projection follows rendering fallback and respects explicit empty translations. All-language results deduplicate by board/card before pages of 40 and show hidden-language matches. Exact displayed labels rank first. Queries use literal word tokens and a final-token prefix; punctuation is never an FTS operator. Empty input returns no results. The `unicode61 remove_diacritics 0` tokenizer retains accents, including Spanish ñ; it does not promise linguistic segmentation or fuzzy matching for every script.

## Verification workflow

Host package tests:

```sh
SWIFT_MODULECACHE_PATH="$PWD/Packages/BoardLibrary/.build/ModuleCache" \
CLANG_MODULE_CACHE_PATH="$PWD/Packages/BoardLibrary/.build/ModuleCache" \
swift test --package-path Packages/BoardLibrary --disable-sandbox
```

Complete seeded production suites use the existing documented simulator ownership and fixture tools:

```sh
python3 documentation/BoardHierarchyAndSearch/run-production-suites.py \
  --output .build/board-hierarchy-search/full-production
```

Use a fresh output path for each run. The runner creates and removes only its owned disposable simulator, saves exact commands/results and runs both full production suites sequentially. Standard uses `BoardLibraryVerification.xctestplan`, a full-inventory copy with Thread Sanitizer disabled because the iOS 27 UI runner fails at startup under TSan. The original main plan remains unchanged. Inspect result counts, failures and named skips; process exit alone is insufficient.

For seeded UI reruns, add `--variant standard` or `--variant plus` and repeat `--only-testing Class/method` (or `Class`) for each selection. Add `--include-unit-tests` to include the full Standard unit target alongside selected UI tests. The timeout defaults to 600 seconds per test and can be set with `--test-timeout`. Assertions and expected skips remain unchanged.

Ordinary focused tests continue to use the existing iPhone 18 Pro. Separate iPad interface plans are described in the Classic guide. No personal Photos library is seeded or deleted by this workflow.
