//
//  Binding+UserDefaults.swift
//  MyMusic
//
//  Created by Andy on 31/12/2020.
//  Copyright © 2020 Andrew Clynes. All rights reserved.
//

import SwiftUI

/*
class UserDefaultsConfig: ObservableObject {
    static let shared = UserDefaultsConfig()

    @Published var includeExplicit: Bool = false
        
}
*/

extension Binding {
    init<RootType>(keyPath: ReferenceWritableKeyPath<RootType, Value>, object: RootType) {
        self.init(
            get: { object[keyPath: keyPath] },
            set: { object[keyPath: keyPath] = $0}
        )
    }
}

struct UserDefaultsConfigToggleItemView: View {
    @ObservedObject var defaultsConfig = UserDefaultsConfig.shared
    let path: ReferenceWritableKeyPath<UserDefaultsConfig, Bool>
    let name: String

    var body: some View {
        HStack {
            Toggle(isOn: Binding(keyPath: self.path, object: self.defaultsConfig)) {
                Text(name)
            }
            Spacer()
        }
    }
}

/*


struct UserDefaultsNumnberView: View {
    @ObservedObject var defaultsConfig = UserDefaultsConfig.shared
    let path: ReferenceWritableKeyPath<UserDefaultsConfig, Bool>
    let name: String

    var body: some View {
        HStack {
            TextField("", )
            Toggle(isOn: Binding(keyPath: self.path, object: self.defaultsConfig)) {
                Text(name)
            }
            Spacer()
        }
    }
}
*/
