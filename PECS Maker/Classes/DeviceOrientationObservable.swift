//
//  DeviceOrientationObservable.swift
//  PECS Maker
//
//  Created by Andy on 25/09/2021.
//

import UIKit
import Combine

class DeviceOrientationObservable : ObservableObject {
    @Published var orientation = UIDevice.current.orientation
    init () {
        NotificationCenter.default.addObserver(self, selector: #selector(isRotated), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    @objc func isRotated() {
        self.orientation = UIDevice.current.orientation
    }
}

