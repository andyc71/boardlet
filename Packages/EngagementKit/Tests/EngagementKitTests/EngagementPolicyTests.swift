import Foundation
import Testing
import EngagementKit

@MainActor
struct EngagementPolicyTests {
    private let safe = EngagementContext(isActive: true, isLibrary: true)

    @Test func defaultsRequireAgeDaysAndMeaningfulCompletions() throws {
        try withFixture { defaults, clock in
            let model = make(defaults, clock)
            for _ in 0..<20 { model.recordActiveDay() }
            #expect(model.history.activeDays.count == 1)
            for _ in 0..<3 { model.recordCompletion(.shareBoard, id: UUID()) }
            #expect(model.solicit(at: UUID(), context: safe, campaignID: "one") == nil)
            clock.date.addTimeInterval(86_400)
            model.recordActiveDay()
            clock.date.addTimeInterval(13 * 86_400 - 1)
            model.recordActiveDay()
            #expect(model.solicit(at: UUID(), context: safe, campaignID: "one") == nil)
            clock.date.addTimeInterval(1)
            #expect(model.solicit(at: UUID(), context: safe, campaignID: "one") == .voting("one"))
        }
    }

    @Test(arguments: [0, 1, 2, 3])
    func workflowThresholdsAreChannelSpecific(count: Int) throws {
        try withFixture { defaults, clock in
            let model = mature(defaults, clock, count: count)
            var policy = model.policy
            policy.votingEnabled = false
            model.policy = policy
            #expect(model.solicit(at: UUID(), context: safe) == (count >= 3 ? .review : nil))
        }
        try withFixture { defaults, clock in
            let model = mature(defaults, clock, count: count)
            #expect(model.solicit(at: UUID(), context: safe, campaignID: "one") == (count >= 2 ? .voting("one") : nil))
        }
    }

    @Test func reviewAlsoDelaysVotingForThirtyDays() throws {
        try withFixture { defaults, clock in
            let model = mature(defaults, clock)
            #expect(model.solicit(at: UUID(), context: safe) == .review)
            clock.date.addTimeInterval(30 * 86_400 - 1)
            #expect(make(defaults, clock).solicit(at: UUID(), context: safe, campaignID: "one") == nil)
            clock.date.addTimeInterval(1)
            #expect(make(defaults, clock).solicit(at: UUID(), context: safe, campaignID: "one") == .voting("one"))
        }
    }

    @Test func duplicateCallbacksAreIdempotentAcrossLaunches() throws {
        try withFixture { defaults, clock in
            let id = UUID()
            let model = make(defaults, clock)
            model.recordCompletion(.exportBoard, id: id)
            model.recordCompletion(.exportBoard, id: id)
            let relaunched = make(defaults, clock)
            relaunched.recordCompletion(.exportBoard, id: id)
            #expect(relaunched.history.completedWorkflows == 1)
            #expect(relaunched.history.ratingWorkflows == 1)
        }
    }

    @Test func saveWorkflowsCanQualifyVotingButNeverRatings() throws {
        try withFixture { defaults, clock in
            let model = mature(defaults, clock, workflow: .saveBoard)
            #expect(model.solicit(at: UUID(), context: safe) == nil)
            #expect(model.solicit(at: UUID(), context: safe, campaignID: "one") == .voting("one"))
        }
    }

    @Test(arguments: ["inactive", "editor", "modal", "welcome", "whatsNew", "notLibrary"])
    func blockedOpportunitiesAreDiscarded(blocker: String) throws {
        try withFixture { defaults, clock in
            let model = mature(defaults, clock)
            var context = safe
            switch blocker {
            case "inactive": context.isActive = false
            case "editor": context.isEditing = true
            case "modal": context.hasModalOrSystemActivity = true
            case "welcome": context.welcomePending = true
            case "whatsNew": context.whatsNewPending = true
            default: context.isLibrary = false
            }
            let opportunity = UUID()
            #expect(model.solicit(at: opportunity, context: context, campaignID: "one") == nil)
            #expect(model.solicit(at: opportunity, context: safe, campaignID: "one") == nil)
            #expect(model.history.lastSolicitation == nil)
        }
    }

    @Test(arguments: [EngagementPresentation.tip("education"), .whatsNew("release")])
    func educationSuppressesWholeSession(presentation: EngagementPresentation) throws {
        try withFixture { defaults, clock in
            let model = mature(defaults, clock)
            #expect(model.beginEducation(presentation, context: safe))
            model.finish(presentation)
            #expect(model.solicit(at: UUID(), context: safe, campaignID: "one") == nil)
            #expect(model.history.lastSolicitation == nil)
        }
    }

    @Test func whatsNewTakesPriorityOverTipsAndMultipleScenesCannotClaim() throws {
        try withFixture { defaults, clock in
            let model = mature(defaults, clock)
            var context = safe
            context.whatsNewPending = true
            #expect(!model.beginEducation(.tip("help"), context: context))
            #expect(model.beginEducation(.whatsNew("release"), context: context))
            #expect(!model.beginEducation(.whatsNew("release"), context: context))
            #expect(model.solicit(at: UUID(), context: safe, campaignID: "one") == nil)
        }
    }

    @Test func dismissedCampaignNeverRepromptsAndNewCampaignWaitsNinetyDays() throws {
        try withFixture { defaults, clock in
            let model = mature(defaults, clock)
            #expect(model.solicit(at: UUID(), context: safe, campaignID: "one") == .voting("one"))
            model.dismissCampaign("one")
            #expect(model.solicit(at: UUID(), context: safe) == nil)
            clock.date.addTimeInterval(90 * 86_400 - 1)
            var policy = EngagementPolicy()
            policy.ratingsEnabled = false
            #expect(make(defaults, clock, policy: policy).solicit(at: UUID(), context: safe, campaignID: "two") == nil)
            clock.date.addTimeInterval(1)
            let relaunched = make(defaults, clock, policy: policy)
            #expect(relaunched.solicit(at: UUID(), context: safe, campaignID: "one") == nil)
            #expect(relaunched.solicit(at: UUID(), context: safe, campaignID: "two") == .voting("two"))
        }
    }

    @Test func votingAndReviewsShareThirtyDayCooldown() throws {
        try withFixture { defaults, clock in
            let model = mature(defaults, clock)
            #expect(model.solicit(at: UUID(), context: safe, campaignID: "one") == .voting("one"))
            clock.date.addTimeInterval(30 * 86_400 - 1)
            #expect(make(defaults, clock).solicit(at: UUID(), context: safe) == nil)
            clock.date.addTimeInterval(1)
            #expect(make(defaults, clock).solicit(at: UUID(), context: safe) == .review)
        }
    }

    @Test func reviewsAreAttemptsLimitedByVersionAndOneHundredTwentyDays() throws {
        try withFixture { defaults, clock in
            let model = mature(defaults, clock)
            var requests = 0
            var recordedBeforeRequest = false
            let attempted = ReviewRequest.attempt(coordinator: model, opportunity: UUID(), context: safe) {
                requests += 1
                recordedBeforeRequest = model.history.lastReviewAttempt == clock.date
            }
            #expect(attempted)
            #expect(recordedBeforeRequest)
            #expect(requests == 1)
            #expect(model.activePresentation == nil)
            clock.date.addTimeInterval(120 * 86_400 - 1)
            #expect(make(defaults, clock, version: "2").solicit(at: UUID(), context: safe) == nil)
            clock.date.addTimeInterval(1)
            #expect(make(defaults, clock).solicit(at: UUID(), context: safe) == nil)
            #expect(make(defaults, clock, version: "2").solicit(at: UUID(), context: safe) == .review)
        }
    }

    @Test(arguments: ["dismissedPromptDate", "lastVotedDate"])
    func legacyVotingDecisionSurvivesCampaignCopyChanges(key: String) throws {
        try withFixture { defaults, clock in
            defaults.set(clock.date, forKey: "com.brightblue.VotingManager.\(key)")
            let model = mature(defaults, clock)
            model.registerCampaign("stable")
            #expect(model.history.invitedCampaignIDs.contains("stable"))
            clock.date.addTimeInterval(100 * 86_400)
            var policy = EngagementPolicy()
            policy.ratingsEnabled = false
            let relaunched = make(defaults, clock, policy: policy)
            #expect(relaunched.solicit(at: UUID(), context: safe, campaignID: "stable") == nil)
            #expect(relaunched.solicit(at: UUID(), context: safe, campaignID: "new") == .voting("new"))
        }
    }

    @Test func ratingsOnlyClientHonorsLegacyVotingCooldownWithoutCampaignRegistration() throws {
        try withFixture { defaults, clock in
            defaults.set(clock.date, forKey: "com.brightblue.VotingManager.dismissedPromptDate")
            let model = mature(defaults, clock)
            #expect(model.solicit(at: UUID(), context: safe) == nil)
            clock.date.addTimeInterval(16 * 86_400)
            #expect(make(defaults, clock).solicit(at: UUID(), context: safe) == .review)
        }
    }

    @Test func migratesRatingAttemptWithoutClaimingSubmissionOrImportingGenericEvents() throws {
        try withFixture { defaults, clock in
            defaults.set(clock.date, forKey: "lastPromptDate")
            defaults.set("14988", forKey: "lastUsedVersion")
            defaults.set(true, forKey: "dontReview")
            defaults.set(999, forKey: "reviewWorthyActionCount")
            let model = make(defaults, clock)
            #expect(model.history.lastReviewAttempt == clock.date)
            #expect(model.history.attemptedVersions == ["1"])
            #expect(model.history.completedWorkflows == 0)
        }
    }

    @Test func userInitiatedInteractionRemainsAvailableAndSuppressesFollowup() throws {
        try withFixture { defaults, clock in
            let model = make(defaults, clock)
            model.recordVote(campaignID: "one")
            #expect(model.history.votedCampaignIDs == ["one"])
            #expect(model.sessionSuppressed)
            #expect(model.history.lastReviewAttempt == nil)
            #expect(ReviewRequest.writeReviewURL(appURL: URL(string: "https://apps.apple.com/app/id123")!)?.query == "action=write-review")
        }
    }

    private func make(_ defaults: UserDefaults, _ clock: TestClock, version: String = "1",
                      policy: EngagementPolicy = .init()) -> EngagementCoordinator {
        EngagementCoordinator(defaults: defaults, marketingVersion: version, policy: policy, now: { clock.date })
    }

    private func mature(_ defaults: UserDefaults, _ clock: TestClock,
                        workflow: CompletedWorkflow = .shareBoard, count: Int = 3) -> EngagementCoordinator {
        let model = make(defaults, clock)
        for _ in 0..<count { model.recordCompletion(workflow, id: UUID()) }
        clock.date.addTimeInterval(86_400)
        model.recordActiveDay()
        clock.date.addTimeInterval(13 * 86_400)
        model.recordActiveDay()
        return model
    }

    private func withFixture(_ body: (UserDefaults, TestClock) throws -> Void) throws {
        let suite = "EngagementTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        try body(defaults, TestClock())
    }
}

@MainActor
private final class TestClock {
    var date = Date(timeIntervalSince1970: 1_700_000_000)
}
