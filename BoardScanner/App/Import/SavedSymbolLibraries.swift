import CryptoKit
import Foundation

/// Private copies keep future imports independent of Files permissions and source-file moves.
struct SavedSymbolLibraries: Sendable {
    let root: URL

    @concurrent func rememberAndSupplement(_ original: SnapPageSet, from source: URL) async throws -> SnapPageSet {
        let accessible = source.startAccessingSecurityScopedResource()
        defer { if accessible { source.stopAccessingSecurityScopedResource() } }
        guard (try source.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) <= 1_000_000_000 else {
            throw LibraryError.tooLarge
        }
        let fm = FileManager.default
        try fm.createDirectory(at: root, withIntermediateDirectories: true)
        let staging = root.appendingPathComponent(UUID().uuidString + ".pending")
        defer { try? fm.removeItem(at: staging) }
        try Task.checkCancellation()
        try fm.copyItem(at: source, to: staging)
        // Validate and render the private snapshot before making it available to later imports.
        let result = try await SnapSymbolLibrary.supplement(original, from: staging)
        let handle = try FileHandle(forReadingFrom: staging)
        defer { try? handle.close() }
        var hash = SHA256()
        while let chunk = try handle.read(upToCount: 1_048_576), !chunk.isEmpty {
            try Task.checkCancellation()
            hash.update(data: chunk)
        }
        let filename = hash.finalize().map { String(format: "%02x", $0) }.joined() + ".db3"
        let destination = root.appendingPathComponent(filename)
        try Task.checkCancellation()
        if !fm.fileExists(atPath: destination.path) { try fm.moveItem(at: staging, to: destination) }
        return result
    }

    @concurrent func supplement(_ original: SnapPageSet) async throws -> (pageSet: SnapPageSet, failedLibraries: Int) {
        guard FileManager.default.fileExists(atPath: root.path) else { return (original, 0) }
        let files = try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "db3" }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        var result = original
        var failures = 0
        for file in files {
            try Task.checkCancellation()
            guard result.unavailableImageCount > 0 else { break }
            do { result = try await SnapSymbolLibrary.supplement(result, from: file) }
            catch is CancellationError { throw CancellationError() }
            catch { failures += 1 }
        }
        try Task.checkCancellation()
        return (result, failures)
    }
}
