//
//  PECS_MakerApp.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import Firebase
import FirebaseAnalytics
import LogFrameworkFirebase
import LogFramework
import Combine
import SharedSwiftUI
import PersistenceFramework
import EngagementKit
import SettingsFramework

@main
struct PECS_MakerApp: App {
    
    @State var topicToEdit: PECSRepo?

    private var cancellable: AnyCancellable?
    
    var currentTheme: SharedUITheme
    private var startup = StartupExperience()
    private var startupScreen: StartupExperience.Screen = .content
    private var whatsNewViewModel: WhatsNewViewModel?
    private var engagement: EngagementCoordinator
    private var featuresViewModel: FeaturesViewModel

    init() {
        currentTheme = Self.setupTheme()
#if DEBUG
        Self.prepareEngagementTestFixture()
#endif
        var policy = EngagementPolicy()
        policy.ratingsEnabled = !CommandLine.arguments.contains(LaunchArguments.noRatings)
        policy.votingEnabled = !CommandLine.arguments.contains(LaunchArguments.noFeatureVoting)
        let coordinator = EngagementCoordinator(marketingVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "", policy: policy)
        engagement = coordinator
        featuresViewModel = FeaturesViewModel(featureSettings: AppSettings.shared, coordinator: coordinator)
        
        processArguments()
        startup.prepare(documents: RepoHelper.documentsDirectory)
        startup.applyEditionPreferences()
        startupScreen = startup.screen
#if DEBUG
        if ProcessInfo.processInfo.environment["PECS_TEST_STARTUP"] == "skip" {
            startupScreen = .content
        }
#endif
        whatsNewViewModel = WhatsNewViewModel(
            locale: AppSettings.shared.currentLanguageCode,
            fileNamePrefix: "WhatsNew",
            migration: WhatsNewMigration(
                isExistingInstallation: startup.screen != .welcome,
                legacyVersionKey: StartupExperience.legacyLastSeenVersionKey
            ),
            coordinator: engagement
        )
        setupAnalytics()
        
        PersistenceSettings.shared = PECSPersistenceSettings()

        // Isolated UI-test libraries retain their explicitly supplied fixtures.
        if startupScreen != .welcome,
           !CommandLine.arguments.contains(where: { $0.hasPrefix(LaunchArguments.docDir + ":") }),
           let source = Bundle.main.url(forResource: "StarterBoards", withExtension: nil) {
            do {
                try StarterBoardInstaller.install(from: source, into: RepoHelper.documentsDirectory,
                                                  language: Bundle.main.preferredLocalizations.first ?? "en")
            } catch {
                logger.logError(.repo, "Could not install starter boards: \(error.localizedDescription)")
            }
        }
        
        //Set up the default nav bar which will be used by all the child pages.
        //For the main page page, we will hide the default nav bar and display our own title.
        
        NavigationBar.configure()
        //UINavigationBar.mfSetup(outlineText: true)
        
        logger.isDetailedLoggingEnabled = UserDefaultsConfig.shared.isDebugLoggingEnabled
        
        cancellable = UserDefaultsConfig.shared.objectWillChange.sink {
            logger.isDetailedLoggingEnabled = UserDefaultsConfig.shared.isDebugLoggingEnabled
        }
        
        //topicToEdit = PECSRepoFactory.shared.publishedTopics.first
        
    }
    
    @StateObject var repoFactory = PECSRepoFactory.shared
    
    var body: some Scene {
        WindowGroup {
            if let whatsNewViewModel {
                BoardletRootView(
                    repoFactory: repoFactory,
                    engagement: engagement,
                    featuresViewModel: featuresViewModel,
                    currentTheme: currentTheme,
                    startup: startup,
                    startupScreen: startupScreen,
                    whatsNewViewModel: whatsNewViewModel
                )
            }
        }
        
    }
    
    static private func setupTheme() -> SharedUITheme {
        let currentTheme = SharedUITheme()
        
        currentTheme.headerStyle.fontName = Theme.headerFontName
        currentTheme.cardBackgroundColor = Theme.cardBackgroundColor

        return currentTheme
        
    }
    
    func setupAnalytics() {
        
        if CommandLine.arguments.contains(LaunchArguments.noAnalytics) {
            return
        }
        
        logger = FirebaseLogger()
        
        MFAnalytics.setup()
    }
    
#if DEBUG
    /// Explicit isolated UI-test fixtures only. Normal debug launches retain all engagement history.
    private static func prepareEngagementTestFixture() {
        guard CommandLine.arguments.contains(where: { $0.hasPrefix(LaunchArguments.docDir + ":") }),
              let fixture = ProcessInfo.processInfo.environment["PECS_TEST_ENGAGEMENT"],
              ["fresh", "eligible", "legacyDismissed"].contains(fixture) else { return }
        var history = EngagementHistory(firstUse: Date().addingTimeInterval(fixture == "fresh" ? 0 : -20 * 86_400))
        history.migratedVoting = fixture != "legacyDismissed"
        if fixture != "fresh" {
            history.activeDays = ["2020-1-1", "2020-1-2", "2020-1-3"]
            history.completedWorkflows = 3
            history.ratingWorkflows = 3
        }
        if fixture == "legacyDismissed" {
            UserDefaults.standard.set(Date(), forKey: "com.brightblue.VotingManager.dismissedPromptDate")
        }
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: EngagementCoordinator.historyKey)
        }
        UserDefaults.standard.set(true, forKey: "isTopicSelectionMaximized")
    }
#endif

    func processArguments() {
#if DEBUG
        if let scenario = ProcessInfo.processInfo.environment["PECS_TEST_STARTUP"],
           scenario == "new" || scenario == "existing" {
            UserDefaults.standard.set(scenario == "new", forKey: StartupExperience.welcomeRequiredKey)
            UserDefaults.standard.removeObject(forKey: StartupExperience.legacyLastSeenVersionKey)
            WhatsNewManager.reset(forFreshInstall: scenario == "new")
        }
        if ProcessInfo.processInfo.environment["PECS_TEST_STARTUP"] == "skip" {
            WhatsNewManager.whatsNewIsEnabled = false
        }
        // UI tests reset only this preference; omit the environment key to test persistence.
        if let value = ProcessInfo.processInfo.environment["PECS_TEST_INTERFACE"] {
            if let style = InterfaceStyle(rawValue: value) {
                UserDefaults.standard.set(style.rawValue, forKey: InterfaceStyle.storageKey)
            } else if value == "default" {
                UserDefaults.standard.removeObject(forKey: InterfaceStyle.storageKey)
            }
        }
#endif
        if CommandLine.arguments.contains(LaunchArguments.keepPDFs) {
            AppSettings.keepPDFs = true
        }
        if CommandLine.arguments.contains(LaunchArguments.darkMode) {
            AppSettings.forceDarkMode = true
        }
        if CommandLine.arguments.contains(LaunchArguments.lightMode) {
            AppSettings.forceLightMode = true
        }
        
        if CommandLine.arguments.contains(LaunchArguments.autoFillSingle) {
            AppSettings.autoFillSingle = true
        }
        else if CommandLine.arguments.contains(LaunchArguments.autoFill) {
            AppSettings.autoFill = true
        }
        
        if CommandLine.arguments.contains(LaunchArguments.resetWhatsNew) {
            WhatsNewManager.reset()
            UserDefaults.standard.removeObject(forKey: StartupExperience.legacyLastSeenVersionKey)
        }
        if CommandLine.arguments.contains(LaunchArguments.noWhatsNew) {
            WhatsNewManager.whatsNewIsEnabled = false
        }



        for argument in CommandLine.arguments {
            if argument.starts(with: LaunchArguments.docDir) {
                let docDir = argument.dropFirst(LaunchArguments.docDir.count + 1)
                let docURL = URL(fileURLWithPath: String(docDir), isDirectory: true)
                RepoHelper.documentsDirectory = docURL
                break
            }
        }
    }
}



// Keep observable-object bindings in a View body. A scene's deferred content
// closure can be evaluated by SwiftUI's background rendering path.
@MainActor
private struct BoardletRootView: View {
    @ObservedObject var repoFactory: PECSRepoFactory
    @ObservedObject var engagement: EngagementCoordinator
    @Environment(\.scenePhase) private var scenePhase
    let featuresViewModel: FeaturesViewModel
    let currentTheme: SharedUITheme
    let startup: StartupExperience
    @State var startupScreen: StartupExperience.Screen
    @AppStorage(StartupExperience.welcomeRequiredKey) private var welcomeRequired = false
    @StateObject var whatsNewViewModel: WhatsNewViewModel
    @StateObject private var presentationContext = ScenePresentationContext()
    @State private var showingWelcomeError = false
    @State private var addedBoardCount = 0
    @State private var showingBoardsAdded = false

    var body: some View {
        Group {
            if startupScreen == .welcome {
                WelcomeView(onChoose: start)
                .environmentObject(currentTheme)
                .alert(L10n.Welcome.startError, isPresented: $showingWelcomeError) {
                    Button(L10n.DefaultBoards.ok, role: .cancel) { }
                } message: {
                    Text(L10n.DefaultBoards.retry)
                }
            } else {
                appContent
            }
        }
        .onChange(of: welcomeRequired) { required in
            if required { startupScreen = .welcome }
        }
        .alert(addedBoardCount == 1 ? L10n.DefaultBoards.addedOne : L10n.DefaultBoards.added(addedBoardCount),
               isPresented: $showingBoardsAdded) {
            Button(L10n.DefaultBoards.ok, role: .cancel) { }
        } message: {
            Text(L10n.Welcome.tapBoardToEdit)
        }
        .whatsNewOverlay(viewModel: whatsNewViewModel,
                         isReady: startupScreen == .content && !showingBoardsAdded && !showingWelcomeError)
        .environmentObject(engagement)
        .environment(\.engagementStartupBlocked, startupScreen != .content || showingBoardsAdded || showingWelcomeError || whatsNewViewModel.showWhatsNewScreen)
        .onChange(of: scenePhase) { phase in
            if phase == .active { engagement.recordActiveDay() }
        }
        .environmentObject(currentTheme)
        .if(AppSettings.forceDarkMode) { $0.preferredColorScheme(.dark) }
        .if(AppSettings.forceLightMode) { $0.preferredColorScheme(.light) }
    }

    private func start(at startingPoint: StartupExperience.StartingPoint) {
        do {
            switch startingPoint {
            case .readyMadeBoards:
                guard let source = Bundle.main.url(forResource: "StarterBoards", withExtension: nil) else {
                    throw CocoaError(.fileNoSuchFile)
                }
                addedBoardCount = try repoFactory.restoreDefaultBoards(
                    from: source, language: Bundle.main.preferredLocalizations.first ?? "en")
                repoFactory.publishedCurrentTopic = nil
                UserDefaults.standard.set(true, forKey: "isTopicSelectionMaximized")
            case .blankBoard:
                let topic = try repoFactory.createEmptyRepo(setActive: true)
                repoFactory.publishedCurrentTopic = topic
                UserDefaults.standard.set(false, forKey: "isTopicSelectionMaximized")
            }
            UserDefaults.standard.set(PECSAppMode.pecsMaker.rawValue, forKey: "appMode")
            startup.finishWelcome()
            startupScreen = .content
            showingBoardsAdded = startingPoint == .readyMadeBoards
        } catch {
            showingWelcomeError = true
        }
    }

    private var appContent: some View {
        ContentView(topicToEdit: $repoFactory.publishedCurrentTopic)
            .background(ScenePresentationReader(context: presentationContext))
            .environmentObject(presentationContext)
            .environmentObject(repoFactory)
            .votingPresentation()
            .environmentObject(featuresViewModel)
            .if(AppSettings.forceDarkMode) { view in
                view.preferredColorScheme(.dark)
            }
            .if(AppSettings.forceLightMode) { view in
                view.preferredColorScheme(.light)
            }
            .environmentObject(currentTheme)
    }
}

private struct EngagementStartupBlockedKey: EnvironmentKey {
    static let defaultValue = true
}
extension EnvironmentValues {
    var engagementStartupBlocked: Bool {
        get { self[EngagementStartupBlockedKey.self] }
        set { self[EngagementStartupBlockedKey.self] = newValue }
    }
}
