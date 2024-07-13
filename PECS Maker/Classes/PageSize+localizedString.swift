//
//  PageSize+localizedString.swift
//  PECS Maker
//
//  Created by Andy on 13/07/2024.
//

import Foundation

extension PageSize {
    var localizedString: String {
        switch self {
        case .a4:
            "A4" //Not localized as it's Universal
        case .a5:
            "A5" //Not localized as it's Universal
        case .usLetter:
            "US Letter" //Not localized as it's US specific
        case .quarto:
            "8x10 (UK Quarto)" //Not localized as it's UK specific
        case .photo10by15:
            L10n.PageSize.photo10by15
        }
    }
}
