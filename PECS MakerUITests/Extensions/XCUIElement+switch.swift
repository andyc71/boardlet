import XCTest

extension XCUIElement {
    private var valueSwitch: XCUIElement {
        let nested = switches.firstMatch
        return nested.exists ? nested : self
    }

    func setSwitch(on newValue: Bool) {
        let control = valueSwitch
        if isSwitchOn() == newValue { return }
        control.tap()
        let predicate = NSPredicate(format: "value == %@", newValue ? "1" : "0")
        let changed = XCTNSPredicateExpectation(predicate: predicate, object: control)
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: 10), .completed,
                       "Switch must reach the requested value. \(debugDescription)")
    }

    func isSwitchOn() -> Bool {
        guard let switchValue = valueSwitch.value as? String else {
            XCTFail("Unable to read switch value")
            return false
        }
        return switchValue == "1"
    }
}
