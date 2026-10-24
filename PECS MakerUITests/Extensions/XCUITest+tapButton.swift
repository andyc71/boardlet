//
//  XCUITest+tapButton.swift
//  PECS MakerUITests
//
//  Created by Andy on 22/12/2022.
//

import XCTest

extension XCUIApplication {

    func tapButton(id: String, canForce: Bool = true, context: String = "") {
        if id.hasPrefix("LayoutScreen.pageSize."), !buttons[id].exists {
            let paperSize = buttons.matching(NSPredicate(format: "label == 'Paper Size' OR label == 'Tamaño de Papel'")).firstMatch
            XCTAssertTrue(paperSize.waitForExistence(timeout: 5))
            paperSize.tap()
        }
        if id.hasPrefix("LayoutScreen.layout."), !buttons[id].exists {
            let seeAll = buttons[AccessibilityIdentifiers.LayoutScreen.seeAllButton]
            if seeAll.exists { seeAll.tap() }
            let layouts = scrollViews.firstMatch
            for _ in 0..<12 where !buttons[id].exists { layouts.swipeUp() }
        }
        if id.hasPrefix("LayoutScreen.layout.") {
            let target = buttons.matching(identifier: id).firstMatch
            let scroll = scrollViews.containing(.button, identifier: id).firstMatch
            if scroll.exists {
                for _ in 0..<8 {
                    var visible = scroll.frame.intersection(frame).insetBy(dx: 0, dy: 8)
                    let navigation = navigationBars.firstMatch
                    if navigation.exists {
                        let top = max(visible.minY, navigation.frame.maxY + 8)
                        visible = CGRect(x: visible.minX, y: top, width: visible.width,
                                         height: max(1, visible.maxY - top))
                    }
                    if target.exists && visible.contains(target.frame) { break }
                    guard target.exists else { scroll.swipeUp(); continue }
                    let distance = min(visible.height * 0.45,
                                       max(-visible.height * 0.45, visible.midY - target.frame.midY))
                    let start = coordinate(withNormalizedOffset: .zero).withOffset(
                        CGVector(dx: visible.midX - frame.minX, dy: visible.midY - frame.minY))
                    start.press(forDuration: 0,
                                thenDragTo: start.withOffset(CGVector(dx: 0, dy: distance)),
                                withVelocity: .default, thenHoldForDuration: 0.25)
                }
            }
        }
        let menuButton = id == AccessibilityIdentifiers.TopicTitleView.menuButton && !buttons[id].exists
            ? buttons["OverflowBarButtonItem"] : buttons.matching(identifier: id).firstMatch
        guard menuButton.waitForExistence(timeout: 10) else {
            XCTFail("\(context): Button named \(menuButton) does not exist")
            return
        }
        menuButton.tap(canForce: canForce)
    }
    
    func forceTapButton(id: String, context: String = "") {
        let menuButton = self.buttons[id]
        guard menuButton.waitForExistence(timeout: 10) else {
            XCTFail("\(context): Button named \(menuButton) does not exist")
            return
        }
        menuButton.forceTap()
    }


}
