//
//  Feature.swift
//  FeatureFramework
//
//  Created by Andy on 23/05/2024.
//

import Foundation

public struct Feature: Identifiable, Codable {
    public var id: String
    public var sendMail: Bool?
    public var name: String
    public var description: String
    public var systemIcon: String?
    public var icon: String?

    public init(id: String, name: String, description: String, systemIcon: String? = nil,
                icon: String? = nil, sendMail: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.systemIcon = systemIcon
        self.icon = icon
        self.sendMail = sendMail
    }
}
