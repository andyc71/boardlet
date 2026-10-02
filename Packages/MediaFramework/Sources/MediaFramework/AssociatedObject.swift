//
//  AssociatedObject.swift
//  MediaFramework
//
//  Created by Andy on 07/02/2021.
//  Copyright © 2021 Andrew Clynes. All rights reserved.
//

//From: https://stackoverflow.com/questions/24133058/is-there-a-way-to-set-associated-objects-in-swift

import Foundation

final class Lifted<T> {
    let value: T
    init(_ x: T) {
        value = x
    }
}

private func lift<T>(x: T) -> Lifted<T>  {
    return Lifted(x)
}

func setAssociatedObject<T>(object: AnyObject, value: T, associativeKey: UnsafeRawPointer, policy: objc_AssociationPolicy) {
        objc_setAssociatedObject(object, associativeKey, lift(x: value),  policy)
}

func getAssociatedObject<T>(object: AnyObject, associativeKey: UnsafeRawPointer) -> T? {
    if let v = objc_getAssociatedObject(object, associativeKey) as? T {
        return v
    }
    else if let v = objc_getAssociatedObject(object, associativeKey) as? Lifted<T> {
        return v.value
    }
    else {
        return nil
    }
}
