import Foundation

/// The single display policy for every What's New entry point.
/// A fresh installation baselines its current release without showing it.
/// Subsequent unseen releases are recorded only when the user continues.
@MainActor
public final class WhatsNewManager {
    public static let initializedKey = "com.brightblue.WhatsNewManager.initialized"
    public static let seenReleaseIDsKey = "com.brightblue.WhatsNewManager.seenReleaseIDs"
    public static let legacyDateKey = "com.brightblue.WhatsNewManager.lastDisplayedFeatureSet"

    public static var whatsNewIsEnabled = true
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func shouldShow(releaseID: String, lastModified: Date, migration: WhatsNewMigration) -> Bool {
        if !defaults.bool(forKey: Self.initializedKey) {
            let oldVersion = migration.legacyVersionKey.flatMap { defaults.string(forKey: $0) }
            let oldDate = defaults.object(forKey: Self.legacyDateKey) as? Date
            let isExisting = migration.isExistingInstallation || oldVersion != nil || oldDate != nil
            // The app's version record takes precedence over its older package date record.
            let alreadySeen = oldVersion.map { $0 == migration.currentVersion } ?? (oldDate == lastModified)
            if !isExisting || alreadySeen {
                markSeen(releaseID)
            }
            defaults.set(true, forKey: Self.initializedKey)
        }
        return Self.whatsNewIsEnabled && !seenReleaseIDs.contains(releaseID)
    }

    public func markSeen(_ releaseID: String) {
        var seen = seenReleaseIDs
        seen.insert(releaseID)
        defaults.set(seen.sorted(), forKey: Self.seenReleaseIDsKey)
        defaults.set(true, forKey: Self.initializedKey)
    }

    private var seenReleaseIDs: Set<String> {
        Set(defaults.stringArray(forKey: Self.seenReleaseIDsKey) ?? [])
    }

    /// Explicit debugging/test reset. Normally forces the current release to be shown.
    /// `forFreshInstall` instead restores the first-install baseline behaviour.
    public static func reset(forFreshInstall: Bool = false, defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: seenReleaseIDsKey)
        defaults.removeObject(forKey: legacyDateKey)
        defaults.set(!forFreshInstall, forKey: initializedKey)
    }
}
