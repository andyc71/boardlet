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

    @SimpleUserDefault(key: "com.brightblue.include-explicit", defaultValue: false)
    var includeExplicit: Bool {
        willSet {
            objectWillChange.send()
        }
    }
    @SimpleUserDefault(key: "com.brightblue.include-cloud", defaultValue: true)
    var includeCloud: Bool {
        willSet {
            objectWillChange.send()
        }
    }

    @SimpleUserDefault(key: "com.brightblue.include-long-Songs", defaultValue: false)
    var includeLongSongs: Bool {
        willSet {
            objectWillChange.send()
        }
    }

    @SimpleUserDefault(key: "com.brightblue.include-short-songs", defaultValue: false)
    var includeShortSongs: Bool {
        willSet {
            objectWillChange.send()
        }
    }

    @SimpleUserDefault(key: "com.brightblue.include-xmas-songs", defaultValue: true)
    var includeChristmasSongs: Bool {
        willSet {
            objectWillChange.send()
        }
    }
    
    @SimpleUserDefault(key: "com.brightblue.map-Reactions-And-Ratings", defaultValue: true)
    var mapReactionsAndRatings: Bool {
        willSet {
            objectWillChange.send()
        }
    }
    
    @SimpleUserDefault(key: "com.brightblue.resume-last-playlist", defaultValue: true)
    var resumeLastPlaylist: Bool {
        willSet {
            objectWillChange.send()
        }
    }



}


