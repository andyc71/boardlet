//
//  XCUIElement+forceTap.swift
//  PECS MakerUITests
//
//  Created by Andy on 07/01/2023.
//

import XCTest

extension XCUIElement {
    
    func forcePress(forDuration duration: TimeInterval) {
        let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVectorMake(0.5, 0.5))
        coordinate.press(forDuration: duration)
    }
    
    func press(forDuration duration: TimeInterval, canForce: Bool) {
        if isHittable {
            press(forDuration: duration)
        }
        else {
//            let width = self.frame.width
//            let height = self.frame.height
            //let cooridnate = self.coordinateWithNormalizedOffset(CGVector(dx: 0, dy: 0)).coordinateWithOffset(CGVector(dx: width / 2, dy: height / 2))
            let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVectorMake(0.5, 0.5))
            coordinate.press(forDuration: duration)
        }
    }
}
