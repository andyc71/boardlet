import UIKit
import XCTest

extension XCUIApplication {
    @MainActor
    func setWindowOrientation(_ orientation: UIDeviceOrientation,
                              file: StaticString = #filePath, line: UInt = #line) {
        XCUIDevice.shared.orientation = orientation
        let window = windows.firstMatch
        let settled = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard window.exists else { return false }
            let frame = window.frame
            return orientation.isLandscape
                ? frame.width > frame.height : frame.height > frame.width
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [settled], timeout: 5), .completed,
                       "The window must finish changing orientation before interaction",
                       file: file, line: line)
    }
}
