//
//  XCUIElement+typeText.swift
//  PECS MakerUITests
//
//  Created by Andy on 20/05/2023.
//

import XCTest

extension XCUIElement {
    func typeText(_ text: String, retries: Int) {
        //Workaround for the bug where you type into a text box and
        //it misses some of the characters.
        let textBox = self
        tapAndWaitForKeyboardToAppear()
        clearText()
        textBox.typeText(text)
        //Dismiss the keyboard
        textBox.typeText("\n")
        if !checkText(text) {
            typeTextOneCharacterAtATime(text, retries: retries)
        }
    }
    
    func typeTextOneCharacterAtATime(_ text: String, retries: Int, currentRetry: Int = 1) {
        let textBox = self
        
        tapAndWaitForKeyboardToAppear()
        clearText()
        for character in text {
            textBox.typeText(String(character))
        }
        //Dismiss the keyboard
        textBox.typeText("\n")

        if !checkText(text) {
            
            if currentRetry < retries {
                typeTextOneCharacterAtATime(title, retries: retries, currentRetry: currentRetry + 1)
            }
            else {
                XCTFail("Could not set the text box to the right value. Wanted to set \(text).")
            }
        }
        
    }
    
    func checkText(_ title: String) -> Bool {
        let textBox = self
        guard let textTyped = textBox.value as? String else {
            XCTFail("Could not get value from textbox")
            return false
        }
        if textTyped != title {
            return false
        }
        else {
            return true
        }
    }
    

    func tapAndWaitForKeyboardToAppear() {
        let keyboard = XCUIApplication().keyboards.element
        while (true) {
            self.tap()
            if keyboard.exists {
                break;
            }
            RunLoop.current.run(until: NSDate(timeIntervalSinceNow: 0.5) as Date)
        }
    }
    
    
}



