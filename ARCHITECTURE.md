# Boardlet architecture

## Boundaries

- `BoardDomain` contains the platform-neutral, `Codable` and `Sendable` board document types plus the `BoardStore` actor. It owns staged writes, atomic replacement, backup recovery, and cleanup only after commit.
- `PECSRepoFactory` adapts the legacy persistence models to the application. Its storage root, settings, and `UserDefaults` are injected; startup failures are published instead of being discarded. There is no process-wide repository singleton or mutable storage-root global.
- `BoardEditorStore` owns one `PageLayoutState` per stable persisted topic UUID. `NavigationModel` owns the single typed `AppRoute` used by both compact and split presentations, so a size-class change preserves the selected topic and operation.
- `BoardRenderer` accepts immutable `Sendable` snapshots and serializes UIKit image and PDF work in an actor. The main actor only captures view state and publishes progress, results, and errors.
- Dynavox search/image decoding and AI image generation are actor-backed services. Their view models are `@MainActor`, cancel superseded requests, and reject stale results.

## Persistence transaction

Saving a board first encodes a complete document and stages every image and index file. The store then atomically promotes the staged directory, retains the previous committed directory as a recovery backup until the promotion succeeds, and only then removes obsolete content. Loading prefers a valid committed document and can recover the prior commit after an interrupted promotion. Encoding model values never writes files as a side effect.

Tests use unique temporary roots and deterministic fault injection to cover image failures, index failures, interrupted commits, and backup recovery. Application tests also construct the repository against an empty temporary root to cover first launch without relying on global initialization order.

## Credentials and AI services

The applications and local packages do not bundle or read provider credentials. AI generation accepts only an HTTPS application-backend URL (`AI_IMAGE_SERVICE_URL`). If it is absent, the feature exposes an explicit unavailable state. Provider authentication belongs on that backend.

## Package graph and generated sources

Boardlet uses local path references for its maintained packages and one checked-in application `Package.resolved`. Transitive external packages have a single identity and compatible requirement in the application graph. Generated localization sources remain checked in; SwiftGen build-tool plugins and source-mutating build phases are intentionally absent. CocoaPods is no longer part of either application target.

All maintained package manifests and application targets use iOS 16.6 as their minimum deployment target.

## Concurrency migration

`BoardDomain`, `LogFramework`, `LogFrameworkFirebase`, `ZipWrapper`, `AISymbols`, `MailFramework`, and `SettingsFramework` compile in Swift 6 mode. Their cross-actor values are `Sendable`, mutable services are actors where applicable, and test synchronization uses continuations rather than timing sleeps.

The remaining UI and persistence packages stay in Swift 5 language mode for this migration. They contain public APIs built around reference-type UIKit, Combine, Core Data/SQLite, and third-party UI values that are not yet `Sendable`; switching those modules wholesale to Swift 6 would require source-breaking public API changes outside Boardlet's boundary. New Boardlet-facing concurrency is isolated in the Swift 6 leaf packages and the actor/MainActor adapters described above. Future migration should proceed in this order:

1. `ThemeFramework` and `MediaFramework` after replacing callback/KVO utilities with structured async APIs.
2. `PersistenceFramework` after its legacy reference models are fully adapted to `BoardDocument` values.
3. `SharedSwiftUI`, `FeatureFramework`, `RatingFramework`, and `DynavoxSymbols` after their public observable types and third-party UI dependencies publish concurrency-safe APIs.
4. The two application targets after the remaining packages expose Swift 6 interfaces.

No broad `@preconcurrency` or module-wide warning suppression is used to hide new Boardlet isolation violations.
