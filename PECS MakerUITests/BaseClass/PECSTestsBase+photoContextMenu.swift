//
//  PECSTestBase+photoContextMenu.swift
//  PECS Maker
//
//  Created by Andy on 21/08/2024.
//

import Foundation
import XCTest

extension PECSTestsBase {
    @discardableResult
    func displayPhotoContextMenuAndSelectOption(photoIndex: Int, accessibilityID: String, menuText: String) -> String {
        
        //Get the photo cell
        guard let cell = app.selectButton(A12SSUI.PhotoCell.image(for: photoIndex)) else {
            return ""
        }
            
        //Long press the cell to display the context menu. Allowing force if needed because of IOS15.5 issue
        //where the item is sometimes not hittable. Also worthwhile checking where the ContextMenu is
        //attached to the the view because we might be tapping on some padding around the control instead of
        //the control itself.
        cell.press(forDuration: 2, canForce: true)
        
        let label = cell.label
        
        //Get the menu button and press
        if XCUIDevice.shared.iosVersion >= 16.0 {
            app.tapButton(id: accessibilityID)
        }
        else {
            //Prior to IOS 16 we dnot have an accessibility idenfitier so we have to
            //use the menu text.
            //We have to be more specific than app.buttons because the chances of finding
            //more than one item are too high. The alternative would be to find all of them
            //and check which one is hittable.
            let button = app.cells.buttons[menuText]
            XCTAssertTrue(button.waitForExistence(timeout: 2), "Could not find button named \(menuText)")
            button.tap()
        }
        
        return label
    }
}
