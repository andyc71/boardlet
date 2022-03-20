//
//  PageLayout.swift
//  PECS Maker
//
//  Created by Andy on 26/09/2021.
//

import UIKit

struct PageLayoutType {
    static func forPageSize(_ pageSize: PageSize) -> [CGSize] {
        switch pageSize {
        case .a4, .usLetter:
            return [
                CGSize(width: 2, height: 2),
                CGSize(width: 2, height: 3),
                CGSize(width: 2, height: 4),
                CGSize(width: 3, height: 4),
            ]
        case .photo10by15:
            return [CGSize(width: 1, height: 1), CGSize(width: 1, height: 2) ]
        }
    }
}


