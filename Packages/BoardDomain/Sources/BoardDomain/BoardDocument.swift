import Foundation

public struct BoardID: RawRepresentable, Codable, Hashable, Sendable, Identifiable {
    public let rawValue: UUID

    public var id: UUID { rawValue }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }

    public init() {
        self.init(rawValue: UUID())
    }
}

public struct BoardItemID: RawRepresentable, Codable, Hashable, Sendable, Identifiable {
    public let rawValue: UUID

    public var id: UUID { rawValue }

    public init(rawValue: UUID) {
        self.rawValue = rawValue
    }

    public init() {
        self.init(rawValue: UUID())
    }
}

public struct BoardAssetReference: Codable, Equatable, Hashable, Sendable {
    public enum MediaType: String, Codable, Sendable {
        case image
        case audio
    }

    public let fileName: String
    public let mediaType: MediaType

    public init(fileName: String, mediaType: MediaType) {
        self.fileName = fileName
        self.mediaType = mediaType
    }
}

public struct BoardItem: Codable, Equatable, Hashable, Identifiable, Sendable {
    public let id: BoardItemID
    public var title: String?
    public var image: BoardAssetReference
    public var audio: BoardAssetReference?
    public var sourceAssetID: String?
    public var semanticCategory: String?

    public init(
        id: BoardItemID = BoardItemID(),
        title: String? = nil,
        image: BoardAssetReference,
        audio: BoardAssetReference? = nil,
        sourceAssetID: String? = nil,
        semanticCategory: String? = nil
    ) {
        self.id = id
        self.title = title
        self.image = image
        self.audio = audio
        self.sourceAssetID = sourceAssetID
        self.semanticCategory = semanticCategory
    }
}

/// A UIKit-free, immutable value used at persistence and rendering boundaries.
public struct BoardDocument: Codable, Equatable, Sendable, Identifiable {
    public static let currentSchemaVersion = 1

    public let id: BoardID
    public var schemaVersion: Int
    public var title: String
    public var topicImage: BoardAssetReference
    public var items: [BoardItem]
    public var pageSize: String
    public var orientation: String
    public var columns: Int
    public var rows: Int

    public init(
        id: BoardID = BoardID(),
        schemaVersion: Int = BoardDocument.currentSchemaVersion,
        title: String,
        topicImage: BoardAssetReference,
        items: [BoardItem],
        pageSize: String,
        orientation: String,
        columns: Int,
        rows: Int
    ) {
        self.id = id
        self.schemaVersion = schemaVersion
        self.title = title
        self.topicImage = topicImage
        self.items = items
        self.pageSize = pageSize
        self.orientation = orientation
        self.columns = columns
        self.rows = rows
    }
}

/// The complete, immutable input for an atomic save.
public struct BoardArchive: Equatable, Sendable {
    public var index: Data
    public var assets: [String: Data]

    public init(index: Data, assets: [String: Data]) {
        self.index = index
        self.assets = assets
    }
}
