//
//  UserDefaults.swift
//  MyMusic
//
//  Created by Andy on 31/12/2020.
//  Copyright © 2020 Andrew Clynes. All rights reserved.
//

import Combine

class UserDefaultsConfig: ObservableObject {
    static let shared = UserDefaultsConfig()

    let objectWillChange = PassthroughSubject<Void, Never>()

    @SimpleUserDefault(key: "com.brightblue.is-debug-logging-enabled", defaultValue: false)
    var isDebugLoggingEnabled: Bool {
        didSet {
            objectWillChange.send()
        }
    }

}


