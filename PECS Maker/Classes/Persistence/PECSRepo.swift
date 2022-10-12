//
//  Topic.swift
//  PECS Maker
//
//  Created by Andy on 03/10/2022.
//

import UIKit
import Photos
import LogFramework
import PersistenceFramework
import ThemeFramework

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

class PECSRepo : Hashable, Equatable, Identifiable, Codable, RepoProtocol {

    var version: Int = 1

    var topic: Topic
    var pageSize: PageSize
    var orientation: PageOrientation
    var layout: PageLayout
    var photos: PhotoBrowserData
    var checkmarks: PageLayoutCheckmarks

    //MARK: TopicProtocol
    //These 2 need to be r/w
    var topicName: String
    var topicDirectoryName: String?
    var topicCategory: ThemeFramework.TopicCategory { topic.topicCategory }
    var hasSkin: Bool? { topic.hasSkin }
    var hasSoundTheme: Bool? { topic.hasSoundTheme }
    var topicImage: UIImage { topic.topicImage }
    

    
    required init(directoryForNewTopic: URL, topic: PersistenceFramework.Topic) throws {

        assert(directoryForNewTopic != RepoHelper.documentsDirectory )

        self.docDir = directoryForNewTopic
        //self.indexFileUrl = self.docDir.appendingPathComponent(indexFileName)
        
        self.topic = topic
        self.topicName = topic.topicName
        self.topicDirectoryName = self.docDir.lastPathComponent
        
        self.pageSize = .a4
        self.orientation = .portrait
        self.layout = PageLayout(width: 1, height: 1)
        self.photos = PhotoBrowserData()
        self.checkmarks = PageLayoutCheckmarks()

        try saveToFile()
    }
    
    static func directoryContainsRepo(_ directory: URL) -> Bool {
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: directory.path) {
            return false
        }
        let indexFileJSON = directory.appendingPathComponent(indexFileName)
        if fileManager.fileExists(atPath: indexFileJSON.path) {
            return true
        }
        return false
    }
    
    static func load(fromDirectory directory: URL, requiredFields: [PersistenceFramework.QuizFieldType]?, createIfMissing: Bool, assertIfRoot: Bool) throws -> Self {
        return try load(directory: directory)
    }
    
    @discardableResult func saveToFile() throws -> URL {
        return try save(directory: self.docDir)
    }

    
    //The reason for having == and hash use the ID is
    //because we need our Swift UI list to allow duplicate items
    static func == (lhs: PECSRepo, rhs: PECSRepo) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }
    
    
    /*
    init(topic: Topic, pageSize: PageSize, orientation: PageOrientation, layout: PageLayout, photos: PhotoBrowserData) {
        self.topic = topic
        self.topicName = topic.topicName
        self.topicDirectoryName = topic.topicDirectoryName
        self.docDir = topic.topicDirectoryName
        
        self.pageSize = pageSize
        self.orientation = orientation
        self.layout = layout
        self.photos = photos
    }*/
    
    // MARK: - Codable
    
    private enum CoderKeys: String, CodingKey {
        case version, topic, pageSize, orientation, layout, photos, checkmarks
    }
    
    // Used for persistent storing of products to disk.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(topic, forKey: .topic)
        //try container.encode(topicName, forKey: .topicName)
        try container.encode(pageSize, forKey: .pageSize)
        try container.encode(orientation, forKey: .orientation)
        try container.encode(layout, forKey: .layout)
        try container.encode(photos, forKey: .photos)
        try container.encode(checkmarks, forKey: .checkmarks)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        //id = try values.decode(UUID.self, forKey: .id)
        version = try values.decode(Int.self, forKey: .version)
        topic =  try values.decode(Topic.self, forKey: .topic)
        
        self.topicName = topic.topicName
        self.topicDirectoryName = topic.topicDirectoryName
        
        pageSize =  try values.decode(PageSize.self, forKey: .pageSize)
        orientation =  try values.decode(PageOrientation.self, forKey: .orientation)
        layout =  try values.decode(PageLayoutType.self, forKey: .layout)
        photos = try values.decode(PhotoBrowserData.self, forKey: .photos)
        checkmarks = try values.decode(PageLayoutCheckmarks.self, forKey: .checkmarks)

        guard let baseURL = decoder.userInfo[.baseURL] as? URL else {
            let message = "JSON decoder userInfo does not contain base URL"
            logger.logError(.repo, message)
            throw ImageEncoderError(message: message)
        }
        self.docDir = baseURL
        
        self.topicName = topic.topicName

    }
    
    static func createFolderName(for topicName: String) -> String {
        let folderName = topicName
        return folderName
    }
    
    @discardableResult func save(directory: URL) throws -> URL {
        
        //let directoryURL = try Topic.dataModelURL(directory: directory, create: true)
        
        self.docDir = directory
        
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        let indexFileURL = directory.appendingPathComponent(Self.indexFileName, isDirectory: false)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.userInfo[.baseURL] = directory
        
        let encoded = try encoder.encode(self)
        do {
            try encoded.write(to: indexFileURL)
        } catch {
            logger.logError(.repo, "Could not write to \(directory.path)", error)
        }
        
        return directory

    }
    

    // The archived file name, name saved to Documents folder.
    private let dataFileName = "PageLayoutState"

    static func load(directory: URL) throws -> Self {
        let directory = try dataModelURL(directory: directory, create: false)
        let indexFileURL = directory.appendingPathComponent(Self.indexFileName, isDirectory: false)
        let codedData = try Data(contentsOf: indexFileURL)
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = directory
        let decoded = try decoder.decode(Self.self, from: codedData)
        return decoded
    }

    static func load(topicName: String) throws -> Self {
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
    
    public static var documentsDirectory: URL {
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
        let docURL = documentsDirectory
        let dataModelFolder = docURL.appendingPathComponent(folderName, isDirectory: true)
        return try dataModelURL(directory: dataModelFolder)
    }
    
    //MARK: RepoProtocol

    var docDir: URL
    
    var items: [AnyObject] {
        photos.photoItems
    }
    

    
}


