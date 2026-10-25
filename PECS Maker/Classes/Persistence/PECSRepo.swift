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
import CryptoKit
import BoardLibrary

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

class PECSRepo : ObservableTopic, Hashable, Equatable, Identifiable, Codable, RepoProtocol {
    
    

    var id = UUID()
    
    var version: Int = 3
    var contentRevision = UUID().uuidString
    struct Hierarchy: Codable { var childOrder: [UUID] = [] }
    var hierarchy = Hierarchy()
    var localization: BoardLocalization?
    private var resolvingLanguage = false
    private var baseTopicImage: UIImage?
    private var baseCoverFilename = "TopicImage.png"
    private var baseCoverData: Data?
    private var coverImages: [String: UIImage] = [:]
    private var coverImagePaths: [String: String] = [:]
    var editingLanguage: String { localization?.preferredLanguage ?? BoardLanguage.appLanguage }

    /// Board lists render the current language without persisting a display projection.
    func refreshLocalizedThumbnail() {
        guard generateTopicThumbnail else { return }
        let state = PageLayoutState(topic: self, setupSinks: false, scheduleGeneratedThumbnail: false)
        resolvingLanguage = true
        topicImage = state.createTopicImage()
        resolvingLanguage = false
    }

    func invalidateInactiveGeneratedCovers() {
        coverImages = coverImages.filter { $0.key == editingLanguage }
        coverImagePaths = coverImagePaths.filter { $0.key == editingLanguage }
    }

    func selectLanguage(_ language: String?) {
        localization?.preferredLanguage = language.map(BoardLanguage.normalize)
        resolveLanguage()
    }

    func resolveLanguage() {
        resolvingLanguage = true
        if let title = localization?.title.resolve(language: editingLanguage).text { topicName = title }
        let cover = BoardLanguage.candidates(for: editingLanguage).compactMap { coverImages[$0] }.first
        if let image = cover ?? baseTopicImage { topicImage = image }
        if generateTopicThumbnail && cover == nil { generatedThumbnailNeedsUpdate = true }
        photos.editingLanguage = editingLanguage
        photos.photoItems.forEach { $0.selectLanguage(editingLanguage) }
        resolvingLanguage = false
        objectWillChange.send()
    }

    var topic: Topic
    var pageSize: PageSize
    var orientation: PageOrientation
    var layout: PageLayout
    var photos: PhotoBrowserData
    var checkmarks: PageLayoutCheckmarks
    var mainMenuAction: MainMenuAction?
    var formatting: CollageFormatting
    
    static func == (lhs: PECSRepo, rhs: PECSRepo) -> Bool {
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
    
    func hash(into hasher: inout Hasher) {
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

    
    /// Set only for user-created boards; consumed after the first committed name.
    var offersSuggestionsAfterNaming = false

    /// Recognize localized factory names, including automatically numbered boards.
    static func isChosenBoardTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return !defaultBoardTitles.contains { defaultTitle in
            if trimmed.caseInsensitiveCompare(defaultTitle) == .orderedSame { return true }
            let prefix = defaultTitle + " "
            guard trimmed.lowercased().hasPrefix(prefix.lowercased()) else { return false }
            let suffix = trimmed.dropFirst(prefix.count)
            return !suffix.isEmpty && suffix.allSatisfy(\.isNumber)
        }
    }

    private static let defaultBoardTitles: [String] = Bundle.main.localizations.compactMap { language in
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return nil }
        return bundle.localizedString(forKey: "Repo.defaultTopicTitle", value: nil, table: "Localizable")
    } + [L10n.Repo.defaultTopicTitle]

    //MARK: TopicProtocol
    //These 2 need to be r/w
    @Published var topicName: String {
        didSet {
            topic.topicName = topicName
            if !resolvingLanguage, oldValue != topicName {
                let language = editingLanguage
                localization?.title.edit(topicName, language: language)
            }
        }
    }
    var topicDirectoryName: String? {
        didSet {
            topic.topicDirectoryName = topicDirectoryName
        }
    }
    
    @Published var topicImage: UIImage {
        didSet {
            topic.topicImage = topicImage
            if !resolvingLanguage, oldValue !== topicImage, baseTopicImage != nil {
                coverImages[editingLanguage] = topicImage
                coverImagePaths[editingLanguage] = "locales/\(editingLanguage)/images/board-cover-\(UUID().uuidString).png"
            }
        }
        
    }
    var topicImageSymbolSource: SymbolSource?
    
    var generateTopicThumbnail: Bool = true
    // Persisted before deferred cover work so interrupted sessions recover on load.
    var generatedThumbnailNeedsUpdate = false
    var topicCategory: ThemeFramework.TopicCategory { topic.topicCategory }
    var hasSkin: Bool? { topic.hasSkin }
    var hasSoundTheme: Bool? { topic.hasSoundTheme }
    

    
    required init(directoryForNewTopic: URL, topic: PersistenceFramework.Topic) throws {

        assert(directoryForNewTopic != RepoHelper.documentsDirectory )

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

        baseTopicImage = topicImage
        localization = BoardLocalization(title: BoardText(key: "board.title", sourceLanguage: BoardLanguage.appLanguage, text: topicName), languages: [BoardLanguage.appLanguage])
        photos.editingLanguage = editingLanguage
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
    
    func relocate(to directory: URL) {
        docDir = directory
        topicDirectoryName = directory.lastPathComponent
        for card in photos.photoItems { card.relocateResources(to: directory) }
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
        case contentRevision, hierarchy, coverImagePaths, localization, id, offersSuggestionsAfterNaming, version, topic, generateTopicThumbnail, generatedThumbnailNeedsUpdate, topicImageSymbolSource, pageSize, orientation, layout, photos, checkmarks, mainMenuAction, formatting
    }
    
    private enum TopicMetadataKeys: String, CodingKey {
        case topicName, topicCategory, topicDirectoryName, hasSkin, hasSoundTheme, imageFileName
    }

    // Used for persistent storing of products to disk.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(contentRevision, forKey: .contentRevision)
        try container.encode(hierarchy, forKey: .hierarchy)
        try container.encode(localization, forKey: .localization)
        try container.encode(offersSuggestionsAfterNaming, forKey: .offersSuggestionsAfterNaming)
        try container.encode(version, forKey: .version)
        var metadata = container.nestedContainer(keyedBy: TopicMetadataKeys.self, forKey: .topic)
        try metadata.encode(localization == nil ? topicName : "", forKey: .topicName)
        try metadata.encode(topic.topicCategory, forKey: .topicCategory)
        try metadata.encode(topicDirectoryName, forKey: .topicDirectoryName)
        try metadata.encodeIfPresent(topic.hasSkin, forKey: .hasSkin)
        try metadata.encodeIfPresent(topic.hasSoundTheme, forKey: .hasSoundTheme)
        try metadata.encode(baseCoverFilename, forKey: .imageFileName)
        if let directory = encoder.userInfo[.baseURL] as? URL {
            let url = directory.appendingPathComponent(baseCoverFilename)
            if !FileManager.default.fileExists(atPath: url.path) {
                guard let data = baseCoverData ?? (baseTopicImage ?? topicImage).pngData() else {
                    throw PhotoItemError(message: "Unable to encode board cover")
                }
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try data.write(to: url, options: .atomic)
            }
        }
        try container.encode(coverImagePaths, forKey: .coverImagePaths)
        if let directory = encoder.userInfo[.baseURL] as? URL {
            for (language, image) in coverImages {
                guard let path = coverImagePaths[language] else { continue }
                let url = directory.appendingPathComponent(path)
                try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
                try ImageEncoder.save(image: image, to: url, format: .png)
            }
        }
        try container.encode(generateTopicThumbnail, forKey: .generateTopicThumbnail)
        try container.encode(generatedThumbnailNeedsUpdate, forKey: .generatedThumbnailNeedsUpdate)
        try container.encodeIfPresent(topicImageSymbolSource, forKey: .topicImageSymbolSource)
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
        BoardLoadMetrics.shared.recordRepositoryDecode()
        let values = try decoder.container(keyedBy: CoderKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        localization = try values.decodeIfPresent(BoardLocalization.self, forKey: .localization)
        offersSuggestionsAfterNaming = try values.decodeIfPresent(Bool.self, forKey: .offersSuggestionsAfterNaming) ?? false
        version = try values.decode(Int.self, forKey: .version)
        guard (1...3).contains(version) else { throw PhotoItemError(message: "Unsupported board version") }
        contentRevision = try values.decodeIfPresent(String.self, forKey: .contentRevision) ?? ""
        hierarchy = try values.decodeIfPresent(Hierarchy.self, forKey: .hierarchy) ?? Hierarchy()
        topic =  try values.decode(Topic.self, forKey: .topic)
        generateTopicThumbnail = try values.decodeIfPresent(Bool.self, forKey: .generateTopicThumbnail) ?? true
        generatedThumbnailNeedsUpdate = try values.decodeIfPresent(Bool.self, forKey: .generatedThumbnailNeedsUpdate) ?? true
        topicImageSymbolSource = try values.decodeIfPresent(SymbolSource.self, forKey: .topicImageSymbolSource)
        
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
        
        guard let baseURL = decoder.userInfo[.baseURL] as? URL else {
            let message = "JSON decoder userInfo does not contain base URL"
            logger.logError(.repo, message)
            throw ImageEncoderError(message: message)
        }
        self.docDir = baseURL
        if !values.contains(.id) {
            let components = baseURL.path.components(separatedBy: "/topics/")
            id = DocumentPaths.provisionalID(components.last ?? baseURL.lastPathComponent)
        }
        topicDirectoryName = baseURL.lastPathComponent
        
        self.topicName = topic.topicName
        self.topicImage = topic.topicImage
        baseTopicImage = topicImage
        let metadata = try values.nestedContainer(keyedBy: TopicMetadataKeys.self, forKey: .topic)
        baseCoverFilename = try metadata.decode(String.self, forKey: .imageFileName)
        baseCoverData = try Data(contentsOf: baseURL.appendingPathComponent(baseCoverFilename))
        coverImagePaths = try values.decodeIfPresent([String: String].self, forKey: .coverImagePaths) ?? [:]
        for (language, path) in coverImagePaths {
            coverImages[language] = try ImageEncoder.load(from: baseURL.appendingPathComponent(path))
        }
        if localization == nil {
            localization = BoardLocalization(title: BoardText(key: "board.title", sourceLanguage: BoardLanguage.unassigned, text: topicName), languages: [BoardLanguage.unassigned])
        } else if let tables = decoder.userInfo[.boardStringTables] as? [String: [String: String]] {
            localization?.title.load(tables: tables)
        }
        resolveLanguage()
    }
    
    static func createFolderName(for topicName: String) -> String {
        let folderName = topicName
        return folderName
    }
    
    @discardableResult func save(directory: URL) throws -> URL {
        
        //let directoryURL = try Topic.dataModelURL(directory: directory, create: true)
        
        self.docDir = directory
        
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        
        contentRevision = UUID().uuidString
        try Data(contentRevision.utf8).write(to: directory.appendingPathComponent(".index-pending"), options: .atomic)
        let childRoot = directory.appendingPathComponent("children")
        if FileManager.default.fileExists(atPath: childRoot.path) {
            let children = try FileManager.default.contentsOfDirectory(at: childRoot, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
            let ids = Set(children.compactMap { try? BoardDocumentReader.read($0,relativePath:$0.path.components(separatedBy:"/topics/").last ?? $0.lastPathComponent).id })
            hierarchy.childOrder = hierarchy.childOrder.filter { ids.contains($0) }
            hierarchy.childOrder += ids.subtracting(hierarchy.childOrder).sorted { $0.uuidString < $1.uuidString }
        }
        let indexFileURL = directory.appendingPathComponent(Self.indexFileName, isDirectory: false)

        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.userInfo[.baseURL] = directory
        
        var tables: [String: [String: String]] = [:]
        let texts = [localization?.title].compactMap { $0 } + photos.photoItems.compactMap(\.localizedTitle)
        for text in texts {
            for (language, value) in text.values { tables[language, default: [:]][text.key] = value }
        }
        localization?.languages = tables.keys.sorted()
        encoder.userInfo[.boardStringTables] = tables
        var tableFiles: [String: String] = [:]
        for (language, strings) in tables {
            let localeDirectory = directory.appendingPathComponent("locales").appendingPathComponent(language)
            try FileManager.default.createDirectory(at: localeDirectory, withIntermediateDirectories: true)
            let tableEncoder = JSONEncoder()
            tableEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try tableEncoder.encode(strings)
            let digest = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let filename = "strings-\(digest).json"
            tableFiles[language] = filename
            let url = localeDirectory.appendingPathComponent(filename)
            if !FileManager.default.fileExists(atPath: url.path) { try data.write(to: url, options: .atomic) }
        }
        localization?.tableFiles = tableFiles
        version = 3
        let encoded = try encoder.encode(self)
        try encoded.write(to: indexFileURL, options: .atomic)
        NotificationCenter.default.post(name: .boardDocumentSaved, object: directory)
        try photos.removeUnusedLegacyImages(in: directory)
        try removeUnreferencedManagedResources(in: directory, index: encoded)
        
        return directory

    }
    

    /// Run only after the index commit: failed saves retain old resources, while
    /// successful exports do not carry deleted text/image revisions as hidden files.
    private func removeUnreferencedManagedResources(in directory: URL, index: Data) throws {
        var referenced = Set(photos.photoItems.flatMap { card in
            [card.imageFileName, card.audioFileName].compactMap { $0 } + Array(card.imageOverrides.values)
        } + Array(coverImagePaths.values))
        if let json = try JSONSerialization.jsonObject(with: index) as? [String: Any],
           let topic = json["topic"] as? [String: Any], let image = topic["imageFileName"] as? String {
            referenced.insert(image)
        }
        for (language, filename) in localization?.tableFiles ?? [:] {
            referenced.insert("locales/\(language)/\(filename)")
        }
        // Directory enumeration resolves symlinks (notably /var -> /private/var
        // on devices). Compare canonical file paths, never trim a raw path prefix.
        let referencedPaths = Set(referenced.map {
            directory.appendingPathComponent($0).resolvingSymlinksInPath().standardizedFileURL.path
        })
        for folder in ["locales", "images"] {
            let root = directory.appendingPathComponent(folder)
            guard let files = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey]) else { continue }
            for case let url as URL in files {
                guard (try url.resourceValues(forKeys: [.isRegularFileKey])).isRegularFile == true else { continue }
                let managedTable = url.lastPathComponent == "strings.json" ||
                    (url.lastPathComponent.hasPrefix("strings-") && url.pathExtension == "json")
                let managedImage = url.pathExtension.lowercased() == "png"
                if (managedTable || managedImage),
                   !referencedPaths.contains(url.resolvingSymlinksInPath().standardizedFileURL.path) {
                    try FileManager.default.removeItem(at: url)
                }
            }
        }
    }

    // The archived file name, name saved to Documents folder.
    private let dataFileName = "PageLayoutState"

    static func load(directory: URL) throws -> Self {
        let directory = try dataModelURL(directory: directory, create: false)
        _ = try BoardDocumentReader.read(directory, relativePath: directory.lastPathComponent)
        let indexFileURL = directory.appendingPathComponent(Self.indexFileName, isDirectory: false)
        let codedData = try Data(contentsOf: indexFileURL)
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = directory
        // Read the manifest before decoding cards so all source and inactive tables survive.
        struct Manifest: Decodable { var version: Int; var localization: BoardLocalization? }
        let manifest = try JSONDecoder().decode(Manifest.self, from: codedData)
        guard (1...3).contains(manifest.version) else { throw PhotoItemError(message: "This board uses an unsupported document version.") }
        if let localization = manifest.localization {
            var tables: [String: [String: String]] = [:]
            for language in localization.languages {
                let url = directory.appendingPathComponent("locales").appendingPathComponent(language).appendingPathComponent(localization.tableFiles?[language] ?? "strings.json")
                tables[language] = try JSONDecoder().decode([String: String].self, from: Data(contentsOf: url))
            }
            decoder.userInfo[.boardStringTables] = tables
            decoder.userInfo[.boardEditingLanguage] = localization.preferredLanguage ?? BoardLanguage.appLanguage
        }
        let decoded = try decoder.decode(Self.self, from: codedData)
        if manifest.localization == nil,
           let root = Bundle.main.url(forResource: "StarterBoards", withExtension: nil) {
            try StarterBoardInstaller.upgradeLegacy(decoded, from: root)
        }
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


extension Notification.Name { static let boardDocumentSaved = Notification.Name("BoardDocumentSaved") }

/// Counters prove that catalogue paths do not instantiate repository/card models.
final class BoardLoadMetrics {
    static let shared = BoardLoadMetrics()
    private let lock = NSLock()
    private var repositoryDecodes = 0
    func recordRepositoryDecode() { lock.lock(); repositoryDecodes += 1; lock.unlock() }
    var fullRepositoryDecodes: Int { lock.lock(); defer { lock.unlock() }; return repositoryDecodes }
}
