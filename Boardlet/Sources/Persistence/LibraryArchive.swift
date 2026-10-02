import Foundation

struct LibraryArchive: Codable {
    let format: String
    let library: Library
    let media: [String: Data]

    @MainActor static func export(store: BoardStore) throws -> Data {
        var files: [String: Data] = [:]
        for board in store.library.boards {
            for name in board.cards.flatMap({ [$0.image, $0.originalImage, $0.recording] }) + [board.cover] {
                if let name, files[name] == nil, let url = store.assetURL(name) { files[name] = try Data(contentsOf: url) }
            }
        }
        return try JSONEncoder().encode(LibraryArchive(format: "boardlet-archive-1", library: store.library, media: files))
    }
    func validatedImport(storage: any LibraryStorage) async throws -> Library {
        guard format == "boardlet-archive-1" else { throw StorageError.unsupportedVersion }
        let valid = try library.validated()
        for board in valid.boards {
            for name in board.cards.flatMap({ [$0.image, $0.originalImage, $0.recording] }) + [board.cover] {
                if let name {
                    guard let data = media[name] else { throw StorageError.missingAsset(name) }
                    let actual = try await storage.storeAsset(data, extension: URL(fileURLWithPath: name).pathExtension)
                    guard actual == name else { throw StorageError.invalidData }
                }
            }
        }
        return valid
    }
}
