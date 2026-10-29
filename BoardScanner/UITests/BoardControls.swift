import XCTest

extension XCUIApplication {
    @MainActor
    func tapBoardControl(_ identifier: String) {
        if !buttons[identifier].exists {
            buttons["boardOptions"].tap()
        }
        buttons[identifier].tap()
    }
}
