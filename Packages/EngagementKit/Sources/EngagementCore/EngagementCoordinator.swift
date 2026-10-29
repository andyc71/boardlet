import Foundation
import Combine

/// One instance per app process, shared by all scenes and modules. Main-actor claims are atomic.
/// ObservableObject preserves iOS 16 support. No timers, deferred prompts or automatic retries.
@MainActor
public final class EngagementCoordinator: ObservableObject {
    public static let historyKey = "com.brightblue.EngagementKit.history.v1"
    @Published public private(set) var history: EngagementHistory
    @Published public private(set) var activePresentation: EngagementPresentation?
    @Published public private(set) var sessionSuppressed = false
    public var policy: EngagementPolicy
    public let marketingVersion: String
    public let defaults: UserDefaults
    public let whatsNew: WhatsNewManager
    private let now: () -> Date
    private var opportunities: Set<UUID> = []

    public init(defaults: UserDefaults = .standard, marketingVersion: String,
                policy: EngagementPolicy = .init(), now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.whatsNew = WhatsNewManager(defaults: defaults)
        self.marketingVersion = marketingVersion
        self.policy = policy
        self.now = now
        if let data = defaults.data(forKey: Self.historyKey),
           let stored = try? JSONDecoder().decode(EngagementHistory.self, from: data) {
            history = stored
        } else {
            // Unknown install age and old generic action counts are not evidence of engagement.
            history = EngagementHistory(firstUse: now())
            history.lastReviewAttempt = defaults.object(forKey: "lastPromptDate") as? Date
            history.lastSolicitation = history.lastReviewAttempt
            // RatingFramework used build numbers. They cannot be mapped back to marketing versions.
            // Preserve any explicit legacy decision conservatively for this marketing version.
            if defaults.string(forKey: "lastReviewRequestAppVersion") != nil
                || defaults.bool(forKey: "dontReview") || defaults.bool(forKey: "lastUsedVersionIsRated") {
                history.attemptedVersions.insert(marketingVersion)
            }
        }
        // Ratings-only clients still inherit the shared cooldown from legacy voting.
        if !history.migratedVoting {
            let legacyDates = ["com.brightblue.VotingManager.dismissedPromptDate",
                               "com.brightblue.VotingManager.lastVotedDate"]
                .compactMap { defaults.object(forKey: $0) as? Date }
            if let date = legacyDates.max() {
                history.lastVotingInvitation = max(history.lastVotingInvitation ?? date, date)
                history.lastSolicitation = max(history.lastSolicitation ?? date, date)
            }
        }
        recordActiveDay()
    }

    /// A session is the process lifetime. Foreground transitions record days, but do not reset suppression.
    public func recordActiveDay() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        let day = calendar.dateComponents([.year, .month, .day], from: now())
        history.activeDays.insert("\(day.year ?? 0)-\(day.month ?? 0)-\(day.day ?? 0)")
        persist()
    }

    /// Stable operation IDs make duplicate completion callbacks harmless, including across launches.
    public func recordCompletion(_ workflow: CompletedWorkflow, id: UUID) {
        guard history.completedWorkflowIDs.insert(id.uuidString).inserted else { return }
        recordActiveDay()
        history.completedWorkflows += 1
        if workflow.isRatingWorthy { history.ratingWorkflows += 1 }
        persist()
    }

    /// Bind legacy dismissal/vote evidence to the current campaign once, independent of copy dates.
    public func registerCampaign(_ campaignID: String) {
        guard !campaignID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !history.migratedVoting else { return }
        let dismissal = defaults.object(forKey: "com.brightblue.VotingManager.dismissedPromptDate") as? Date
        let vote = defaults.object(forKey: "com.brightblue.VotingManager.lastVotedDate") as? Date
        if dismissal != nil { history.dismissedCampaignIDs.insert(campaignID) }
        if vote != nil { history.votedCampaignIDs.insert(campaignID) }
        if let date = [dismissal, vote].compactMap({ $0 }).max() {
            history.invitedCampaignIDs.insert(campaignID)
            history.lastVotingInvitation = date
            history.lastSolicitation = max(history.lastSolicitation ?? date, date)
        }
        history.migratedVoting = true
        persist()
    }

    /// Priority: welcome/system/editing blocks all; What's New > education > voting > ratings.
    /// Pass a new opportunity only for a meaningful safe boundary, not when a blocker dismisses.
    public func solicit(at opportunity: UUID, context: EngagementContext,
                        campaignID: String? = nil) -> EngagementPresentation? {
        guard opportunities.insert(opportunity).inserted else { return nil }
        guard context.permitsSolicitation, activePresentation == nil, !sessionSuppressed,
              now().timeIntervalSince(history.firstUse) >= policy.minimumInstallAge,
              history.activeDays.count >= policy.minimumActiveDays,
              elapsed(since: history.lastSolicitation, atLeast: policy.solicitationInterval) else { return nil }
        if let campaignID, !campaignID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            registerCampaign(campaignID)
            // Migration can introduce a more recent cross-channel cooldown.
            guard elapsed(since: history.lastSolicitation, atLeast: policy.solicitationInterval) else { return nil }
            if policy.votingEnabled, history.completedWorkflows >= policy.votingWorkflowCount,
               !history.invitedCampaignIDs.contains(campaignID),
               elapsed(since: history.lastVotingInvitation, atLeast: policy.votingCampaignInterval) {
                history.invitedCampaignIDs.insert(campaignID)
                history.lastVotingInvitation = now()
                return claimSolicitation(.voting(campaignID))
            }
        }
        if policy.ratingsEnabled, !marketingVersion.isEmpty,
           history.ratingWorkflows >= policy.ratingWorkflowCount,
           !history.attemptedVersions.contains(marketingVersion),
           elapsed(since: history.lastReviewAttempt, atLeast: policy.ratingAttemptInterval) {
            // This is an attempt; StoreKit provides no display or submission confirmation.
            history.attemptedVersions.insert(marketingVersion)
            history.lastReviewAttempt = now()
            return claimSolicitation(.review)
        }
        return nil
    }

    private func claimSolicitation(_ presentation: EngagementPresentation) -> EngagementPresentation {
        history.lastSolicitation = now()
        sessionSuppressed = true
        activePresentation = presentation
        persist()
        return presentation
    }

    /// TipKit supplies individual eligibility. The coordinator only grants the opportunity.
    public func beginEducation(_ presentation: EngagementPresentation, context: EngagementContext) -> Bool {
        guard context.permitsPresentation, activePresentation == nil else { return false }
        switch presentation {
        case .whatsNew: break
        case .tip: guard !context.whatsNewPending, !sessionSuppressed else { return false }
        default: return false
        }
        sessionSuppressed = true
        activePresentation = presentation
        return true
    }

    public func finish(_ presentation: EngagementPresentation) {
        if activePresentation == presentation { activePresentation = nil }
    }

    public func dismissCampaign(_ campaignID: String) {
        history.dismissedCampaignIDs.insert(campaignID)
        history.invitedCampaignIDs.insert(campaignID)
        finish(.voting(campaignID))
        persist()
    }

    /// Explicit user actions bypass automatic eligibility, but prevent an automatic follow-up.
    public func recordUserInitiatedInteraction() { sessionSuppressed = true }

    public func recordVote(campaignID: String) {
        history.votedCampaignIDs.insert(campaignID)
        history.invitedCampaignIDs.insert(campaignID)
        recordUserInitiatedInteraction()
        finish(.voting(campaignID))
        persist()
    }

    private func elapsed(since date: Date?, atLeast interval: TimeInterval) -> Bool {
        date.map { now().timeIntervalSince($0) >= interval } ?? true
    }

    private func persist() {
        // All fields are known Codable values; keep existing state if encoding ever fails.
        if let data = try? JSONEncoder().encode(history) { defaults.set(data, forKey: Self.historyKey) }
    }
}
