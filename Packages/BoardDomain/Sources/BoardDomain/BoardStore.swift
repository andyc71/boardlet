import Foundation

public enum BoardStorePhase: Equatable, Sendable {
    case recovered
    case stagingCreated
    case assetWritten(String)
    case indexWritten
    case readyToCommit
    case previousVersionBackedUp
    case committed
}

public enum BoardStoreError: Error, Equatable, LocalizedError, Sendable {
    case destinationIsNotAFileURL
    case invalidFileName(String)
    case missingIndex(URL)
    case missingAsset(String)

    public var errorDescription: String? {
        switch self {
        case .destinationIsNotAFileURL:
            "The board destination must be a file URL."
        case .invalidFileName(let name):
            "The board contains an unsafe asset filename: \(name)"
        case .missingIndex(let url):
            "The board index is missing at \(url.path)."
        case .missingAsset(let name):
            "The board asset is missing: \(name)"
        }
    }
}

public typealias BoardStoreFaultInjector = @Sendable (BoardStorePhase) throws -> Void

/// Serializes board saves and performs recovery before every read or write.
public actor BoardStore {
    public let indexFileName: String
    private let faultInjector: BoardStoreFaultInjector?

    public init(
        indexFileName: String = "index.json",
        faultInjector: BoardStoreFaultInjector? = nil
    ) {
        self.indexFileName = indexFileName
        self.faultInjector = faultInjector
    }

    public func save(_ archive: BoardArchive, to destination: URL) throws {
        try AtomicBoardPersistence.save(
            archive,
            to: destination,
            indexFileName: indexFileName,
            faultInjector: faultInjector
        )
    }

    public func load(from destination: URL) throws -> BoardArchive {
        try AtomicBoardPersistence.load(
            from: destination,
            indexFileName: indexFileName
        )
    }

    public func recover(at destination: URL) throws {
        try AtomicBoardPersistence.recover(at: destination)
    }
}

/// The synchronous implementation is exposed for legacy callers while they migrate
/// to the actor-based `BoardStore` API.
public enum AtomicBoardPersistence {
    private static let commitMarkerName = ".commit-ready"

    public static func save(
        _ archive: BoardArchive,
        to destination: URL,
        indexFileName: String = "index.json",
        faultInjector: BoardStoreFaultInjector? = nil
    ) throws {
        guard destination.isFileURL else {
            throw BoardStoreError.destinationIsNotAFileURL
        }
        try validate(fileName: indexFileName)
        for fileName in archive.assets.keys {
            try validate(fileName: fileName)
        }

        let fileManager = FileManager.default
        let paths = transactionPaths(for: destination)
        try recover(at: destination)
        try faultInjector?(.recovered)

        try fileManager.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try removeIfPresent(paths.staging, fileManager: fileManager)
        try fileManager.createDirectory(
            at: paths.staging,
            withIntermediateDirectories: false
        )
        try faultInjector?(.stagingCreated)

        do {
            for fileName in archive.assets.keys.sorted() {
                guard let data = archive.assets[fileName] else {
                    throw BoardStoreError.missingAsset(fileName)
                }
                let fileURL = paths.staging.appendingPathComponent(fileName)
                try durableWrite(data, to: fileURL)
                try faultInjector?(.assetWritten(fileName))
            }

            let indexURL = paths.staging.appendingPathComponent(indexFileName)
            try durableWrite(archive.index, to: indexURL)
            try faultInjector?(.indexWritten)

            try durableWrite(Data(), to: paths.staging.appendingPathComponent(commitMarkerName))
            try verify(archive, in: paths.staging, indexFileName: indexFileName)
            try faultInjector?(.readyToCommit)

            try removeIfPresent(paths.backup, fileManager: fileManager)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.moveItem(at: destination, to: paths.backup)
                try faultInjector?(.previousVersionBackedUp)
            }

            try fileManager.moveItem(at: paths.staging, to: destination)
            try faultInjector?(.committed)
            try removeIfPresent(paths.backup, fileManager: fileManager)
            try removeIfPresent(destination.appendingPathComponent(commitMarkerName), fileManager: fileManager)
        } catch {
            // Restore the last complete version immediately when possible. A later
            // load also calls recover, covering process termination between renames.
            try? recover(at: destination)
            throw error
        }
    }

    public static func load(
        from destination: URL,
        indexFileName: String = "index.json"
    ) throws -> BoardArchive {
        try recover(at: destination)
        let indexURL = destination.appendingPathComponent(indexFileName)
        guard FileManager.default.fileExists(atPath: indexURL.path) else {
            throw BoardStoreError.missingIndex(indexURL)
        }

        let index = try Data(contentsOf: indexURL)
        let fileURLs = try FileManager.default.contentsOfDirectory(
            at: destination,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        )
        var assets: [String: Data] = [:]
        for fileURL in fileURLs where fileURL.lastPathComponent != indexFileName {
            let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
            if values.isRegularFile == true {
                assets[fileURL.lastPathComponent] = try Data(contentsOf: fileURL)
            }
        }
        return BoardArchive(index: index, assets: assets)
    }

    public static func recover(at destination: URL) throws {
        guard destination.isFileURL else {
            throw BoardStoreError.destinationIsNotAFileURL
        }
        let fileManager = FileManager.default
        let paths = transactionPaths(for: destination)
        let destinationExists = fileManager.fileExists(atPath: destination.path)
        let backupExists = fileManager.fileExists(atPath: paths.backup.path)
        let stagingExists = fileManager.fileExists(atPath: paths.staging.path)

        if destinationExists {
            try removeIfPresent(paths.backup, fileManager: fileManager)
            try removeIfPresent(paths.staging, fileManager: fileManager)
            try removeIfPresent(destination.appendingPathComponent(commitMarkerName), fileManager: fileManager)
            return
        }

        if backupExists {
            try fileManager.moveItem(at: paths.backup, to: destination)
            try removeIfPresent(paths.staging, fileManager: fileManager)
            return
        }

        if stagingExists {
            let marker = paths.staging.appendingPathComponent(commitMarkerName)
            if fileManager.fileExists(atPath: marker.path) {
                try fileManager.moveItem(at: paths.staging, to: destination)
                try removeIfPresent(destination.appendingPathComponent(commitMarkerName), fileManager: fileManager)
            } else {
                try fileManager.removeItem(at: paths.staging)
            }
        }
    }

    private static func verify(
        _ archive: BoardArchive,
        in directory: URL,
        indexFileName: String
    ) throws {
        let indexURL = directory.appendingPathComponent(indexFileName)
        guard try Data(contentsOf: indexURL) == archive.index else {
            throw BoardStoreError.missingIndex(indexURL)
        }
        for (fileName, expectedData) in archive.assets {
            let assetURL = directory.appendingPathComponent(fileName)
            guard FileManager.default.fileExists(atPath: assetURL.path),
                  try Data(contentsOf: assetURL) == expectedData else {
                throw BoardStoreError.missingAsset(fileName)
            }
        }
    }

    private static func validate(fileName: String) throws {
        let url = URL(fileURLWithPath: fileName)
        guard !fileName.isEmpty,
              fileName != ".",
              fileName != "..",
              !fileName.contains("/"),
              !fileName.contains("\\"),
              url.lastPathComponent == fileName else {
            throw BoardStoreError.invalidFileName(fileName)
        }
    }

    private static func durableWrite(_ data: Data, to url: URL) throws {
        try data.write(to: url, options: [.atomic])
        let handle = try FileHandle(forWritingTo: url)
        try handle.synchronize()
        try handle.close()
    }

    private static func removeIfPresent(_ url: URL, fileManager: FileManager) throws {
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    private static func transactionPaths(for destination: URL) -> (staging: URL, backup: URL) {
        let parent = destination.deletingLastPathComponent()
        let name = destination.lastPathComponent
        return (
            parent.appendingPathComponent(".\(name).boardlet-staging", isDirectory: true),
            parent.appendingPathComponent(".\(name).boardlet-backup", isDirectory: true)
        )
    }
}
