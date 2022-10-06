//
//  Topic.swift
//  PECS Maker
//
//  Created by Andy on 03/10/2022.
//

import UIKit
import Photos
import LogFramework

extension CodingUserInfoKey {
    static let baseURL = CodingUserInfoKey(rawValue: "baseURL")!
}

public enum TopicError : LocalizedError {
    //case loadTopic(url: URL?, originalError: Error?)
    case saveTopic(url: URL? = nil, originalError: Error? = nil)
    //case loadImage(localizedDescription: String)
    //case saveImage(localizedDescription: String)
    //case topicFileDoesNotExist(localizedDescription: String)
    //case decodeError(localizedDescription: String)
    
    public var errorDescription: String? {
        switch self {
        case .saveTopic(_, _):
            return "Unable to save the topic"
        }
    }
    
}


class Topic : Hashable, Equatable, Identifiable, Codable {

    //The reason for having == and hash use the ID is
    //because we need our Swift UI list to allow duplicate items
    static func == (lhs: Topic, rhs: Topic) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }
    
    //var id = UUID()
    //var image: UIImage
    var version: Int = 1
    var topicName: String
    var pageSize: PageSize
    var orientation: PageOrientation
    var layout: PageLayout
    var photos: PhotoBrowserData
    
    init(topicName: String, pageSize: PageSize, orientation: PageOrientation, layout: PageLayout, photos: PhotoBrowserData) {
        self.topicName = topicName
        self.pageSize = pageSize
        self.orientation = orientation
        self.layout = layout
        self.photos = photos
    }
    
    // MARK: - Codable
    
    private enum CoderKeys: String, CodingKey {
        case version, topicName, pageSize, orientation, layout, photos
    }
    
    // Used for persistent storing of products to disk.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(topicName, forKey: .topicName)
        try container.encode(pageSize, forKey: .pageSize)
        try container.encode(orientation, forKey: .orientation)
        try container.encode(layout, forKey: .layout)
        try container.encode(photos, forKey: .photos)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        //id = try values.decode(UUID.self, forKey: .id)
        version = try values.decode(Int.self, forKey: .version)
        topicName = try values.decode(String.self, forKey: .topicName)
        pageSize =  try values.decode(PageSize.self, forKey: .pageSize)
        orientation =  try values.decode(PageOrientation.self, forKey: .orientation)
        layout =  try values.decode(PageLayoutType.self, forKey: .layout)
        photos = try values.decode(PhotoBrowserData.self, forKey: .photos)
    }
    
    static func createFolderName(for topicName: String) -> String {
        let folderName = topicName
        return folderName
    }
    
    @discardableResult func save(directory: URL) throws -> URL {
        
        let directoryURL = try Topic.dataModelURL(directory: directory, create: true)
        let indexFileURL = directoryURL.appendingPathComponent(Topic.indexFileName, isDirectory: false)

        let encoder = JSONEncoder()
        encoder.userInfo[.baseURL] = directoryURL
        
        let encoded = try encoder.encode(self)
        do {
            try encoded.write(to: indexFileURL)
        } catch {
            logger.logError(.repo, "Could not write to \(directoryURL.path)", error)
        }
        
        return directoryURL

    }
    
    @discardableResult func save() throws -> URL {
        let directoryURL = try Topic.dataModelURL(topicName: topicName, create: true)
        return try save(directory: directoryURL)
    }
    
    // The archived file name, name saved to Documents folder.
    private let dataFileName = "PageLayoutState"

    static func load(directory: URL) throws -> Topic {
        let directory = try dataModelURL(directory: directory, create: false)
        let indexFileURL = directory.appendingPathComponent(Topic.indexFileName, isDirectory: false)
        let codedData = try Data(contentsOf: indexFileURL)
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = directory
        let decoded = try decoder.decode(Topic.self, from: codedData)
        return decoded
    }

    static func load(topicName: String) throws -> Topic {
        let directory = try dataModelURL(topicName: topicName)
        return try load(directory: directory)
    }
    
//    func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(photoBrowserData, forKey: .photoBrowserData)
//    }
//
//    func decode(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        photoBrowserData = try values.decode(PhotoBrowserData.self, forKey: .photoBrowserData)
//    }
    
    static private func documentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    static private var indexFileName: String = "index.json"
    
    static private func dataModelURL(directory dataModelFolder: URL, create: Bool = false) throws -> URL {
        if create {
            try FileManager.default.createDirectory(at: dataModelFolder, withIntermediateDirectories: true)
        }
        return dataModelFolder
    }
    
    static private func dataModelURL(topicName: String, create: Bool = false) throws -> URL {
        let folderName = createFolderName(for: topicName)
        let docURL = documentsDirectory()
        let dataModelFolder = docURL.appendingPathComponent(folderName, isDirectory: true)
        return try dataModelURL(directory: dataModelFolder)
    }

    
    
    
}


