//
//  ContentView.swift
//  NGSwiftUIUserDefaultsEditorExample
//
//  Created by Noah Gilmore on 5/4/20.
//  Copyright © 2020 Noah Gilmore. All rights reserved.
//

import SwiftUI
import Combine

@propertyWrapper
struct SimpleUserDefault<T> {
    let userDefaults: UserDefaults
    let key: String
    let defaultValue: T

    init(
        userDefaults: UserDefaults = UserDefaults.standard,
        key: String,
        defaultValue: T
    ) {
        self.userDefaults = userDefaults
        self.key = key
        self.defaultValue = defaultValue
    }

    var wrappedValue: T {
        get {
            guard let data = userDefaults.object(forKey: key) as? T else { return self.defaultValue }
            return data
        }

        set {
            userDefaults.set(newValue, forKey: key)
        }
    }
}


