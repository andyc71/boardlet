//
//  FitzgeraldKey.swift
//  PECS Maker
//
//  Created by Andy on 28/06/2022.
//

import UIKit

enum FitzgeraldKey : String, Equatable, CaseIterable, Codable {
    
    case none
    case noun
    case pronoun
    case adjective
    case verb
    case conjunction
    case preposition
    case question
    case adverb
    case important
    case determiner
    
    var color: UIColor {
        switch self {
        case .none:
            return .clear
        case .pronoun:
            return .yellow
        case .adjective:
            return .blue
        case .verb:
            return .green
        case .noun:
            return .orange
        case .conjunction:
            return .white
        case .preposition:
            return .systemPink
        case .question:
            return .purple
        case .adverb:
            return .brown
        case .important:
            return .red
        case .determiner:
            return .gray
        }
    }
    
    var localizedName: String {
        switch self {
        case .none:
            return L10n.FitzgeraldKey.none
        case .pronoun:
            return L10n.FitzgeraldKey.pronoun
        case .adjective:
            return L10n.FitzgeraldKey.adjective
        case .verb:
            return L10n.FitzgeraldKey.verb
        case .noun:
            return L10n.FitzgeraldKey.noun
        case .conjunction:
            return L10n.FitzgeraldKey.conjunction
        case .preposition:
            return L10n.FitzgeraldKey.preposition
        case .question:
            return L10n.FitzgeraldKey.question
        case .adverb:
            return L10n.FitzgeraldKey.adverb
        case .important:
            return L10n.FitzgeraldKey.important
        case .determiner:
            return L10n.FitzgeraldKey.determiner
        }
    }
    
    
}
