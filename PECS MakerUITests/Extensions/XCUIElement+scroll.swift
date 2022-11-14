//
//  XCUIElement+scroll.swift
//  PECS MakerUITests
//
//  Created by Andy on 03/11/2022.
//

import XCTest

extension XCUIApplication {
    private struct Constants {
        // Half way accross the screen and 10% from top
        static let topOffset = CGVector(dx: 0.5, dy: 0.1)

        // Half way accross the screen and 90% from top
        static let bottomOffset = CGVector(dx: 0.5, dy: 0.9)
    }

    var screenTopCoordinate: XCUICoordinate {
        return windows.firstMatch.coordinate(withNormalizedOffset: Constants.topOffset)
    }

    var screenBottomCoordinate: XCUICoordinate {
        return windows.firstMatch.coordinate(withNormalizedOffset: Constants.bottomOffset)
    }

    func scrollDownToElement(element: XCUIElement, maxScrolls: Int = 5) {
        for _ in 0..<maxScrolls {
            if element.exists && element.isHittable { element.scrollToTop(); break }
            scrollDown()
        }
    }

    func scrollDown() {
        screenBottomCoordinate.press(forDuration: 0.1, thenDragTo: screenTopCoordinate)
    }
}

extension XCUIElement {
    func scrollToTop() {
        let topCoordinate = XCUIApplication().screenTopCoordinate
        let elementCoordinate = coordinate(withNormalizedOffset: .zero)

        // Adjust coordinate so that the drag is straight up, otherwise
        // an embedded horizontal scrolling element will get scrolled instead
        let delta = topCoordinate.screenPoint.x - elementCoordinate.screenPoint.x
        let deltaVector = CGVector(dx: delta, dy: 0.0)

        elementCoordinate.withOffset(deltaVector).press(forDuration: 0.1, thenDragTo: topCoordinate)
    }

}
