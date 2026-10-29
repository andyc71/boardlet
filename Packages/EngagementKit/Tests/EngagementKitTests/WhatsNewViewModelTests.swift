import Foundation
import Testing
@testable import EngagementWhatsNew
import EngagementCore
import EngagementContent

@MainActor
struct WhatsNewViewModelTests {
    @Test func freshInstallAndExplicitResetUseSamePolicy() throws {
        let suite = "WhatsNewModelTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = WhatsNewViewModel(locale: "en", in: .module, subdirectory: "Assets", defaults: defaults)
        #expect(model.lastError == nil)
        #expect(model.showWhatsNewScreen == false)
        model.reset()
        #expect(model.showWhatsNewScreen)
        model.dismissWhatsNewScreen()
        #expect(model.showWhatsNewScreen == false)
        let relaunch = WhatsNewViewModel(locale: "en", in: .module, subdirectory: "Assets", defaults: defaults)
        #expect(relaunch.showWhatsNewScreen == false)
    }

    @Test(arguments: ["en", "es", "es_ES", "es-MX", "unavailable", "fr"])
    func localizedLoaderPreservesPrefixAndUsesOneReleaseID(locale: String) throws {
        let suite = "WhatsNewModelTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = WhatsNewViewModel(locale: locale, in: .module, subdirectory: "Assets",
            fileNamePrefix: "WhatsNew", migration: .init(isExistingInstallation: true), defaults: defaults)
        #expect(model.lastError == nil)
        #expect(model.features.count == 4)
        #expect(model.title == (locale.hasPrefix("es") ? "Novedades" : "What's New"))
        #expect(model.showWhatsNewScreen)
        model.dismissWhatsNewScreen()
        model.loadFeatures(for: "en", in: .module, subdirectory: "Assets", fileNamePrefix: "WhatsNew")
        #expect(model.showWhatsNewScreen == false)
    }

    @Test func failedLoadDoesNotBaselineOrPresentStaleContent() throws {
        let suite = "WhatsNewModelTests.\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = WhatsNewViewModel(locale: "en", in: .module, fileNamePrefix: "Missing", defaults: defaults)
        #expect(model.lastError != nil)
        #expect(model.showWhatsNewScreen == false)
        #expect(defaults.bool(forKey: WhatsNewManager.initializedKey) == false)
        model.loadFeatures(for: "en", in: .module, subdirectory: "Assets", fileNamePrefix: "WhatsNew")
        #expect(model.lastError == nil)
        #expect(model.showWhatsNewScreen == false)
        model.reset()
        #expect(model.showWhatsNewScreen)
        model.loadFeatures(for: "en", in: .module, fileNamePrefix: "Missing")
        #expect(model.showWhatsNewScreen == false)
    }
}
