import XCTest
import SwiftUI
import SharedSwiftUI
import FeatureFramework
import RatingFramework
@testable import PECS_Maker

@MainActor
final class NavigationModelTests: PersistenceTestsBase {
    func testStartupRestoresLastTopicAndFallsBackToFirst() throws {
        let defaults = UserDefaults.standard
        let key = "RepoFactory.currentTopicDir"
        let savedDirectory = repoFactory.documentsDirectory
        let savedSelection = defaults.object(forKey: key)
        defer {
            repoFactory.documentsDirectory = savedDirectory
            defaults.set(savedSelection, forKey: key)
        }
        repoFactory.documentsDirectory = tempDir
        defaults.removeObject(forKey: key)
        let factory = PECSRepoFactory()
        let first = try factory.createEmptyRepo(setActive: false)
        let last = try factory.createEmptyRepo(setActive: true)
        XCTAssertNotEqual(first.id, last.id)

        let restored = PECSRepoFactory()
        XCTAssertEqual(restored.publishedCurrentTopic?.topicDirectoryName, last.topicDirectoryName)
        XCTAssertEqual(restored.currentTopic?.topicDirectoryName, last.topicDirectoryName)

        defaults.set(UUID().uuidString, forKey: key)
        let missing = PECSRepoFactory()
        XCTAssertNotNil(missing.availableTopics.first)
        XCTAssertEqual(missing.publishedCurrentTopic?.id, missing.availableTopics.first?.id)
        XCTAssertEqual(missing.currentTopic?.id, missing.availableTopics.first?.id)
        XCTAssertEqual(defaults.string(forKey: key), missing.availableTopics.first?.topicDirectoryName)

        defaults.removeObject(forKey: key)
        let noSavedSelection = PECSRepoFactory()
        XCTAssertEqual(noSavedSelection.publishedCurrentTopic?.id, noSavedSelection.availableTopics.first?.id)
    }

    func testMaximizingTopicsKeepsEditorAndSelectingABoardRestoresColumns() throws {
        let navigation = NavigationModel()
        let board = try makeBoard("A")
        navigation.selectTopic(board)
        navigation.setMainMenuAction(.titles)
        let editor = try XCTUnwrap(navigation.pageLayoutState)
        editor.title = "Draft"
        navigation.topicsAreMaximized = true
        navigation.synchronizeTopic(board)
        XCTAssertTrue(navigation.topicsAreMaximized, "Repository echoes must not dismiss the topics screen")
        XCTAssertTrue(navigation.pageLayoutState === editor)
        navigation.selectTopic(board)
        XCTAssertFalse(navigation.topicsAreMaximized)
        XCTAssertTrue(navigation.pageLayoutState === editor)
        XCTAssertEqual(editor.title, "Draft")
        XCTAssertEqual(navigation.mainMenuAction, .titles)
        navigation.topicsAreMaximized = true
        let other = try makeBoard("B")
        navigation.selectTopic(other)
        XCTAssertFalse(navigation.topicsAreMaximized)
        XCTAssertEqual(navigation.selectedTopic?.id, other.id)
    }

    func testInitialBoardShowsSelectedPhotosWithoutPushingCompactEditor() throws {
        let navigation = NavigationModel()
        navigation.selectTopic(try makeBoard("Initial board"))
        XCTAssertEqual(navigation.mainMenuAction, .changeSelections)
        XCTAssertEqual(navigation.focus, .menu)
        navigation.selectTopic(nil)
        navigation.selectTopic(try makeBoard("Next board"))
        XCTAssertEqual(navigation.mainMenuAction, .changeSelections)
        XCTAssertEqual(navigation.focus, .menu)
    }

    private func makeBoard(_ name: String) throws -> PECSRepo {
        let directory = tempDir.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let board = try repoFactory.createEmptyRepo(directoryURL: directory, setActive: false)
        board.topicName = name
        return board
    }

    func testBoardBAndDraftSurviveColumnNavigationAndRepositoryEchoes() throws {
        let a = try makeBoard("A")
        let b = try makeBoard("B")
        let navigation = NavigationModel()
        navigation.selectTopic(a)
        navigation.setMainMenuAction(.print)
        navigation.selectTopic(b)
        navigation.setMainMenuAction(.titles)
        let editor = try XCTUnwrap(navigation.pageLayoutState)
        editor.title = "Unsaved board B title"
        let photo = PhotoItem(image: UIImage(systemName: "star")!, title: "Draft caption")
        editor.photoBrowserData.photoItems.append(photo)

        // Column focus is presentation state: Back and repeated publication of
        // the selected repository must not recreate or reload the editor.
        for _ in 0..<5 {
            navigation.focus = .menu
            navigation.synchronizeTopic(b)
            navigation.setMainMenuAction(.titles)
            XCTAssertEqual(navigation.selectedTopic?.id, b.id)
            XCTAssertEqual(navigation.mainMenuAction, .titles)
            XCTAssertTrue(navigation.pageLayoutState === editor)
            XCTAssertEqual(editor.title, "Unsaved board B title")
            XCTAssertTrue(editor.photoBrowserData.photoItems.last === photo)
            XCTAssertEqual(photo.title, "Draft caption")
        }
    }

    func testBackReopenAndSwitchDestinationUseCurrentBoard() throws {
        let navigation = NavigationModel()
        let a = try makeBoard("A")
        let b = try makeBoard("B")
        navigation.selectTopic(a)
        navigation.setMainMenuAction(.titles)
        navigation.focus = .boards
        navigation.selectTopic(b)
        let editor = navigation.pageLayoutState
        navigation.setMainMenuAction(.titles)
        navigation.focus = .menu
        XCTAssertEqual(navigation.focus, .menu)
        navigation.setMainMenuAction(.titles)
        XCTAssertEqual(navigation.mainMenuAction, .titles)
        XCTAssertEqual(navigation.focus, .editor)
        navigation.setMainMenuAction(.selectLayout)
        XCTAssertEqual(navigation.mainMenuAction, .selectLayout)
        XCTAssertTrue(navigation.pageLayoutState === editor)
        XCTAssertEqual(navigation.selectedTopic?.id, b.id)
    }

    func testSelectingAnotherBoardKeepsDestinationWithANewEditor() throws {
        let navigation = NavigationModel()
        navigation.selectTopic(try makeBoard("A"))
        navigation.setMainMenuAction(.changeSelections)
        let previousEditor = navigation.pageLayoutState
        let b = try makeBoard("B")
        navigation.selectTopic(b)
        XCTAssertFalse(navigation.pageLayoutState === previousEditor)
        XCTAssertEqual(navigation.mainMenuAction, .changeSelections)
        XCTAssertEqual(navigation.focus, .editor)
        XCTAssertEqual(navigation.selectedTopic?.id, b.id)
        navigation.selectTopic(nil)
        XCTAssertNil(navigation.pageLayoutState)
        XCTAssertNil(navigation.mainMenuAction)
        XCTAssertEqual(navigation.focus, .boards)
        navigation.setMainMenuAction(.titles)
        XCTAssertNil(navigation.mainMenuAction)
    }

    func testBackCommitsAnEditorThatRemainsMounted() throws {
        let navigation = NavigationModel()
        navigation.selectTopic(try makeBoard("B"))
        navigation.setMainMenuAction(.titles)
        let editor = try XCTUnwrap(navigation.pageLayoutState)
        editor.title = "Changed title before Back"
        editor.checkmarks.didTitles = false
        navigation.focus = .menu
        XCTAssertTrue(editor.checkmarks.didTitles)
        XCTAssertEqual(editor.topic.topicName, "Changed title before Back")
        XCTAssertTrue(navigation.pageLayoutState === editor)

        navigation.setMainMenuAction(.selectLayout)
        editor.checkmarks.didPageLayout = false
        navigation.focus = .menu
        XCTAssertTrue(editor.checkmarks.didPageLayout)
        XCTAssertTrue(navigation.pageLayoutState === editor)
    }

    func testAdaptiveColumnsKeepTheActiveTitleFieldAndEditor() throws {
        let navigation = NavigationModel()
        navigation.selectTopic(try makeBoard("A"))
        navigation.selectTopic(try makeBoard("B"))
        navigation.setMainMenuAction(.titles)
        let editor = try XCTUnwrap(navigation.pageLayoutState)
        let photo = PhotoItem(image: UIImage(systemName: "star")!, title: "Board B draft")
        editor.photoBrowserData.photoItems.append(photo)
        let topic = Binding(get: { navigation.selectedTopic }, set: { navigation.selectTopic($0) })
        let action = Binding(get: { navigation.mainMenuAction }, set: { navigation.setMainMenuAction($0) })
        let root = AdaptiveBoardNavigation(topicToEdit: topic, appMode: .constant(.pecsMaker),
                                           mainMenuAction: action, selectedItems: .constant([]))
            .environmentObject(navigation)
            .environmentObject(SharedUITheme())
            .environmentObject(FeaturesViewModel(featureSettings: AppSettings.shared))
            .environmentObject(RatingStateMachine2())
        let host = UIHostingController(rootView: root)
        let container = UIViewController()
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let window = UIWindow(windowScene: scene)
        window.rootViewController = container
        window.makeKeyAndVisible()
        container.addChild(host)
        container.view.addSubview(host.view)
        host.didMove(toParent: container)
        defer {
            host.willMove(toParent: nil)
            host.view.removeFromSuperview()
            host.removeFromParent()
            window.isHidden = true
        }

        func resize(width: CGFloat, sizeClass: UIUserInterfaceSizeClass) {
            container.setOverrideTraitCollection(UITraitCollection(horizontalSizeClass: sizeClass), forChild: host)
            host.view.frame = CGRect(x: 0, y: 0, width: width, height: 820)
            host.view.setNeedsLayout()
            host.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        }
        func textFields(in view: UIView) -> [UITextField] {
            (view as? UITextField).map { [$0] } ?? view.subviews.flatMap { textFields(in: $0) }
        }

        resize(width: 1180, sizeClass: .regular)
        if #available(iOS 17.0, *) {
            func hasNativeSplit(_ controller: UIViewController) -> Bool {
                controller is UISplitViewController || controller.children.contains(where: hasNativeSplit)
            }
            XCTAssertTrue(hasNativeSplit(host), "The expanded layout must use the native splitter")
        }
        let field = try XCTUnwrap(textFields(in: host.view).first { $0.text == "Board B draft" })
        XCTAssertTrue(field.becomeFirstResponder())
        field.text = "In-progress caption"
        field.sendActions(for: .editingChanged)
        for _ in 0..<3 {
            resize(width: 600, sizeClass: .compact)
            resize(width: 1180, sizeClass: .regular)
            XCTAssertTrue(navigation.pageLayoutState === editor)
            XCTAssertEqual(navigation.mainMenuAction, .titles)
            XCTAssertEqual(navigation.selectedTopic?.topicName, "B")
            let currentField = try XCTUnwrap(textFields(in: host.view).first { $0.text == "In-progress caption" })
            XCTAssertTrue(currentField === field, "Resizing must retain the active editor's input view")
            // Native split collapse may dismiss the keyboard; retain the field and draft.
            XCTAssertEqual(photo.title, "In-progress caption")
            navigation.topicsAreMaximized = true
            resize(width: 1180, sizeClass: .regular)
            navigation.topicsAreMaximized = false
            resize(width: 1180, sizeClass: .regular)
            XCTAssertTrue(navigation.pageLayoutState === editor)
            XCTAssertTrue(textFields(in: host.view).contains { $0 === field })
            XCTAssertEqual(photo.title, "In-progress caption")
        }
    }

}
