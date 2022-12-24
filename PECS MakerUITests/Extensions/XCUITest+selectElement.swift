//
//  XCUITest+tapButton.swift
//  PECS MakerUITests
//
//  Created by Andy on 22/12/2022.
//

import XCTest

enum UIElementExistsAssert { case noAssert, exists, doesNotExist }
enum UIElementType: String { case button, staticText, image }

extension XCUIApplication {

    @discardableResult
    func selectButton(_ id: String, assertType: UIElementExistsAssert = .exists, context: String = "") -> XCUIElement? {
        let element = self.buttons[id]
        return assertElementExistence(element, id: id, elementType: .button, assertType: assertType, context: context)
    }

    @discardableResult
    func selectStaticText(_ id: String, assertType: UIElementExistsAssert = .exists, context: String = "") -> XCUIElement? {
        let element = self.staticTexts[id]
        return assertElementExistence(element, id: id, elementType: .staticText, assertType: assertType, context: context)
    }
    
    
    @discardableResult
    func checkElementExistence(_ elementType: UIElementType, id: String, context: String = "") -> XCUIElement? {
        let element = selectElement(elementType, id: id)
        return assertElementExistence(element, id: id, elementType: elementType, assertType: .exists)
    }

    @discardableResult
    func checkElementNonExistence(_ elementType: UIElementType, id: String, context: String = "") -> XCUIElement? {
        let element = selectElement(elementType, id: id)
        return assertElementExistence(element, id: id, elementType: elementType, assertType: .doesNotExist)
    }
    
    @discardableResult
    func selectElement(_ elementType: UIElementType, id: String) -> XCUIElement {
        switch elementType {
        case .button:
            return self.buttons[id]
        case .staticText:
            return self.staticTexts[id]
        case .image:
            return self.images[id]
        }
    }

    @discardableResult
    func assertElementExistence(_ element: XCUIElement, id: String, elementType: UIElementType, assertType: UIElementExistsAssert, context: String = "") -> XCUIElement? {
        let result = element.waitForExistence(timeout: 2)
        switch assertType {
        case .noAssert:
            return result ? element : nil
        case .exists:
            XCTAssertTrue( result, "\(context): \(elementType) named \(id) does not exist")
            return result ? element : nil
        case .doesNotExist:
            XCTAssertFalse( result, "\(context): \(elementType) named \(id) exists but it should not")
            return result ? element : nil
        }
    }

}
