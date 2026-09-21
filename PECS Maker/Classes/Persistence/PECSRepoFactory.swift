import Combine
import PersistenceFramework
import SwiftUI

@MainActor
final class PECSRepoFactory: RepoFactory<PECSRepo>, ObservableObject {
    @Published private(set) var publishedTopics: [PECSRepo] = []
    @Published var publishedCurrentTopic: PECSRepo? {
        didSet {
            if currentTopic != publishedCurrentTopic {
                currentTopic = publishedCurrentTopic
            }
        }
    }
    @Published private(set) var startupError: Error?

    init(
        settings: PersistenceSettingsProtocol,
        storageRoot: URL,
        userDefaults: UserDefaults = .standard,
        loadOnInit: Bool = true
    ) {
        super.init(
            settings: settings,
            documentsDirectory: storageRoot,
            userDefaults: userDefaults
        )
        publishedTopics = availableTopics

        guard loadOnInit else { return }
        do {
            _ = try loadCurrentRepo(
                makeActive: true,
                alternateTopicStrategies: [.createEmptyIfNoTopicsExist]
            )
            publishedCurrentTopic = currentTopic
        } catch {
            startupError = error
        }
    }

    override nonisolated func availableTopicsDidChange() {
        MainActor.assumeIsolated {
            publishedTopics = availableTopics
        }
    }

    override nonisolated func currentTopicDidChange(newValue: PECSRepo?) {
        MainActor.assumeIsolated {
            publishedCurrentTopic = newValue
        }
    }

    override func createEmptyRepo(directoryURL: URL? = nil, setActive: Bool) throws -> PECSRepo {
        try super.createEmptyRepo(directoryURL: directoryURL, setActive: setActive)
    }
}
