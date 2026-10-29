import Foundation

/// Evidence from an app that predates FeatureFramework's release-ID tracking.
/// This is consumed only when the package has no tracking state of its own.
public struct WhatsNewMigration {
    public let isExistingInstallation: Bool
    public let legacyVersionKey: String?
    public let currentVersion: String?

    public init(isExistingInstallation: Bool = false,
                legacyVersionKey: String? = nil,
                currentVersion: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) {
        self.isExistingInstallation = isExistingInstallation
        self.legacyVersionKey = legacyVersionKey
        self.currentVersion = currentVersion
    }
}
