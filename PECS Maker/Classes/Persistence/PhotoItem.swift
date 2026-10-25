//
//  PhotoItem.swift
//  PECS Maker
//
//  Created by Andy on 27/06/2022.
//

import UIKit
import Photos
import LogFramework
import PersistenceFramework
import SharedSwiftUI

public struct PhotoItemError : Error {
    public var message: String
    public init(message: String) {
        self.message = message
    }
}

struct SymbolSource: Codable, Hashable {
    enum Provider: String, Codable {
        case arasaac
        case aacStandard
    }

    let provider: Provider
    let symbolID: Int
    var isModified = false
    var languageCode: String?
    var imageURL: URL?
    var sourceURL: URL?
}

class PhotoItem : Hashable, Equatable, Identifiable, Codable {
    
    //The reason for having == and hash use the ID is
    //because we need our Swift UI list to allow duplicate items...
    //but that's the wrong way to implement Equatable so going back
    //to the proper way.
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        // SwiftUI compares an image view's item after unrelated view updates.
        // Comparing an object with itself must not encode its image twice.
        if lhs === rhs { return true }
        //lhs.id == rhs.id
        //lhs.image.hashValue == rhs.image.hashValue &&
        //If we have an assetID, use it for the comparison rather than
        //comparing the actual image becuase that's more processor intensive.
        if lhs.assetId != nil {
            if lhs.assetId != rhs.assetId {
                return false
            }
        }
        else {
            if lhs.image.pngData() != rhs.image.pngData() {
                return false
            }
        }
        if lhs.assetId != rhs.assetId {
            return false
        }
        if lhs.localizedTitle?.values != rhs.localizedTitle?.values ||
            lhs.localizedTitle?.sourceLanguage != rhs.localizedTitle?.sourceLanguage ||
            lhs.imageOverrides != rhs.imageOverrides || lhs.imageMetadata != rhs.imageMetadata { return false }
        if lhs.title != rhs.title {
            return false
        }
        if lhs.fitzgeraldKey != rhs.fitzgeraldKey {
            return false
        }
        if lhs.symbolSource != rhs.symbolSource {
            return false
        }
        if lhs.isPlaceholder != rhs.isPlaceholder { return false }
        if lhs.hasPhoto != rhs.hasPhoto { return false }
        return true
    }
    
    func hash(into hasher: inout Hasher) {
        //hasher.combine(id.hashValue)
        //hasher.combine(image.hashValue)
        //hasher.combine(asset)
        hasher.combine(assetId)
        hasher.combine(title)
        hasher.combine(fitzgeraldKey)
        hasher.combine(symbolSource)
        hasher.combine(isPlaceholder)
    }
    
    var localizedTitle: BoardText?
    private(set) var editingLanguage = BoardLanguage.appLanguage
    private var resolvingLanguage = false
    private var assignedToBoard = false

    func assignToBoard(language: String) {
        if !assignedToBoard, resourceDirectory == nil, var text = localizedTitle {
            let value = text.values[text.sourceLanguage]
            text.values.removeValue(forKey: text.sourceLanguage)
            text.sourceLanguage = BoardLanguage.normalize(language)
            text.values[text.sourceLanguage] = value
            localizedTitle = text
        }
        assignedToBoard = true
        if editingLanguage != language { selectLanguage(language) }
    }
    struct ImageMetadata: Codable, Equatable {
        var symbolSource: SymbolSource?
        var assetId: String?
        var hasPhoto: Bool
    }
    var imageOverrides: [String: String] = [:]
    private var imageMetadata: [String: ImageMetadata] = [:]
    private var baseSymbolSource: SymbolSource?
    private var baseAssetId: String?
    private var resolvedImageLanguage: String? {
        BoardLanguage.candidates(for: editingLanguage).first { imageOverrides[$0] != nil }
    }
    private var pendingImages: [String: UIImage] = [:]
    private var resourceDirectory: URL?
    var resolvedTextLanguage: String? { localizedTitle?.resolve(language: editingLanguage).language }

    func selectLanguage(_ language: String) {
        editingLanguage = BoardLanguage.normalize(language)
        resolvingLanguage = true
        if let localizedTitle { title = localizedTitle.resolve(language: editingLanguage).text }
        resolvingLanguage = false
        if imageFileName != nil { storedImage = nil }
        renderRevision = UUID()
    }

    private var resolvedImagePath: String? {
        for language in BoardLanguage.candidates(for: editingLanguage) {
            if let path = imageOverrides[language] { return path }
        }
        return imageFileName
    }

    var itemID = UUID()
    private var storedImage: UIImage?
    /// PNG already prepared by the system photo importer on a background queue.
    private var preparedPNGData: Data?
    /// In-memory visual content version; persistence dirtiness is independent.
    private(set) var renderRevision = UUID()
    private(set) var isPlaceholder = false
    private var storedHasPhoto: Bool? = true

    /// Blank cards have a transparent backing image for persistence, but no user photo.
    var hasPhoto: Bool {
        if let language = resolvedImageLanguage { return imageMetadata[language]?.hasPhoto ?? true }
        if isPlaceholder { return false }
        if let storedHasPhoto { return storedHasPhoto }
        // Boards saved before this flag existed used a transparent 1×1 image.
        let legacyBlankCard = title?.isEmpty == false && assetId == nil &&
            symbolSource == nil && isTransparentBackingImage(image)
        storedHasPhoto = !legacyBlankCard
        return !legacyBlankCard
    }

    private func isTransparentBackingImage(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage, cgImage.width == 1, cgImage.height == 1 else { return false }
        var pixel = [UInt8](repeating: 0, count: 4)
        guard let context = CGContext(data: &pixel, width: 1, height: 1,
                                      bitsPerComponent: 8, bytesPerRow: 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        return pixel[3] == 0
    }

    var image: UIImage {
        get {
            for language in BoardLanguage.candidates(for: editingLanguage) {
                if let pending = pendingImages[language] { return pending }
                if imageOverrides[language] != nil { break }
            }
            if let storedImage { return storedImage }
            let loadedImage = loadImage()
            storedImage = loadedImage
            return loadedImage
        }
        set {
            if localizedTitle != nil, imageFileName != nil {
                let metadata = ImageMetadata(symbolSource: symbolSource, assetId: assetId, hasPhoto: true)
                pendingImages[editingLanguage] = newValue
                imageMetadata[editingLanguage] = metadata
                imageOverrides[editingLanguage] = "locales/\(editingLanguage)/images/\(itemID.uuidString)-\(UUID().uuidString).png"
            }
            storedImage = newValue
            preparedPNGData = nil
            isPlaceholder = false
            if imageOverrides[editingLanguage] == nil { storedHasPhoto = true }
            renderRevision = UUID()
            if symbolSource != nil {
                symbolSource?.isModified = true
            }
            needsSave = true
        }
    }
    
    private func loadImage() -> UIImage {
        
        guard let imageURL = resourceDirectory.flatMap({ directory in resolvedImagePath.map { directory.appendingPathComponent($0) } }) ?? self.imageURL else {
            //throw ImageEncoderError(message: "Unable to load image for key \(imageFileName)")
            logger.logError(.repo, "Unable to load image from because imageURL is nil")
            return UIImage()
        }
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            //throw ImageEncoderError(message: "Unable to load image for key \(imageFileName)")
            logger.logError(.repo, "Unable to load image because file does not exist at \(imageURL.path)")
            return UIImage()
        }
        do {
            guard let image = try ImageEncoder.load(from: imageURL) else {
                //throw ImageEncoderError(message: "Unable to load image for key \(imageFileName)")
                logger.logError(.repo, "Loaded empty image from \(imageURL)")
                return UIImage()
            }
            return image
        }
        catch {
            logger.logError(.repo, "Unable to load image from \(imageURL)")
            return UIImage()
        }
    }
    
    var asset: PHAsset?
    var assetId: String? {
        get {
            if let language = resolvedImageLanguage { return imageMetadata[language]?.assetId }
            return baseAssetId
        }
        set {
            if imageOverrides[editingLanguage] != nil {
                if imageMetadata[editingLanguage] == nil { imageMetadata[editingLanguage] = ImageMetadata(hasPhoto: true) }
                imageMetadata[editingLanguage]?.assetId = newValue
            } else { baseAssetId = newValue }
        }
    }
    
    @Published var title: String? {
        didSet {
            if oldValue != title {
                renderRevision = UUID()
                if !resolvingLanguage { localizedTitle?.edit(title, language: editingLanguage) }
            }
            if !resolvingLanguage, title?.isEmpty == false { isPlaceholder = false }
        }
    }
    var fitzgeraldKey: FitzgeraldKey = .none {
        didSet { if oldValue != fitzgeraldKey { renderRevision = UUID() } }
    }
    var symbolSource: SymbolSource? {
        get {
            if let language = resolvedImageLanguage { return imageMetadata[language]?.symbolSource }
            return baseSymbolSource
        }
        set {
            if imageOverrides[editingLanguage] != nil {
                if imageMetadata[editingLanguage] == nil { imageMetadata[editingLanguage] = ImageMetadata(hasPhoto: true) }
                imageMetadata[editingLanguage]?.symbolSource = newValue
            } else { baseSymbolSource = newValue }
        }
    }
    var needsSave = false
    
    //This is nil until the file is saved/loaded to/from disk
    var imageFileName: String?
    var imageURL: URL?
    
    //This is nil until the file is saved/loaded to/from disk
    var audioFileName: String?
    var audioURL: URL?
    
    init(image: UIImage, asset: PHAsset? = nil, assetId: String? = nil, title: String? = nil,
         fitzgeraldKey: FitzgeraldKey = .none, symbolSource: SymbolSource? = nil,
         preparedPNGData: Data? = nil) {
        self.needsSave = true
        self.fitzgeraldKey = fitzgeraldKey
        self.baseSymbolSource = symbolSource
        self.storedImage = image
        self.preparedPNGData = preparedPNGData
        if assetId == nil {
            self.baseAssetId = asset?.localIdentifier
        }
        else {
            self.baseAssetId = assetId
        }
        self.asset = asset
        self.title = title
        self.localizedTitle = BoardText(sourceLanguage: editingLanguage, text: title)
        //print("image init: id = \(itemID)")
    }
    
    func copy() -> PhotoItem {
        let photoItem = PhotoItem(image: self.image, asset: asset, assetId: assetId,
                                  title: self.title, fitzgeraldKey: fitzgeraldKey,
                                  symbolSource: symbolSource, preparedPNGData: preparedPNGData)
        photoItem.assignedToBoard = assignedToBoard
        photoItem.localizedTitle = localizedTitle
        photoItem.localizedTitle?.key = UUID().uuidString
        photoItem.editingLanguage = editingLanguage
        photoItem.imageFileName = imageFileName
        photoItem.audioFileName = audioFileName
        photoItem.audioURL = audioURL
        photoItem.imageURL = imageURL
        photoItem.resourceDirectory = resourceDirectory
        photoItem.baseSymbolSource = baseSymbolSource
        photoItem.baseAssetId = baseAssetId
        photoItem.imageMetadata = imageMetadata
        photoItem.imageOverrides = imageOverrides
        photoItem.pendingImages = pendingImages
        photoItem.needsSave = needsSave
        photoItem.isPlaceholder = isPlaceholder
        photoItem.storedHasPhoto = storedHasPhoto
        return photoItem
    }

    /// A real, encodable transparent image keeps skipped slots compatible with
    /// existing board persistence and exports. Placeholder metadata distinguishes
    /// empty slots from user images without inspecting or encoding their pixels.
    static func blankCard(title: String = "") -> PhotoItem {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1), format: format).image { _ in }
        let card = PhotoItem(image: image, title: title)
        card.isPlaceholder = title.isEmpty
        card.storedHasPhoto = false
        return card
    }
    
    // MARK: - Codable
    
    private enum CoderKeys: String, CodingKey {
        case imageMetadata, localizedTitle, translations, imageOverrides, id, imageFileName, audioFileName, asset, assetId, title, fitzgeraldKey, symbolSource, isPlaceholder, hasPhoto
    }
    
    public static var imageFilePrefix: String = "PhotoItem"
    
    private static func makeImageFileName(id: UUID) -> String {
        return "\(imageFilePrefix)-\(id.uuidString).png"
    }
    
    public static func isPhotoItem(at fileURL: URL) -> Bool {
        let pathExtension = fileURL.pathExtension.lowercased()
        if  pathExtension != "png" && pathExtension != "jpg" {
            return false
        }
        if !fileURL.lastPathComponent.starts(with: imageFilePrefix) {
            return false
        }
        return true
    }
    
    
    // Used for persistent storing of products to disk.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CoderKeys.self)
        try container.encode(itemID, forKey: .id)
        //try container.encode(asset, forKey: .asset)
        try container.encode(baseAssetId, forKey: .assetId)
        try container.encode(localizedTitle, forKey: .localizedTitle)
        if encoder.userInfo[.boardStringTables] == nil {
            try container.encode(localizedTitle?.values, forKey: .translations)
        }
        if encoder.userInfo[.boardStringTables] == nil {
            try container.encode(localizedTitle?.values[localizedTitle?.sourceLanguage ?? ""] ?? title, forKey: .title)
        }
        try container.encode(imageOverrides, forKey: .imageOverrides)
        try container.encode(fitzgeraldKey, forKey: .fitzgeraldKey)
        try container.encodeIfPresent(baseSymbolSource, forKey: .symbolSource)
        try container.encode(isPlaceholder, forKey: .isPlaceholder)
        try container.encodeIfPresent(storedHasPhoto, forKey: .hasPhoto)
        try container.encode(imageMetadata, forKey: .imageMetadata)
        
        //Save the image to external storage.
        // Loaded boards may use descriptive filenames. Keep that reference when
        // the image is unchanged, since needsSave is false and no file is written.
        if imageFileName == nil {
            imageFileName = PhotoItem.makeImageFileName(id: itemID)
        }
        //try ImageEncoder.save(image: image, fileName: fileName)
        
        guard let baseURL = encoder.userInfo[.baseURL] as? URL else {
            let message = "JSON encoder userInfo does not contain base URL"
            logger.logError(.repo, message)
            throw PhotoItemError(message: message)
        }
        
        try container.encode(imageFileName, forKey: .imageFileName)
        
        try container.encode(audioFileName, forKey: .audioFileName)
        
        // Copy every referenced resource when exporting/saving into another directory.
        for path in [imageFileName, audioFileName].compactMap({ $0 }) + Array(imageOverrides.values) {
            let destination = baseURL.appendingPathComponent(path)
            if let source = resourceDirectory?.appendingPathComponent(path),
               source != destination, FileManager.default.fileExists(atPath: source.path),
               !FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
                try FileManager.default.copyItem(at: source, to: destination)
            }
        }
        for (language, image) in pendingImages {
            guard let path = imageOverrides[language] else { continue }
            let destination = baseURL.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
            try ImageEncoder.save(image: image, to: destination, format: .png)
        }
        if needsSave && pendingImages.isEmpty {
            let imageURL = baseURL.appendingPathComponent(imageFileName!)
            if let preparedPNGData {
                try preparedPNGData.write(to: imageURL, options: .atomic)
                self.preparedPNGData = nil
            } else {
                try ImageEncoder.save(image: image, to: imageURL, format: .png)
            }
            self.imageURL = imageURL
        }
        pendingImages.removeAll()
        needsSave = false
        resourceDirectory = baseURL
        imageURL = imageFileName.map { baseURL.appendingPathComponent($0) }
        audioURL = audioFileName.map { baseURL.appendingPathComponent($0) }
    }
    
    /// Keep existing card/sentence references valid after moving their owning board.
    func relocateResources(to directory: URL) {
        resourceDirectory = directory
        imageURL = imageFileName.map { directory.appendingPathComponent($0) }
        audioURL = audioFileName.map { directory.appendingPathComponent($0) }
    }

    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CoderKeys.self)
        itemID = try values.decode(UUID.self, forKey: .id)
        //image = try values.decode(UIImage.self, forKey: .image)
        //asset = try values.decode(PHAsset.self, forKey: .asset)
        if let assetId = try? values.decode(String.self, forKey: .assetId) {
            self.baseAssetId = assetId
            let authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
            if authorization == .authorized || authorization == .limited {
                self.asset = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil).firstObject
            }
        }
        title = try? values.decode(String.self, forKey: .title)
        localizedTitle = try values.decodeIfPresent(BoardText.self, forKey: .localizedTitle)
            ?? BoardText(key: itemID.uuidString, sourceLanguage: BoardLanguage.unassigned, text: title)
        if let tables = decoder.userInfo[.boardStringTables] as? [String: [String: String]] {
            localizedTitle?.load(tables: tables)
        } else if let translations = try values.decodeIfPresent([String: String].self, forKey: .translations) {
            localizedTitle?.values = translations
        }
        imageOverrides = try values.decodeIfPresent([String: String].self, forKey: .imageOverrides) ?? [:]
        fitzgeraldKey = try values.decode(FitzgeraldKey.self, forKey: .fitzgeraldKey)
        baseSymbolSource = try values.decodeIfPresent(SymbolSource.self, forKey: .symbolSource)
        imageMetadata = try values.decodeIfPresent([String: ImageMetadata].self, forKey: .imageMetadata) ?? [:]
        isPlaceholder = try values.decodeIfPresent(Bool.self, forKey: .isPlaceholder) ?? false
        storedHasPhoto = try values.decodeIfPresent(Bool.self, forKey: .hasPhoto)
        
        imageFileName = try values.decode(String.self, forKey: .imageFileName)
        guard let imageFileName = self.imageFileName else {
            let message = "JSON does not contain a filename"
            logger.logError(.repo, message)
            throw PhotoItemError(message: message)
        }
        
        audioFileName = try values.decodeIfPresent(String.self, forKey: .audioFileName)
        
        guard let baseURL = decoder.userInfo[.baseURL] as? URL else {
            let message = "JSON decoder userInfo does not contain base URL"
            logger.logError(.repo, message)
            throw PhotoItemError(message: message)
        }
        
        var imageURL = baseURL.appendingPathComponent(imageFileName)
        // Older saves replaced descriptive starter-image names with the generated
        // name without renaming the file. Recover only an unambiguous UUID match.
        if !FileManager.default.fileExists(atPath: imageURL.path),
           imageFileName == Self.makeImageFileName(id: itemID) {
            let matches = try FileManager.default.contentsOfDirectory(
                at: baseURL, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.hasSuffix(" - " + imageFileName) }
            if matches.count == 1 {
                imageURL = matches[0]
                self.imageFileName = imageURL.lastPathComponent
            }
        }
        guard FileManager.default.fileExists(atPath: imageURL.path) else {
            throw PhotoItemError(message: "Image \(imageFileName) does not exist at \(baseURL)")
        }
        self.imageURL = imageURL
        self.resourceDirectory = baseURL
        assignedToBoard = true
        selectLanguage(decoder.userInfo[.boardEditingLanguage] as? String ?? BoardLanguage.appLanguage)

        if let audioFileName = audioFileName {
            let audioURL = baseURL.appendingPathComponent(audioFileName)
            guard FileManager.default.fileExists(atPath: audioURL.path) else {
                throw PhotoItemError(message: "Audio \(audioFileName) does not exist at \(baseURL)")
            }
            self.audioURL = audioURL
        }
        

        self.needsSave = false
        
    }
    
    
    func save(to fileURL: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.userInfo[.baseURL] = fileURL.deletingLastPathComponent()
        
        do {
            let encoded = try encoder.encode(self)
            try encoded.write(to: fileURL)
        } catch {
            let message = "Could not save PhotoItem to \(fileURL.path)"
            logger.logError(.repo, message, error)
            throw PhotoItemError(message: message)
        }
    }
    
    
    static func load(from fileURL: URL) throws -> Self {
        let codedData = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.userInfo[.baseURL] = fileURL.deletingLastPathComponent()
        do {
            let decoded = try decoder.decode(Self.self, from: codedData)
            return decoded
        }
        catch{
            let message = "Could not load PhotoItem from \(fileURL.path)"
            throw PhotoItemError(message: message)
        }
    }
    
}
 
extension PhotoItem : ImagePickerItem {
    
    var id: String { itemID.uuidString }
    var debugInfo: [String]? { return nil }

    func loadImage(size: CGSize) -> UIImage {
        //print("loadImage: id = \(itemID)")
        return image
    }
    
}
