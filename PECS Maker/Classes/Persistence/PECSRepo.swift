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
import BoardDomain

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

@MainActor
class PECSRepo: @MainActor ObservableTopic, @MainActor Hashable, Identifiable, @MainActor Codable, @MainActor RepoProtocol {
    private static let boardStore = BoardStore(indexFileName: indexFileName)

    nonisolated let id: UUID
    
    var version: Int = 1

    var topic: Topic
    var pageSize: PageSize
    var orientation: PageOrientation
    var layout: PageLayout
    var photos: PhotoBrowserData
    var checkmarks: PageLayoutCheckmarks
    var mainMenuAction: MainMenuAction?
    var formatting: CollageFormatting
    
    nonisolated static func == (lhs: PECSRepo, rhs: PECSRepo) -> Bool {
        /*
        lhs.topic == rhs.topic &&
        lhs.pageSize == rhs.pageSize &&
        lhs.orientation == rhs.orientation &&
        lhs.layout == rhs.layout &&
        lhs.photos == rhs.photos &&
        lhs.checkmarks == rhs.checkmarks
         */
        lhs.id == rhs.id
    }
    
    nonisolated func hash(into hasher: inout Hasher) {
        /*
        hasher.combine(topic)
        hasher.combine(pageSize)
        hasher.combine(orientation)
        hasher.combine(layout)
        hasher.combine(photos)
        hasher.combine(checkmarks)
         */
        hasher.combine(id)
    }

    
    //MARK: TopicProtocol
    //These 2 need to be r/w
    @Published var topicName: String {
        didSet {
            topic.topicName = topicName
        }
    }
    var topicDirectoryName: String? {
        didSet {
            topic.topicDirectoryName = topicDirectoryName
        }
    }
    
    @Published var topicImage: UIImage {
        didSet { topic.topicImage = topicImage }
        
    }
    
    var generateTopicThumbnail: Bool = true
    var topicCategory: ThemeFramework.TopicCategory { topic.topicCategory }
    var hasSkin: Bool? { topic.hasSkin }
    var hasSoundTheme: Bool? { topic.hasSoundTheme }
    

    
    required init(directoryForNewTopic: URL, topic: PersistenceFramework.Topic) throws {

        self.id = UUID()
        self.docDir = directoryForNewTopic
        //self.indexFileUrl = self.docDir.appendingPathComponent(indexFileName)
        
        self.topic = topic
        self.topicName = topic.topicName
        self.topicDirectoryName = self.docDir.lastPathComponent
        self.topicImage = topic.topicImage
        
        self.pageSize = .a4
        self.orientation = .portrait
        self.layout = PageLayout(width: 1, height: 1)
        self.photos = PhotoBrowserData()
        self.checkmarks = PageLayoutCheckmarks()
        self.formatting = CollageFormatting()

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

    /*
    //The reason for having == and hash use the ID is
    //because we need our Swift UI list to allow duplicate items,
    //but I can't remmeber why we did that.
    //But maybe docDir is a better bet.
    static func == (lhs: PECSRepo, rhs: PECSRepo) -> Bool {
        //lhs.id == rhs.id
        //lhs.docDir == rhs.docDir
        
    }
    
    func hash(into hasher: inout Hasher) {
        //hasher.combine(id.hashValue)
        hasher.combine(docDir.hashValue)
    }
     */
    
    
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
        case id, version, topic, generateTopicThumbnail, pageSize, orientation, layout, photos, checkmarks, mainMenuAction, formatting
    }

    private struct PersistedTopic: Codable {
        var topicName: String
        var topicCategory: ThemeFramework.TopicCategory
        var imageFileName: String
        var topicDirectoryName: String?
        var hasSkin: Bool?
        var hasSoundTheme: Bool?
    }
    
    // Used for persistent storing of products to disk.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(version, forKey: .version)
        try container.encode(
            PersistedTopic(
                topicName: topic.topicName,
                topicCategory: topic.topicCategory,
                imageFileName: Self.topicImageFileName,
                topicDirectoryName: topic.topicDirectoryName,
                hasSkin: topic.hasSkin,
                hasSoundTheme: topic.hasSoundTheme
            ),
            forKey: .topic
        )
        try container.encode(generateTopicThumbnail, forKey: .generateTopicThumbnail)
        //try container.encode(topicName, forKey: .topicName)
        try container.encode(pageSize, forKey: .pageSize)
        try container.encode(orientation, forKey: .orientation)
        try container.encode(layout, forKey: .layout)
        try container.encode(photos, forKey: .photos)
        try container.encode(checkmarks, forKey: .checkmarks)
        try container.encode(mainMenuAction, forKey: .mainMenuAction)
        try container.encode(formatting, forKey: .formatting)
    }
    
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        guard let baseURL = decoder.userInfo[.baseURL] as? URL else {
            let message = "JSON decoder userInfo does not contain base URL"
            logger.logError(.repo, message)
            throw ImageEncoderError(message: message)
        }
        let persistedTopic = try values.decode(PersistedTopic.self, forKey: .topic)
        let actualDirectoryName = baseURL.lastPathComponent
        let wasCopiedToNewDirectory = persistedTopic.topicDirectoryName.map {
            $0 != actualDirectoryName
        } ?? false
        if wasCopiedToNewDirectory {
            id = UUID()
        } else {
            id = try values.decodeIfPresent(UUID.self, forKey: .id)
                ?? Self.legacyStableID(for: baseURL)
        }
        version = try values.decode(Int.self, forKey: .version)
        let topicImageURL = baseURL.appendingPathComponent(persistedTopic.imageFileName)
        guard let topicImage = try ImageEncoder.load(from: topicImageURL) else {
            throw ImageEncoderError(message: "Unable to load topic image at \(topicImageURL.path)")
        }
        topic = Topic(
            topicName: persistedTopic.topicName,
            topicCategory: persistedTopic.topicCategory,
            topicImage: topicImage,
            topicDirectoryName: actualDirectoryName,
            hasSkin: persistedTopic.hasSkin,
            hasSoundTheme: persistedTopic.hasSoundTheme
        )
        generateTopicThumbnail = try values.decodeIfPresent(Bool.self, forKey: .generateTopicThumbnail) ?? true
        
        self.topicName = topic.topicName
        self.topicDirectoryName = topic.topicDirectoryName
        
        pageSize =  try values.decode(PageSize.self, forKey: .pageSize)
        orientation =  try values.decode(PageOrientation.self, forKey: .orientation)
        layout =  try values.decode(PageLayoutType.self, forKey: .layout)
        photos = try values.decode(PhotoBrowserData.self, forKey: .photos)
        checkmarks = try values.decode(PageLayoutCheckmarks.self, forKey: .checkmarks)
        mainMenuAction = try? values.decode(MainMenuAction.self, forKey: .mainMenuAction)
        
        //App has never ben released with formatting as nil, but I do have
        //some legacy topics on my phone.
        if let formatting = try? values.decode(CollageFormatting.self, forKey: .formatting) {
            self.formatting = formatting
        }
        else {
            self.formatting = CollageFormatting()
        }
        
        for photoItem in photos.photoItems {
            try photoItem.bindAssets(to: baseURL)
        }
        self.docDir = baseURL
        
        self.topicName = topic.topicName
        self.topicImage = topic.topicImage

    }
    
    static func createFolderName(for topicName: String) -> String {
        let folderName = topicName
        return folderName
    }
    
    @discardableResult func save(directory: URL) throws -> URL {
        self.docDir = directory

        let archive = try persistenceArchive()
        try AtomicBoardPersistence.save(
            archive,
            to: directory,
            indexFileName: Self.indexFileName
        )
        didPersist(to: directory)
        return directory
    }

    func makePersistenceArchive(directory: URL? = nil) throws -> BoardArchive {
        if let directory {
            docDir = directory
        }
        return try persistenceArchive()
    }

    nonisolated static func persist(_ archive: BoardArchive, to directory: URL) async throws {
        try await boardStore.save(archive, to: directory)
    }

    func didPersist(to directory: URL) {
        docDir = directory
        for photoItem in photos.photoItems {
            photoItem.didPersist(to: directory)
        }
    }

    private func persistenceArchive() throws -> BoardArchive {

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.outputFormatting.insert(.sortedKeys)

        var assets = [Self.topicImageFileName: try Self.pngData(for: topic.topicImage)]
        for photoItem in photos.photoItems {
            for (fileName, data) in try photoItem.persistenceAssets() {
                if assets.updateValue(data, forKey: fileName) != nil {
                    throw PhotoItemError(message: "Duplicate persisted asset filename: \(fileName)")
                }
            }
        }

        let encoded = try encoder.encode(self)
        return BoardArchive(index: encoded, assets: assets)
    }
    

    // The archived file name, name saved to Documents folder.
    private let dataFileName = "PageLayoutState"

    static func load(directory: URL) throws -> Self {
        let directory = try dataModelURL(directory: directory, create: false)
        try AtomicBoardPersistence.recover(at: directory)
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
    static private let topicImageFileName = "TopicImage.png"

    private static func pngData(for image: UIImage) throws -> Data {
        guard let data = image.pngData() else {
            throw ImageEncoderError(message: "Unable to encode topic image")
        }
        return data
    }

    private static func legacyStableID(for directory: URL) -> UUID {
        let bytes = Array(directory.standardizedFileURL.path.utf8)
        var high: UInt64 = 0xcbf29ce484222325
        var low: UInt64 = 0x84222325cbf29ce4
        for byte in bytes {
            high = (high ^ UInt64(byte)) &* 0x100000001b3
            low = (low ^ UInt64(byte)) &* 0x9e3779b185ebca87
        }
        var uuidBytes: uuid_t = (
            UInt8(truncatingIfNeeded: high >> 56), UInt8(truncatingIfNeeded: high >> 48),
            UInt8(truncatingIfNeeded: high >> 40), UInt8(truncatingIfNeeded: high >> 32),
            UInt8(truncatingIfNeeded: high >> 24), UInt8(truncatingIfNeeded: high >> 16),
            UInt8(truncatingIfNeeded: high >> 8), UInt8(truncatingIfNeeded: high),
            UInt8(truncatingIfNeeded: low >> 56), UInt8(truncatingIfNeeded: low >> 48),
            UInt8(truncatingIfNeeded: low >> 40), UInt8(truncatingIfNeeded: low >> 32),
            UInt8(truncatingIfNeeded: low >> 24), UInt8(truncatingIfNeeded: low >> 16),
            UInt8(truncatingIfNeeded: low >> 8), UInt8(truncatingIfNeeded: low)
        )
        withUnsafeMutableBytes(of: &uuidBytes) { rawBytes in
            rawBytes[6] = (rawBytes[6] & 0x0f) | 0x50
            rawBytes[8] = (rawBytes[8] & 0x3f) | 0x80
        }
        return UUID(uuid: uuidBytes)
    }
    
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
