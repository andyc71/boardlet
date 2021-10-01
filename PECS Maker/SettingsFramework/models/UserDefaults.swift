//
//  UserDefaults.swift
//  MyMusic
//
//  Created by Andy on 12/09/2020.
//  Copyright © 2020 Andrew Clynes. All rights reserved.
//
// From: https://gist.github.com/bermudalocket/776c8266e7443b6222f87360d5d46316

import Combine
import Foundation
import SwiftUI

let preferenceKey = "com.brightblue.mymusic"


@propertyWrapper
struct Persistable<T> {

    let key: String

    let publisher: CurrentValueSubject<T, Never>

    var projectedValue: Persistable<T> { return self }

    var wrappedValue: T {
        get {
            self.publisher.value
        }
        set {
            publisher.send(newValue)
            UserDefaults.standard.set(newValue, forKey: self.key)
        }
    }

    init(_ key: String, defaultValue: T) {
        self.key = "\(preferenceKey).\(key)"
        var value: T = defaultValue
        if let currentValue = UserDefaults.standard.object(forKey: self.key) as? T {
            value = currentValue
        }
        self.publisher = CurrentValueSubject<T, Never>(value)
    }
}

class UserDefaultsConfig2: ObservableObject  {

    static let shared = UserDefaultsConfig2()

    @Persistable("IncludeExplicit", defaultValue: true) var includeExplicit: Bool
    //@Persistable("vibrancy", defaultValue: 17.5) var vibrancy: Double
    //@Persistable("tint", defaultValue: .someEnumValue) var tint: SomeEnumType
  
}
