import Foundation
import CryptoKit
import UIKit
import AVFAudio

struct LegacyImportResult: Sendable {
    var boards: [Board]
    var skipped: Int
}

/// Reads only. Never invokes the legacy Codable implementations, which write files.
struct LegacyImporter {
    let storage: any LibraryStorage

    func importFolder(_ folder: URL, existing: [Board]) async throws -> LegacyImportResult {
        let fm = FileManager.default
        let root = folder.standardizedFileURL.resolvingSymlinksInPath()
        var indices: [URL] = []
        if fm.fileExists(atPath: root.appendingPathComponent("index.json").path) {
            indices = [root.appendingPathComponent("index.json")]
        } else { indices = Self.findIndices(root) }
        guard !indices.isEmpty else { throw StorageError.invalidData }
        var boards: [Board] = []
        var seen = Set(existing.compactMap(\.legacySource))
        var skipped = 0
        for index in indices.sorted(by: { $0.path < $1.path }) {
            try Task.checkCancellation()
            let data = try Data(contentsOf: index)
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let version = json["version"] as? Int, version == 1,
                  let topic = json["topic"] as? [String: Any], let name = topic["topicName"] as? String,
                  let photos = json["photos"] as? [String: Any] else { throw StorageError.invalidData }
            let source = topic["topicDirectoryName"] as? String ?? SHA256.hash(data: data).description
            if seen.contains(source) { skipped += 1; continue }
            let directory = index.deletingLastPathComponent()
            var board = Board(name: name)
            board.legacySource = source
            board.legacyMetadata = data
            if let paper = json["pageSize"] as? String, let known = Paper(rawValue: paper) { board.print.paper = known }
            else { throw StorageError.invalidData }
            board.print.landscape = json["orientation"] as? String == "landscape"
            if let layout = json["layout"] as? [String: Any], let width = layout["width"] as? Int, let height = layout["height"] as? Int {
                board.print.columns = width; board.print.rows = height
                board.print.fixedCardAspectRatio = layout["fixedCardAspectRatio"] as? Double
                board.communication.columns = min(6, max(1, width))
                board.communication.rows = min(8, max(1, height))
            } else { throw StorageError.invalidData }
            if let formatting = json["formatting"] as? [String: Any] { board.print = Self.formatting(formatting, settings: board.print) }
            if let cover = topic["imageFileName"] as? String {
                board.cover = try await asset(cover, in: directory, image: true)
            }
            board.coverAttribution = Self.attribution(json["topicImageSymbolSource"])
            let items = photos["photoItems"] as? [[String: Any]]
            if photos["photoItems"] != nil && !(photos["photoItems"] is NSNull) && items == nil { throw StorageError.invalidData }
            for item in items ?? [] {
                guard let image = item["imageFileName"] as? String else { throw StorageError.invalidData }
                var card = Card(label: item["title"] as? String ?? "")
                if let id = item["id"] as? String, let uuid = UUID(uuidString: id) { card.id = uuid }
                card.image = try await asset(image, in: directory, image: true)
                card.originalImage = card.image
                if let audio = item["audioFileName"] as? String {
                    card.recording = try await asset(audio, in: directory, image: false)
                    card.voice = .recording
                }
                card.category = item["fitzgeraldKey"] as? String ?? "none"
                card.attribution = Self.attribution(item["symbolSource"])
                card.originalAttribution = card.attribution
                board.cards.append(card)
            }
            _ = try Library(boards: [board]).validated()
            boards.append(board); seen.insert(source)
        }
        return LegacyImportResult(boards: boards.sorted { left, right in
            let defaults = ["New Board", "Nuevo Tablero"]
            if defaults.contains(left.name) != defaults.contains(right.name) { return defaults.contains(left.name) }
            return left.name < right.name
        }, skipped: skipped)
    }

    static func containsBoards(_ root: URL) -> Bool { !findIndices(root).isEmpty }

    private static func findIndices(_ root: URL) -> [URL] {
        guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else { return [] }
        return enumerator.compactMap { $0 as? URL }.filter { $0.lastPathComponent == "index.json" }
    }

    private func asset(_ name: String, in directory: URL, image: Bool) async throws -> String {
        try AssetPath.validate(name)
        let url = directory.appendingPathComponent(name).resolvingSymlinksInPath()
        guard url.deletingLastPathComponent() == directory.resolvingSymlinksInPath(),
              let data = try? Data(contentsOf: url), !data.isEmpty else { throw StorageError.missingAsset(name) }
        if image, UIImage(data: data) == nil { throw StorageError.missingAsset(name) }
        if !image { do { _ = try AVAudioFile(forReading: url) } catch { throw StorageError.missingAsset(name) } }
        return try await storage.storeAsset(data, extension: url.pathExtension)
    }

    private static func attribution(_ object: Any?) -> Attribution? {
        guard let value = object as? [String: Any], let provider = value["provider"] as? String else { return nil }
        if provider == "arasaac", let id = value["symbolID"] as? Int {
            var result = Attribution.arasaac(id); result.modified = value["isModified"] as? Bool ?? false; return result
        }
        return Attribution(provider: provider, credit: provider)
    }

    private static func formatting(_ f: [String: Any], settings: PrintSettings) -> PrintSettings {
        var s = settings
        s.showTitle = f["pageTitleVisible"] as? Bool ?? false
        s.titleColor = f["pageTitleColor"] as? String ?? s.titleColor
        s.titleBold = f["pageTitleBoldFont"] as? Bool ?? false
        s.titleFraction = f["pageTitleHeightPercentage"] as? Double ?? 0.15
        s.labelColor = f["labelColor"] as? String ?? s.labelColor
        s.labelBold = f["labelBoldFont"] as? Bool ?? false
        s.labelFraction = f["labelHeightPercentage"] as? Double ?? 0.15
        s.labelsAbove = f["labelPosition"] as? String == "top"
        s.background = f["cellFillColor"] as? String ?? s.background
        s.marginFraction = f["marginPercentage"] as? Double ?? 0.05
        s.borderColor = f["gridlineColor"] as? String ?? s.borderColor
        s.borderWidth = f["gridlinesThick"] as? Bool == true ? 4 : 1
        s.categoryBorders = f["fitzgeraldBordersEnabled"] as? Bool ?? false
        s.categoryBorderWidth = f["fitzgeraldBordersThick"] as? Bool == true ? 4 : 1
        return s
    }
}

/// This policy is dormant for development IDs and never crosses app sandboxes.
enum ProductionMigration {
    static func source(bundleID: String?, documents: URL, libraryExists: Bool) -> URL? {
        guard !libraryExists, ["com.brightblue.EasyPECS", "com.brightblue.EasyPECSPlus"].contains(bundleID ?? "") else { return nil }
        return documents
    }
}
