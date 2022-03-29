//
//  PageLayout.swift
//  PECS Maker
//
//  Created by Andy on 26/09/2021.
//

import UIKit

extension PageLayoutType : Identifiable, Equatable {

    static func == (lhs: PageLayoutType, rhs: PageLayoutType) -> Bool {
        return lhs.width == rhs.width &&
        lhs.height == rhs.height &&
        lhs.isDefault == rhs.isDefault
    }
    
    
    static var zero : PageLayoutType { get { return PageLayoutType(width: 0, height: 0)}}
    
    func flipped() -> PageLayoutType {
        return PageLayoutType(width: self.height, height: self.width)
    }
    
    func asPortrait() -> PageLayoutType {
        return self
    }
    
    func asLandsape() -> PageLayoutType {
        return self.flipped()
    }
    
    public var id: UUID {
        return UUID()
    }

    static func forPageSize(_ pageSize: PageSize) -> [PageLayoutType] {
        switch pageSize {
        case .a4, .usLetter:
            return [
                PageLayoutType(width: 1, height: 2),
                PageLayoutType(width: 1, height: 3),
                PageLayoutType(width: 1, height: 4),

                PageLayoutType(width: 2, height: 2),
                PageLayoutType(width: 2, height: 3),
                PageLayoutType(width: 2, height: 4),

                PageLayoutType(width: 3, height: 2, isDefault: .landscape),
                PageLayoutType(width: 3, height: 3, isDefault: .portrait),
                PageLayoutType(width: 3, height: 4),

                PageLayoutType(width: 4, height: 2),
                PageLayoutType(width: 4, height: 3),
                PageLayoutType(width: 4, height: 4),

            ]
        case .photo10by15:
            return [
                PageLayoutType(width: 1, height: 1),
                PageLayoutType(width: 1, height: 2, isDefault: .portrait),
                PageLayoutType(width: 2, height: 1, isDefault: .landscape)
            ]
        }
    }
}


