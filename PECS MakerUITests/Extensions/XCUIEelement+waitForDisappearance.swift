//
//  XCUIEelement+waitForDisappearance.swift
//  PECS Maker
//
//  Created by Andy on 04/07/2024.
//

import XCTest

extension XCUIElement {
    func waitForDisappearance(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate { evaluatedObject, _ in
            guard let element = evaluatedObject as? XCUIElement else { return false }
            return !element.exists
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
}
