//
//  XCUIElement+forceTap.swift
//  PECS MakerUITests
//
//  Created by Andy on 07/01/2023.
//

import XCTest

extension XCUIElement {
    func forceTap() {
        //Workaround a well-known bug where the item for some reason isn't tappable
        //even though it seems to be OK in the UI, and Accessibility Inspector.
        let coordinate: XCUICoordinate = self.coordinate(withNormalizedOffset: CGVectorMake(0, 0))
        coordinate.tap()
    }
    
    func tap(canForce: Bool) {
        if isHittable {
            tap()
        }
        else {
            forceTap()
        }
    }
}
