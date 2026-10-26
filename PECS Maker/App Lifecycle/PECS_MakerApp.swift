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
import RatingFramework
import FeatureFramework
import SettingsFramework

@main
struct PECS_MakerApp: App {
    
    @State var topicToEdit: PECSRepo?

    private var cancellable: AnyCancellable?
    
    var currentTheme: SharedUITheme
    private var startup = StartupExperience()
    private var startupScreen: StartupExperience.Screen = .content

    init() {
        currentTheme = Self.setupTheme()
        
        processArguments()
        startup.prepare(documents: RepoHelper.documentsDirectory)
        startup.applyEditionPreferences()
        startupScreen = startup.screen
#if DEBUG
        if ProcessInfo.processInfo.environment["PECS_TEST_STARTUP"] == "skip" {
            startupScreen = .content
        }
#endif
        if CommandLine.arguments.contains(LaunchArguments.noWhatsNew), startupScreen == .whatsNew {
            startupScreen = .content
        }
        setupAnalytics()
        setupRatingHelper()
        
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
    
    @StateObject var ratingStateMachine: RatingStateMachine2 = RatingStateMachine2()
    @StateObject var featuresViewModel: FeaturesViewModel = FeaturesViewModel(featureSettings: AppSettings.shared)
    
    @StateObject var repoFactory = PECSRepoFactory.shared
    
    var body: some Scene {
        WindowGroup {
            BoardletRootView(
                repoFactory: repoFactory,
                ratingStateMachine: ratingStateMachine,
                featuresViewModel: featuresViewModel,
                currentTheme: currentTheme,
                startup: startup,
                startupScreen: startupScreen
            )
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
    
    func setupRatingHelper() {
        
        if CommandLine.arguments.contains(LaunchArguments.noRatings) {
            return
        }
        
        #if DEBUG
        RatingHelper.reset()
        #endif

        RatingHelper.setup()
        RatingHelper.minimumReviewWorthyActionCount = 1
    }
    
    func processArguments() {
#if DEBUG
        if let scenario = ProcessInfo.processInfo.environment["PECS_TEST_STARTUP"],
           scenario == "new" || scenario == "existing" {
            UserDefaults.standard.set(scenario == "new", forKey: StartupExperience.welcomeRequiredKey)
            UserDefaults.standard.removeObject(forKey: StartupExperience.lastSeenVersionKey)
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
        
        if CommandLine.arguments.contains(LaunchArguments.resetFeatureVoting) {
            VotingManager.clearLastVotedDate()
        }
        if CommandLine.arguments.contains(LaunchArguments.noFeatureVoting) {
            VotingManager.votingIsEnabled = false
        }
        if CommandLine.arguments.contains(LaunchArguments.resetWhatsNew) {
            WhatsNewManager.reset()
            UserDefaults.standard.removeObject(forKey: StartupExperience.lastSeenVersionKey)
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
    @ObservedObject var ratingStateMachine: RatingStateMachine2
    let featuresViewModel: FeaturesViewModel
    let currentTheme: SharedUITheme
    let startup: StartupExperience
    @State var startupScreen: StartupExperience.Screen
    @AppStorage(StartupExperience.welcomeRequiredKey) private var welcomeRequired = false
    private let releaseNotes = ReleaseNotes.load(locale: AppSettings.shared.currentLanguageCode)
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
        .sheet(isPresented: Binding(
            get: { startupScreen == .whatsNew && releaseNotes != nil },
            set: { if !$0 { dismissWhatsNew() } }
        )) {
            if let releaseNotes {
                StartupWhatsNewView(notes: releaseNotes, onContinue: dismissWhatsNew)
            }
        }
        .if(AppSettings.forceDarkMode) { $0.preferredColorScheme(.dark) }
        .if(AppSettings.forceLightMode) { $0.preferredColorScheme(.light) }
    }

    private func dismissWhatsNew() {
        startup.finishWhatsNew()
        startupScreen = .content
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
            .if(startupScreen == .content) { view in
                view.ratingAlert(state: $ratingStateMachine.ratingState, feedbackSettings: AppSettings.shared, theme: currentTheme)
                    .votingPrompt()
            }
            .environmentObject(ratingStateMachine)
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
