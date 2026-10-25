# Board hierarchy and indexed search

Design and implementation handoff, 25 October 2026. This is a proposed implementation contract, not evidence that the feature exists or tests pass.

## Outcome and scope

Implement nested boards and local search in the production `PECS Maker.xcodeproj`, for both `PECS Maker` and `Easy PECS Plus`. Keep iOS 16.6 support. Use the current checkout; preserve existing user changes. The separate `Boardlet/` rebuild is out of scope.

A board contains vocabulary cards and zero or more child boards. Its immediate children appear as navigation cards in a separate area outside the vocabulary grid. Wide layouts generally place that area at the leading edge; narrow layouts place it above the board. Navigation preserves the current sentence. Search finds boards and cards across the library or a selected subtree without opening every board.

Deliver the storage and catalogue, hierarchy management, adaptive navigation, functional search UI, migration and recovery, and verification. Fuzzy matching, semantic/vector search, OCR, arbitrary cross-links, Spotlight integration, and PDF navigation links are future work.

## Existing code and constraints

- `PECSRepo.swift` owns the version-2 document, localized tables, cover images, save and resource cleanup. Its decoder instantiates card models and reads cover resources. It is unsuitable as an indexing decoder.
- `PhotoItem.swift` decoding also checks resources and may fetch Photos assets. Search must never invoke it.
- `PECSRepoFactory` currently inherits `RepoFactory<PECSRepo>` and publishes complete repositories. The pinned PersistenceFramework revision is `540616e5058057e235af2b71f36bdb49f32dd5bd`; its initializer eagerly loads available topics. Replacing only the view's array would leave startup eager loading intact.
- Existing cached dependency source is inspectable under `.build/SourcePackages/checkouts/PersistenceFramework`. Do not implement production changes only in generated dependency checkouts. Prefer an app-owned catalogue/repository service and adapt call sites; preserve necessary framework behavior through deliberate adapters.
- Read `documentation/README.md`, the multilingual guide, board-editor guide, Classic guide and relevant test guides first. Check actual target membership; duplicate/conflict-style Swift filenames are not evidence of active code.
- The checkout already contains many changed starter-board assets, screenshot-board data/scripts and documentation. Do not revert, regenerate or claim those as this task's changes.

## Authoritative folder structure

```text
topics/
  <existing-root-folder-or-new-board-UUID>/
    index.json
    images/
    locales/
      es/
        strings-<hash>.json
        images/
    children/
      <child-board-UUID>/
        index.json
        images/
        locales/
        children/
```

1. Existing root directory names remain valid. New board directories use UUIDs, with display titles in the document. Renaming a title does not rename a directory or change identity.
2. Enumerate roots only at the library's topic root and children only immediately under each board's `children/`. A candidate needs a supported, valid board index. Ignore staging directories and unrelated files. Never recursively search arbitrary resource directories for boards.
3. `images/` and `locales/` are resources owned by their containing board. `children/` is a separate structural namespace. A board titled `ES`, `es`, `Images`, `Locales` or `Children` is ordinary user content. Do not infer language from its title or directory name; do not depend on case-sensitive filenames.
4. A board has one physical parent. Parent IDs in the catalogue are derived from containment. Do not maintain a second authoritative parent pointer in document JSON. Reject moving a board into itself or a descendant.
5. Restrict resource and child paths to their owning document/library. Reject traversal and escaping symlinks; avoid loops. Treat invalid documents as unavailable entries with diagnostics, not as an excuse to drop healthy siblings.
6. Existing v1 and v2 boards open without rewriting them. Preserve current multilingual fallback, source-language and legacy starter migration behavior.

### Document metadata and compatibility

Introduce document version 3 for new-format saves. Its additions are a persistent `contentRevision` token and `hierarchy.childOrder`, an ordered array of immediate child board IDs. A fresh UUID is an adequate revision token; it is distinct from the schema version. Missing child order means no explicit ordering. New readers support v1/v2/v3 and reject unsupported future versions. Old v2 readers already reject v3; this prevents old writers silently treating hierarchical documents as ordinary flat boards.

Opening or indexing does not migrate files. Upgrade on an explicit successful save or hierarchy edit, with atomic index replacement after resources are committed. Existing flat v1/v2 documents continue to load. Ensure all intentional version checks and tests reflect the new contract, without broadly weakening assertions. Starter resources need not be rewritten en masse.

Preserve stored board IDs and directory UUID compatibility. Fix the existing decoder's directory-name-based identity regeneration so valid persisted identities survive moves. For truly legacy documents without any persistent identity, derive a repeatable provisional identity from the library-relative location, then persist that identity on the next authorized save and retain a mapping during moves. Do not assign a new random identity on every catalogue rebuild. Explicit duplicate/import-copy operations assign fresh board IDs throughout the copied subtree and remap child ordering and card identities as required by existing duplication semantics. Unexpected external ID collisions must be surfaced and isolated, not silently merged.

Order children by valid IDs in `childOrder`; append newly discovered, unlisted children in deterministic ID order. Removing stale order entries is a save-time reconciliation, not an indexing write. Migrate existing root ordering to stable IDs while retaining current starter ordering and deleted-starter ledger behavior.

## Lightweight catalogue and document loading

Introduce app-owned responsibilities with testable boundaries (names may follow repository conventions):

- `BoardDocumentReader`: reads just JSON metadata and referenced string tables into value types. No UIKit images, Photos calls, full `PECSRepo`, card view models or thumbnail generation. It must project legacy and current localization consistently with the full loader.
- `BoardLibraryStore`: discovers document boundaries, resolves IDs to current locations, and owns create/save/move/copy/delete/import/export operations and change notifications.
- `BoardCatalog`: owns the local SQLite database, metadata, hierarchy relationships, indexing/reconciliation and search. Isolate blocking work from the main thread; bound background concurrency.
- `BoardSummary`: lightweight identity, resolved title, parent, child count, order and cover reference consumed by library lists and navigation cards.
- `BoardRepositoryLoader`: opens only requested boards, with a bounded cache. Board ancestors needed for navigation come from summaries rather than full repository loads.

Remove the eager full-library load from application startup and catalogue-backed browsing. Audit `availableTopics`, published topic arrays, settings/restore flows, chooser screens, state restoration, export and duplicate actions. Do not leave a second hidden factory that instantiates every board. Existing operations must still work in Standard, Plus and Classic interfaces where available.

Keep SQLite and its WAL/SHM files in app-private Application Support outside `topics/`. Exclude this derived index from board exports and backup where appropriate; rebuild per device. Documents remain authoritative. Verify FTS5 on the minimum supported runtime/SQLite configuration; avoid SQL features newer than that baseline. Use the system SQLite API or an already suitable project dependency without adding an unnecessary remote dependency.

### Logical database model

- `boards`: board ID, parent ID, library-relative document location, schema version, content revision/fingerprint, source/preferred language, cover references, sibling order and availability.
- `cards`: board ID + card ID, card position, source language and thumbnail/image references. Exclude placeholders from searchable vocabulary.
- `texts`: entity type, board ID, optional card ID, language tag and original text. Preserve absent versus explicitly empty translations.
- FTS5 text index linked transactionally to text records; indexed board/parent/entity/language keys for filters. Use ordinary tables plus maintained FTS rows/triggers and test consistency; avoid a fragile contentless configuration.
- `index_state`: schema/indexer version, completed document revision/fingerprint, pending work and reconciliation generation.

Use parent-ID indexes and a recursive SQL subtree query initially; benchmark it before adding a closure table. Construct breadcrumbs for returned results only. Return small result pages (default 40) with stable tie-breaking. Page after entity/language deduplication so one translated card cannot fill a page with duplicates. Do not load all matching rows into Swift just to filter, sort or paginate.

## Index lifecycle and consistency

1. First build: walk document boundaries and parse one board's metadata/text at a time with bounded batches. Do not read image pixels. Show indexing progress and explicitly label incomplete search while allowing navigation and already indexed results. Resume after interruption.
2. Normal app save: persist a durable pending-operation marker before committing the document; atomically commit its resources/index; update that board's catalogue rows and FTS entries in one database transaction; then acknowledge the marker. An index failure must not undo a successful document save. Pending markers must survive database rebuild or be recoverable from document revision reconciliation.
3. Detect committed changes arriving through Files/iCloud using available file-change coordination plus foreground reconciliation. Track the manifest and referenced string tables (including mutable external tables), not only root-directory modification times. Unchanged documents require no full decoding. Metadata probes may be O(number of boards); each search must perform zero library traversal.
4. Reconcile deletions only after successfully enumerating the relevant scope. Temporary iCloud unavailability or a failed directory read is not evidence that a board was deleted. Mark unavailable content clearly.
5. Use revision/generation checks to prevent an older queued index update from overwriting newer state. Serialize mutations appropriately and resolve IDs to paths at use time so queued work cannot read a stale pre-move path.
6. Missing/corrupt database: rebuild from documents. Build replacement indexes in a separate generation/database and promote completed state safely; do not report an empty or partial library as a completed search.
7. Opening a result validates the current board/card and gracefully handles changes or deletion since the query. Refresh that entry; never select the wrong card by old numeric position.

Filesystem commits and SQLite transactions are not a single atomic transaction. Recovery tests must exercise the gap explicitly. Revision markers optimize app-originated changes; fingerprints/reconciliation cover external changes and legacy documents.

## Hierarchy mutations and portable documents

- Create child: commit a complete child document under `children/<id>` before adding it to parent order. A committed but unlisted child is discoverable. A failed creation leaves no half-valid navigable board.
- Move: retain board and descendant IDs; update physical placement, both parent orders and catalogue paths. Use durable operation journaling/staging and startup recovery for interrupted multi-file operations. Prevent cycles and cross-volume destructive shortcuts. Unsupported cross-provider moves should be explained, not partially executed.
- Duplicate: stage a self-contained subtree with fresh identities, preserve all translations, images and ordering, then publish it once valid.
- Delete: clearly present deletion of the board and its descendants in the existing confirmation flow. Keep catalogues and navigation free of stale descendants after success. Do not follow escaping links.
- Editable share/export: include the entire selected subtree, all languages and referenced resources; omit derived database and staging/journal files. Import validates the whole package before publishing, handles identity collisions as a copy, and preserves the source on failure.
- Resource cleanup operates only on each board's owned `images/` and `locales/`; it must never traverse `children/` or delete a child's resources.
- Rendered image/PDF/print output preserves existing vocabulary geometry. Navigation cards are screen UI and do not appear in printable output by default.

## Navigation and hierarchy management UI

- Provide create-child, move-to-parent/root, reorder, duplicate-subtree and delete-subtree actions through existing authoring/library patterns. The hierarchy must be usable without hand-editing folders.
- Show immediate child boards as image-and-title cards outside the vocabulary board, using lightweight summaries and lazily loaded covers. Parent boards may contain only children, only vocabulary, or both.
- Reserve one navigation background token in the teal/cyan family, unassigned by the current Fitzgerald palette. Current Fitzgerald keys already include grey and white, as well as the common chromatic colours. Use a permanent folder/page-arrow badge and a distinct card treatment; colour cannot be the sole signal. Verify light/dark and increased-contrast appearance. Do not assign a Fitzgerald key to links.
- Show Back to Parent with the parent's title/image and Home where relevant. These remain pinned while child links scroll. At library roots, Home returns to the root library. Child order is stable and consistent across layouts.
- Selecting a child changes the displayed board; it does not speak or insert a link into the sentence. Preserve the sentence across navigation, including the language/source metadata required to speak its existing cards.
- In the editor, navigation opens the corresponding board for editing. In communication mode, it remains communication navigation. Search result opening respects the same mode.
- Compare leading-sidebar and above-board candidates against the actual available bounds after safe areas, sentence area and app controls. Reuse existing board geometry/readability calculations where possible. Prefer the candidate that preserves readable vocabulary cards and reduces scrolling, not merely the device orientation.
- Bound the navigation area to one card column or row initially; excess children scroll independently. Preserve comfortable hit targets and Dynamic Type labels. A board with no vocabulary may use the remaining area for child navigation instead of rendering an empty full-size vocabulary grid.
- Use `onGeometryChange`, observing only required values. Measure a stable outer container and calculate candidates without using the chosen child's size as feedback. Add hysteresis so tiny resizes do not oscillate between placements. Keep placement stable during card edits and selection. A user placement-lock preference can wait.
- Preserve selection, scroll identity, existing editor controls, whole-page fit/zoom and print geometry. Observe Reduce Motion and expose meaningful VoiceOver button labels and grouping.

## Search behavior

- Add a discoverable search entry in the library and current-board experience. Support all-library and current-board-plus-descendants scope, board/card results, and current-language versus all-languages search.
- Current-language search uses each board's effective selected language and the same per-field fallback chain as rendering. A hidden English translation must not match when a real Spanish value is shown, unless All languages is selected. An explicit empty translation stops fallback. Unassigned legacy source text remains searchable according to existing rendering rules.
- Index all original translations once; language changes alter query projection/ranking, not the underlying documents or a full index rebuild. All-languages mode deduplicates by entity and shows which text/language matched when different from the displayed title.
- Start with literal word and last-word-prefix matching. Quote/escape FTS terms and bind SQL parameters; user punctuation must not become FTS operators or crash a query. Define empty/whitespace behavior explicitly. No fuzzy-search promise.
- Rank exact displayed-label matches first, then word/prefix matches, with stable deterministic ties. Keep language fallback semantics separate from ranking. Implement case matching and test accent handling against English and Spanish examples; do not casually equate Spanish n and ñ. Document tokenizer behavior for other scripts without claiming universal linguistic support.
- Use a short cancellable typing debounce (roughly 150 ms), cancel obsolete work, and reject stale result generations. Database work and thumbnail decoding stay off the UI thread.
- Return 40 results initially with stable paging. Load thumbnails only for visible rows using a bounded cache. A board result opens the board; a card result opens its board, selects/reveals its actual current position, and does not automatically speak or add it to a sentence.
- Show breadcrumb context. No text-recognition, image embedding, network request or full board load is involved in executing a normal indexed query.

## Verification and completion gate

The user's requirement is that all tests pass. Implementation is not complete after writing tests or passing only the new suite. Record the exact commands, final test inventory/counts, result bundles and any unavailable checks in a new verification document. Do not label historical results as new passes, hide unexpected skips, weaken assertions to get green, or claim unavailable tests passed.

### Required new coverage

- Folder boundaries: ES/es/Images/Locales titles, nested translations, missing/invalid index, unknown versions, resource folders, symlink/path escape, duplicate IDs and deep hierarchy. Parent saves must preserve child bytes.
- Legacy compatibility: v1/v2 read without mutation, explicit v3 save/reload, stable IDs through rename/move/rebuild, existing starter ledger/ordering and localized title/image behavior.
- Mutations: create/reorder/move-to-root, reject descendant moves, subtree copy identity remapping, delete, export/import all languages, and injected failure/relaunch at each journal/commit boundary.
- Catalogue: initial build, incremental replacement/removal, stale update rejection, database corruption/rebuild, external manifest/table edit, temporarily unavailable scope, cancellation and resumable partial build.
- Search: board and card labels, literal punctuation/quotes/FTS operators, empty input, prefixes, English/Spanish accents, fallback versus real/empty translations, all-language deduplication before paging, stable pages/ties, subtree filters and breadcrumbs after moves.
- Assert through instrumentation that normal browse/search uses zero full-repository decodes and zero image-pixel reads before visible thumbnail requests. Opening one result must not load its siblings/ancestors as complete boards. Include startup to catch eager framework initialization.
- UI in both variants: child navigation/Back/Home, sentence preservation, search/open/reveal without speaking, authoring actions, portrait/landscape and resizable iPad bounds, many children, empty parent, Dynamic Type, light/dark, VoiceOver semantics and Reduce Motion. Visually inspect representative screenshots.
- Existing editor, formatting, pagination, speech, multilingual restoration, copying, printing/sharing and Classic interfaces must remain covered.

### Performance evidence

Use generated fixtures in ignored `.build/board-hierarchy-search/`, with 1,000 boards / 100,000 cards and multiple translations. Separately measure first indexing, unchanged launch reconciliation, warm and cold queries, common prefixes, subtree filtering, all-language deduplication, incremental updates, and peak memory. The query target is p95 under 100 ms excluding the typing debounce and image loading, on a representative physical older supported device when available. Simulator measurements are useful but must be labelled; do not claim physical-device performance from them. Record data volume, query set, build configuration, hardware/runtime, repetitions and percentile method. Verify bounded working memory and no main-thread indexing stalls, not just one fast query. Investigate misses and report measured limits honestly.

### Existing suite execution

1. Start with focused pure storage/index tests and new UI tests, then fix failures.
2. Build both production schemes and run complete enabled production unit/UI suites, including the Plus UI target and existing BoardEditor/InterfaceModes coverage where separate plans contain additional cases. Discover the actual final test inventory; do not assume historical counts.
3. Use the existing iPhone 18 Pro / iOS 27 simulator for ordinary tests. Run applicable iPad layout checks on an existing iPad simulator. Preserve iOS 16.6 deployment and verify new API/SQLite availability; report minimum-runtime execution separately if no suitable runtime is installed.
4. Tests requiring seeded Photos fixtures must use the documented disposable-simulator runners in `documentation/Scripts/SystemPhotoPicker/README.md`. Never run historical destructive SetupPhotos on the personal simulator. If picker/shared sources are changed, also run the prescribed production matrix and standalone harness. Reconcile runner inventories if adding tests changes expected counts; preserve all mandatory assertions and expected-skip rules.
5. Run complete tests for any new or changed local package, plus affected existing integration suites. Do not run builds concurrently against the same simulator/derived-data directory.
6. Use documented package-cache/signing workarounds only as needed and record them. Existing guides note Thread Sanitizer startup problems in iOS 27 UI runners; if encountered, report the failure and a separately labelled valid rerun rather than silently changing global plans.
7. Review `git diff --check`, source membership in both targets and generated localization. Restore only build-number changes caused by this work to the exact captured pre-build values. Preserve all unrelated pre-existing changes.

Create `documentation/BoardHierarchyAndSearch/VERIFICATION.md` with actual outcomes and update the documentation index and relevant guides to describe the shipped behavior. If tooling, dependencies or device availability prevent the completion gate, clearly identify the blocker, completed checks and remaining checks. Do not declare that all tests pass until execution supports it.

## Implementation sequence

1. Capture starting status and understand active persistence/navigation call sites; implement lightweight readers, identity/version contract and pure tests.
2. Implement catalogue/index lifecycle and mutation recovery; prove multilingual and subtree correctness with fixtures.
3. Replace eager library discovery and connect existing authoring/restoration paths to lazy summaries/loading.
4. Implement hierarchy management and adaptive navigation in both app variants.
5. Implement search UI and ID-based result navigation.
6. Finish performance measurement, complete regression suites, visual verification and documentation. Resolve failures before reporting completion.

The implementation owner may adjust internal types and SQL layout to fit inspected code. Preserve these user-visible and correctness requirements; document material deviations with evidence rather than silently reducing scope.
