//
//  Snapshots.swift
//  PECS MakerUITests
//
//  Created by Andy on 30/06/2022.
//

import Foundation

class Snapshots {
    static var takeSnapshots: Bool {
        if let value = ProcessInfo.processInfo.environment["takeSnapshots"] {
            return value == "1"
        }
        else {
            return false
        }
    }
}
