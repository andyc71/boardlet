import Foundation
import Testing
import EngagementKit

@MainActor
struct VotingModelTests {
    @Test func explicitVoteWorksBeforeAutomaticEligibilityAndCallsServiceOnce() throws {
        let suite = "VotingModelTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let coordinator = EngagementCoordinator(defaults: defaults, marketingVersion: "1")
        let service = VotingServiceSpy()
        let model = FeaturesViewModel(featureSettings: TestFeatureSettings(service: service), coordinator: coordinator)
        model.loadFeatures(for: "en", in: .module, subdirectory: "Assets")
        let feature = try #require(model.features.first)
        #expect(model.votingPromptError == nil)
        model.openVoting()
        model.handleVote(for: feature)
        #expect(service.votes == [feature.id])
        #expect(model.showThankYouAlert)
        #expect(coordinator.sessionSuppressed)
        #expect(coordinator.history.lastReviewAttempt == nil)
        #expect(coordinator.history.votedCampaignIDs == ["test-campaign"])
        model.dismissFeaturesView()
        model.featuresViewDidDismiss()
        model.featuresViewDidDismiss()
        #expect(service.listDismissals == 1)
        #expect(service.dismissals == 0)
    }

    @Test func dismissalIsBoundToCampaignAndFailedLoadClearsStaleContent() throws {
        let suite = "VotingModelTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let coordinator = EngagementCoordinator(defaults: defaults, marketingVersion: "1")
        let service = VotingServiceSpy()
        let model = FeaturesViewModel(featureSettings: TestFeatureSettings(service: service), coordinator: coordinator)
        model.loadFeatures(for: "en", in: .module, subdirectory: "Assets")
        model.dismissPrompt()
        #expect(service.dismissals == 1)
        #expect(coordinator.history.dismissedCampaignIDs == ["test-campaign"])
        model.loadFeatures(for: "en", in: .module, subdirectory: "missing")
        #expect(model.campaignID == nil)
        #expect(model.features.isEmpty)
        #expect(model.votingPromptError != nil)
    }
}

private struct TestFeatureSettings: FeatureSettings {
    let service: VotingServiceSpy
    var featureRequestEmailAddress: String { "feedback@example.com" }
    var featureRequestEmailSubject: String { "Feedback" }
    var featureRequestEmailBody: String { "" }
    var featureRequestLocale: String { "en" }
    var featureVotingService: FeatureVotingService? { service }
}

private final class VotingServiceSpy: FeatureVotingService {
    var votes: [String] = []
    var dismissals = 0
    var listDismissals = 0
    func voteForFeature(feature: Feature) { votes.append(feature.id) }
    func dismissVotingPrompt() { dismissals += 1 }
    func dismissFeatureList() { listDismissals += 1 }
}
