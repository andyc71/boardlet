//
//  PageLayoutCheckmarks.swift
//  PECS Maker
//
//  Created by Andy on 12/10/2022.
//

import Combine

class PageLayoutCheckmarks: ObservableObject, Codable, Hashable {
    
    static func == (lhs: PageLayoutCheckmarks, rhs: PageLayoutCheckmarks) -> Bool {
        lhs.didPageLayout == rhs.didPageLayout &&
        lhs.didTitles == rhs.didTitles &&
        lhs.didPrint == rhs.didPrint
    }
    
    func isEqual(to object: Any?) -> Bool {
            guard object != nil && type(of: object!) == PageLayoutCheckmarks.self else {
                return false
            }
            let value = object as! PageLayoutCheckmarks
            return self == value
        }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(didPageLayout)
        hasher.combine(didTitles)
        hasher.combine(didPrint)
    }
    
    @Published var didPageLayout: Bool = false
    @Published var didTitles: Bool = false
    @Published var didPrint: Bool = false

    init() {
    }
    
    func copy(from other: PageLayoutCheckmarks) {
        self.didPageLayout = other.didPageLayout
        self.didTitles = other.didTitles
        self.didPrint = other.didPrint
    }
    
    // MARK: - Codable
    
    private enum CoderKeys: String, CodingKey {
        case didPageLayout, didTitles, didPrint
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(didPageLayout, forKey: .didPageLayout)
        try container.encode(didTitles, forKey: .didTitles)
        try container.encode(didPrint, forKey: .didPrint)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        didPageLayout = try values.decode(Bool.self, forKey: .didPageLayout)
        didTitles = try values.decode(Bool.self, forKey: .didTitles)
        didPrint = try values.decode(Bool.self, forKey: .didPrint)
    }
    
}


