//
//  XCUITest+tapButton.swift
//  PECS MakerUITests
//
//  Created by Andy on 22/12/2022.
//

import XCTest

enum UIElementExistsAssert { case noAssert, exists, doesNotExist }
enum UIElementType: String { case button, staticText, image, cell, other }

extension XCUIApplication {

    @discardableResult
    func selectButton(_ id: String, assertType: UIElementExistsAssert = .exists, context: String = "") -> XCUIElement? {
        let element = self.buttons[id]
        return assertElementExistence(element, id: id, elementType: .button, assertType: assertType, context: context)
    }
    
    @discardableResult
    func selectFirstButton(_ ids: [String], assertType: UIElementExistsAssert = .exists, context: String = "") -> XCUIElement? {
        var foundElement: XCUIElement?
        for id in ids {
            let element = self.buttons[id]
            if element.waitForExistence(timeout: 2) {
                foundElement = element
                break
            }
        }
        switch assertType {
        case .noAssert:
            return foundElement
        case .exists:
            XCTAssertNotNil(foundElement, "Could not find an element with any of the identifiers \(ids)")
            return foundElement
        case .doesNotExist:
            XCTAssertNil(foundElement, "Unexpectedly found an element with one of the identifiers \(ids)")
            return foundElement
        }
    }

    @discardableResult
    func selectStaticText(_ id: String, assertType: UIElementExistsAssert = .exists, context: String = "") -> XCUIElement? {
        let element = self.staticTexts[id]
        return assertElementExistence(element, id: id, elementType: .staticText, assertType: assertType, context: context)
    }
    
    @discardableResult
    func selectImage(_ id: String, assertType: UIElementExistsAssert = .exists, context: String = "") -> XCUIElement? {
        let element = self.images[id]
        return assertElementExistence(element, id: id, elementType: .image, assertType: assertType, context: context)
    }

    @discardableResult
    func selectCell(_ id: String, assertType: UIElementExistsAssert = .exists, context: String = "") -> XCUIElement? {
        let element = self.cells[id]
        return assertElementExistence(element, id: id, elementType: .cell, assertType: assertType, context: context)
    }


    @discardableResult
    func selectOther(_ id: String, assertType: UIElementExistsAssert = .exists, context: String = "") -> XCUIElement? {
        let element = self.otherElements[id]
        return assertElementExistence(element, id: id, elementType: .other, assertType: assertType, context: context)
    }
    
    @discardableResult
    func selectOther(labelEndingIn labelEnding: String, assertType: UIElementExistsAssert = .exists, context: String = "") -> XCUIElement? {
        let element = self.otherElements.matching(NSPredicate(format: "label ENDSWITH %@", labelEnding)).firstMatch
        return assertElementExistence(element, id: "*\(labelEnding)", elementType: .other, assertType: assertType, context: context)
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
        case .cell:
            return self.cells[id]
        case .other:
            return self.otherElements[id]
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
