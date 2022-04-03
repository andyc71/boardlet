//
//  PageSize.swift
//  PECS Maker
//
//  Created by Andy on 26/09/2021.
//

import UIKit

extension CGSize {
    func flipped() -> CGSize {
        return CGSize(width: self.height, height: self.width)
    }

    func asPortrait() -> CGSize {
        return self
    }
    func asLandsape() -> CGSize {
        return CGSize(width: self.height, height: self.width)
    }
}

//extension PageLayout : Identifiable {
//    public var id: UUID {
//        return UUID()
//    }






