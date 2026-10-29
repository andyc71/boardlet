import Foundation
import Combine
import EngagementCore
import EngagementContent

/// Loads release notes and applies EngagementKit's shared display policy.
/// ObservableObject is retained for source compatibility and iOS 16 support.
@MainActor
public final class WhatsNewViewModel: FeaturesViewModelProtocol {
    @Published public var title = ""
    @Published public var header: String?
    @Published public var footer: String?
    @Published public var buttonTitle = ""
    public let iconPosition: FeatureIconPosition = .leading
    public let canVote = false
    @Published public var features: [Feature] = []
    @Published public var lastModified: Date?
    @Published public private(set) var lastError: Error?
    @Published public private(set) var showWhatsNewScreen = false
    public private(set) var releaseID: String?
    public let coordinator: EngagementCoordinator
    private let manager: WhatsNewManager
    private let migration: WhatsNewMigration

    public init(locale: String, in bundle: Bundle = .main, subdirectory: String? = nil,
                fileNamePrefix: String? = nil, migration: WhatsNewMigration = .init(),
                defaults: UserDefaults = .standard, coordinator: EngagementCoordinator? = nil) {
        let coordinator = coordinator ?? EngagementCoordinator(defaults: defaults,
            marketingVersion: migration.currentVersion ?? "")
        self.coordinator = coordinator
        manager = coordinator.whatsNew
        self.migration = migration
        self.defaults = coordinator.defaults
        loadFeatures(for: locale, in: bundle, subdirectory: subdirectory, fileNamePrefix: fileNamePrefix)
    }

    private let defaults: UserDefaults

    public func reset() {
        WhatsNewManager.reset(defaults: defaults)
        updatePrompts()
    }

    public func loadFeatures(for locale: String, in bundle: Bundle, subdirectory: String? = nil,
                             fileNamePrefix: String? = nil) {
        do {
            let response = try FeaturesResponse.load(for: locale, in: bundle,
                subdirectory: subdirectory, fileNamePrefix: fileNamePrefix)
            title = response.title
            header = response.header
            footer = response.footer
            buttonTitle = response.buttonTitle
            features = response.features
            lastModified = response.lastModified
            releaseID = response.effectiveReleaseID
            lastError = nil
            updatePrompts()
        } catch {
            lastError = error
            releaseID = nil
            showWhatsNewScreen = false
        }
    }

    public func updatePrompts() {
        guard let releaseID, let lastModified else { return }
        showWhatsNewScreen = manager.shouldShow(releaseID: releaseID, lastModified: lastModified,
                                                migration: migration)
    }

    public func dismissWhatsNewScreen() {
        guard let releaseID else { return }
        manager.markSeen(releaseID)
        showWhatsNewScreen = false
        coordinator.finish(.whatsNew(releaseID))
    }

    public func isLastFeature(_ feature: Feature) -> Bool { features.last?.id == feature.id }
    public func dismissFeaturesView() { dismissWhatsNewScreen() }
    public func handleVote(for feature: Feature) {}
}
