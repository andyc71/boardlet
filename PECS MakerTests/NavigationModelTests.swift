import XCTest
@testable import PECS_Maker

@MainActor
final class NavigationModelTests: XCTestCase {
    func testPhotoPopThenBoardPopReturnsToTopics() {
        let model = NavigationModel()
        let board = AppRoute.board(UUID())
        model.updateStackPath([board], for: .compact)
        model.push(.photo(UUID()))
        model.pop()
        XCTAssertEqual(model.path, [board])
        model.pop()
        XCTAssertTrue(model.path.isEmpty)
        model.pop()
        XCTAssertTrue(model.path.isEmpty)
    }

    func testModernSplitPopPreservesBoardAndEditorSession() {
        let model = NavigationModel()
        let board = AppRoute.board(UUID())
        let photoID = UUID()
        model.updateStackPath([board, .photo(photoID)], for: .compact)
        model.selectedPhotoIDs = [photoID]
        model.selectedBoardPage = 2
        XCTAssertEqual(model.stackPath(for: .modernDetail), [.photo(photoID)])
        model.updateStackPath([], for: .modernDetail)
        XCTAssertEqual(model.path, [board])
        XCTAssertEqual(model.selectedPhotoIDs, [photoID])
        XCTAssertEqual(model.selectedBoardPage, 2)
    }

    func testClassicColumnsProjectTheSameHistoryAsCompact() {
        let model = NavigationModel()
        let board = AppRoute.board(UUID())
        let photo = AppRoute.photo(UUID())
        model.updateStackPath([board, .menu(.changeSelections), photo], for: .compact)
        XCTAssertEqual(model.stackPath(for: .compact), model.path)
        XCTAssertEqual(model.stackPath(for: .classicDetail), [photo])
        model.updateStackPath([], for: .classicDetail)
        XCTAssertEqual(model.path, [board, .menu(.changeSelections)])
        model.pop()
        XCTAssertNil(model.selectedAction)
        XCTAssertEqual(model.path, [board])
    }

    func testSelectingAnotherMenuActionDropsItsPreviousDescendants() {
        let model = NavigationModel()
        let board = AppRoute.board(UUID())
        model.updateStackPath([board, .menu(.changeSelections), .photo(UUID())], for: .compact)
        model.setMainMenuAction(.selectLayout)
        XCTAssertEqual(model.path, [board, .menu(.selectLayout)])
        model.push(.allLayouts)
        model.setMainMenuAction(.settings)
        XCTAssertEqual(model.path, [board, .menu(.settings)])
    }

    func testInterfaceSwitchKeepsBoardButDropsInterfaceSpecificScreens() {
        let model = NavigationModel()
        let board = AppRoute.board(UUID())
        model.updateStackPath([board, .menu(.settings), .credits], for: .compact)
        model.resetInterfaceNavigation()
        XCTAssertEqual(model.path, [board])
        model.updateStackPath([.menu(.settings)], for: .compact)
        model.resetInterfaceNavigation()
        XCTAssertTrue(model.path.isEmpty)
    }

    func testSettingsWithoutABoardAndRepeatedPushes() {
        let model = NavigationModel()
        model.setMainMenuAction(.settings)
        model.push(.credits)
        model.push(.credits)
        XCTAssertEqual(model.path, [.menu(.settings), .credits])
        XCTAssertEqual(model.stackPath(for: .modernDetail), model.path)
        XCTAssertEqual(model.stackPath(for: .classicDetail), [.credits])
    }

    func testDeletingSelectedBoardClearsAllNavigationAndSelection() {
        let model = NavigationModel()
        model.updateStackPath([.board(UUID()), .photo(UUID())], for: .compact)
        model.selectedPhotoIDs = [UUID()]
        model.selectedBoardPage = 3
        model.clearTopic()
        XCTAssertTrue(model.path.isEmpty)
        XCTAssertTrue(model.selectedPhotoIDs.isEmpty)
        XCTAssertEqual(model.selectedBoardPage, 0)
        XCTAssertNil(model.pageLayoutState)
    }
}
