# EngagementKit

Reusable engagement policy and presentation for iOS 16+. Boardlet and Easy PECS Plus retain iOS **16.6** and Swift 5. The package consolidates the working FeatureFramework release-note renderer/migration and replaces RatingFramework's rating pre-screen with native StoreKit attempts. Existing framework checkouts remain untouched for other consumers.

## Products

| Product | Responsibility |
| --- | --- |
| EngagementCore | Main-actor coordinator, persisted workflow/solicitation history, migration, priority and session arbitration. Foundation/Combine only. |
| EngagementRatings | Review-attempt adapter and user-initiated App Store review URL. |
| EngagementVoting | Inline campaign invitation, explicit voting, analytics/service callbacks and separate private email feedback. |
| EngagementWhatsNew | Localized content loader, release-ID migration and the existing adaptive sheet renderer. |
| EngagementTipKit | Optional iOS 17+ educational TipKit adapter. Not linked by the umbrella product. |
| EngagementKit | Re-exports core, ratings, voting, release notes and shared content types for convenient integration. |

`EngagementContent` is an internal shared target for localized feature content and rows. Existing SharedSwiftUI and MailFramework dependencies support the existing theme and mail UI. The core does not depend on those frameworks, UIKit, StoreKit or TipKit.

## Integration contract

Create **one coordinator per app process**, shared by every scene and module. Supply a marketing version (never the build number), a defaults store, and optional policy overrides. The clock is injectable for deterministic tests. `ObservableObject` is intentional for iOS 16 compatibility.

```swift
let engagement = EngagementCoordinator(
    marketingVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
)
let voting = FeaturesViewModel(featureSettings: settings, coordinator: engagement)
let whatsNew = WhatsNewViewModel(locale: "en", fileNamePrefix: "WhatsNew",
    migration: .init(isExistingInstallation: hasExistingData,
                     legacyVersionKey: "startup.lastSeenVersion"),
    coordinator: engagement)
```

The app supplies **facts**, not a second engagement coordinator:

- Call `recordActiveDay()` when a scene becomes active. Days are distinct UTC calendar days; repeated launches do not add days. A session lasts for the process lifetime, including background/foreground transitions.
- Call `recordCompletion(_:id:)` only after a successful print, export, share, or save. Allocate one UUID at operation start and reuse it for duplicate completion callbacks. Cancellation, errors, navigation, sheet opening and alerts closing are not completions. `saveBoard` qualifies for voting only.
- At a deliberate library entry, pass `EngagementContext` with current scene activity, library/editing state, welcome/release-note state and modal/system activity. Unknown context defaults to blocked. Check actual scene presentation state as well as local sheet/alert state.
- Pass a fresh opportunity ID at that boundary. A blocked opportunity is consumed; there is **no queue**, timer or automatic retry when a modal dismisses. Never call from an observer whose only trigger is a blocker becoming false.
- Mount `VotingPromptView` inline in the library and `.votingPresentation()` once at the scene root. Both use the same `FeaturesViewModel` environment object. `considerInvitation` arbitrates voting versus ratings and accepts the scene's SwiftUI `requestReview` action.
- Attach `.whatsNewOverlay(viewModel:isReady:)` after welcome is ready. The package claims education priority and suppresses solicitations for the process session.

## Default policy

| Channel | Minimum evidence | Frequency |
| --- | --- | --- |
| Voting invitation | 14 elapsed days, 3 distinct active days, 2 completed workflows | Once per stable campaign; at least 90 days between campaigns |
| Native review attempt | 14 elapsed days, 3 active days, 3 completed print/export/share workflows | At least 120 days between attempts; once per marketing version |
| Both | Active library with no editing, welcome, release notes or modal/system activity | Shared 30-day cooldown and at most one automatic solicitation per process session |

Welcome/system activity/editing blocks presentations. Pending What's New blocks tips and solicitations; a shown tip or What's New suppresses solicitations for the session. Voting wins over ratings when both qualify at an opportunity. Dismissing anything does not drain a prompt backlog.

An invitation is recorded when granted to its inline host. An interrupted or navigated-away invitation is not reissued on the next launch. A review request is recorded **before** calling StoreKit, as an **attempt** only. There is no claim that Apple displayed a dialog or that a user submitted a review. There is no sentiment pre-screen. See [Apple's RequestReviewAction](https://developer.apple.com/documentation/storekit/requestreviewaction).

User-initiated feedback, voting and review links bypass automatic eligibility. `recordUserInitiatedInteraction()` suppresses follow-up solicitations without claiming a review attempt. Explicit review buttons open the App Store's `action=write-review` URL; private feedback remains a separate email action.

## Identity and migration

Voting JSON must declare a nonblank `campaignID`, identical across locales. Missing IDs disable automatic invitations while allowing explicit access. Copy, locale and `lastModified` updates never create a new campaign. The production campaign is `boardlet-feature-priorities-2026`.

At first registration, the coordinator binds old `com.brightblue.VotingManager.dismissedPromptDate` and `lastVotedDate` evidence to the current campaign and preserves its cooldown. It does not import the old generic event counter. Unknown install age starts at first EngagementKit use, deliberately conservative. Existing rating prompt dates preserve cooldowns; legacy review/version preferences are imported conservatively.

What's New retains `com.brightblue.WhatsNewManager.*` keys and release-ID semantics. A fresh installation silently baselines the current release. Existing app data without prior evidence is eligible. Before initialization only, `startup.lastSeenVersion` takes precedence over the legacy displayed-date key. After initialization, only release IDs matter. Continue marks seen; interrupted presentation does not. The existing `2026-10-ios27` release ID is unchanged.

History is scoped by the supplied UserDefaults suite, so the two apps retain independent engagement histories. Do not reset it on ordinary debug launches. Test fixtures must opt in explicitly.

## Optional TipKit

Link `EngagementTipKit` only where needed. Configure `Tips` once in the app. On iOS 17+, supply an educational `Tip` to `EngagementTipView(tip, coordinator:context:)`. TipKit owns that tip's rules, events, eligibility and datastore; the coordinator only grants a presentation opportunity and session exclusion. A blocked opportunity is discarded. A change to unsafe context withdraws the tip and does not retry it automatically.

Keep ordinary inline help outside the availability check on iOS 16. No onboarding tour is added to either production app. For iOS 18+ apps using [TipGroup](https://developer.apple.com/documentation/tipkit/tipgroup), select its current tip using TipKit, then pass that tip through the same adapter. Gate all TipGroup use with `if #available(iOS 18.0, *)`. Group sequencing stays in TipKit, not EngagementKit history.

## Verification

See [the app integration and exact verification commands](../../documentation/EngagementKit.md). The shared package Xcode scheme includes all package tests and compiles the optional TipKit adapter. Run on an iOS simulator: the renderer and mail integration are iOS modules, so a macOS `swift test` does not build the whole package.
