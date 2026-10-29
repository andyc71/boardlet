import Foundation
import Testing
@testable import EngagementWhatsNew
import EngagementCore
import EngagementContent

@MainActor
struct WhatsNewLogicTests {
    @Test func freshInstallBaselinesThenShowsNextReleaseUntilContinued() throws {
        let suite = "WhatsNewTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let date = Date(timeIntervalSince1970: 100)
        let manager = WhatsNewManager(defaults: defaults)
        #expect(manager.shouldShow(releaseID: "one", lastModified: date, migration: .init()) == false)
        let relaunched = WhatsNewManager(defaults: defaults)
        #expect(relaunched.shouldShow(releaseID: "one", lastModified: date.addingTimeInterval(1), migration: .init()) == false)
        #expect(relaunched.shouldShow(releaseID: "two", lastModified: date, migration: .init()))
        // An interrupted presentation is not acknowledged.
        #expect(WhatsNewManager(defaults: defaults).shouldShow(releaseID: "two", lastModified: date, migration: .init()))
        relaunched.markSeen("two")
        #expect(relaunched.shouldShow(releaseID: "two", lastModified: date, migration: .init()) == false)
        #expect(relaunched.shouldShow(releaseID: "one", lastModified: date, migration: .init()) == false)
    }

    @Test(arguments: [true, false])
    func migratesLegacyDate(alreadySeen: Bool) throws {
        let suite = "WhatsNewTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let date = Date(timeIntervalSince1970: 100)
        defaults.set(alreadySeen ? date : date.addingTimeInterval(-1), forKey: WhatsNewManager.legacyDateKey)
        let manager = WhatsNewManager(defaults: defaults)
        #expect(manager.shouldShow(releaseID: "one", lastModified: date, migration: .init()) == !alreadySeen)
        #expect(manager.shouldShow(releaseID: "two", lastModified: date, migration: .init()))
    }

    @Test(arguments: ["4.0", "3.0"])
    func migratesAppVersionOnceTakingPrecedenceOverOlderDateRecord(version: String) throws {
        let suite = "WhatsNewTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let date = Date(timeIntervalSince1970: 100)
        defaults.set(version, forKey: "old.version")
        defaults.set(date, forKey: WhatsNewManager.legacyDateKey)
        let migration = WhatsNewMigration(legacyVersionKey: "old.version", currentVersion: "4.0")
        let manager = WhatsNewManager(defaults: defaults)
        #expect(manager.shouldShow(releaseID: "one", lastModified: date, migration: migration) == (version != "4.0"))
        #expect(manager.shouldShow(releaseID: "two", lastModified: date, migration: migration))
    }

    @Test func existingInstallWithoutPriorNotesIsNotTreatedAsFresh() throws {
        let suite = "WhatsNewTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        #expect(WhatsNewManager(defaults: defaults).shouldShow(releaseID: "one", lastModified: Date(),
                                                            migration: .init(isExistingInstallation: true)))
    }
}
