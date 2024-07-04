//
//  XCUIEelement+waitForDisappearance.swift
//  PECS Maker
//
//  Created by Andy on 04/07/2024.
//

import XCTest

extension XCUIElement {
    func waitForDisappearance(timeout: TimeInterval) -> Bool {
        let startTime = Date()
        while self.exists {
            if Date().timeIntervalSince(startTime) > timeout {
                return false
            }
            usleep(100_000) // Sleep for 0.1 seconds (100,000 microseconds)
        }
        return true
    }
}

