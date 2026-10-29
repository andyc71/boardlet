//
//  File.swift
//  
//
//  Created by Andy on 30/05/2024.
//

import Foundation

public enum VotingPromptError : LocalizedError {
    case jsonNotFound(locale: String)
    case jsonDecodingError(error: Error, locale: String)
    
    public var errorDescription: String? {
        switch self {
        case .jsonNotFound(let locale):
            return LocalizedFeatureStrings.featureListNotFoundErrorMessage(locale: locale)
        case .jsonDecodingError(_, let locale):
            return LocalizedFeatureStrings.featureListDecodingErrorMessage(locale: locale)
        }
    }
}

