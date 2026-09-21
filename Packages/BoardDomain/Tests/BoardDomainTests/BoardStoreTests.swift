import Foundation
import Testing
@testable import BoardDomain

@Suite("Atomic board persistence")
struct BoardStoreTests {
    @Test("Round trips an archive and removes obsolete assets after commit")
    func roundTripAndCleanup() async throws {
        try await withTemporaryDirectory { directory in
            let destination = directory.appendingPathComponent("Board", isDirectory: true)
            let store = BoardStore()
            try await store.save(
                BoardArchive(index: Data("v1".utf8), assets: ["old.png": Data([1])]),
                to: destination
            )
            try await store.save(
                BoardArchive(index: Data("v2".utf8), assets: ["new.png": Data([2])]),
                to: destination
            )

            let loaded = try await store.load(from: destination)
            #expect(loaded.index == Data("v2".utf8))
            #expect(loaded.assets == ["new.png": Data([2])])
        }
    }

    @Test("Creates a missing storage hierarchy on first save")
    func createsMissingStorageHierarchy() throws {
        try withTemporaryDirectory { directory in
            let destination = directory
                .appendingPathComponent("topics", isDirectory: true)
                .appendingPathComponent("First Board", isDirectory: true)
            let archive = BoardArchive(index: Data("first".utf8), assets: [:])

            try AtomicBoardPersistence.save(archive, to: destination)

            #expect(try AtomicBoardPersistence.load(from: destination) == archive)
        }
    }

    @Test("Every injected pre-commit failure preserves the previous complete board", arguments: [
        BoardStorePhase.recovered,
        .stagingCreated,
        .assetWritten("new.png"),
        .indexWritten,
        .readyToCommit,
        .previousVersionBackedUp
    ])
    func injectedFailurePreservesPreviousBoard(phase: BoardStorePhase) async throws {
        try await withTemporaryDirectory { directory in
            let destination = directory.appendingPathComponent("Board", isDirectory: true)
            let original = BoardArchive(index: Data("original".utf8), assets: ["old.png": Data([1])])
            try AtomicBoardPersistence.save(original, to: destination)

            let store = BoardStore { reachedPhase in
                if reachedPhase == phase {
                    throw InjectedFailure()
                }
            }

            await #expect(throws: InjectedFailure.self) {
                try await store.save(
                    BoardArchive(index: Data("replacement".utf8), assets: ["new.png": Data([2])]),
                    to: destination
                )
            }

            let recovered = try AtomicBoardPersistence.load(from: destination)
            #expect(recovered == original)
        }
    }

    @Test("Recovery restores a backup left by an interrupted directory swap")
    func interruptedSwapRecovery() throws {
        try withTemporaryDirectory { directory in
            let destination = directory.appendingPathComponent("Board", isDirectory: true)
            let original = BoardArchive(index: Data("original".utf8), assets: ["old.png": Data([1])])
            try AtomicBoardPersistence.save(original, to: destination)

            let backup = directory.appendingPathComponent(".Board.boardlet-backup", isDirectory: true)
            try FileManager.default.moveItem(at: destination, to: backup)

            try AtomicBoardPersistence.recover(at: destination)

            #expect(try AtomicBoardPersistence.load(from: destination) == original)
        }
    }

    @Test("Rejects asset paths that could escape the board directory")
    func rejectsUnsafeAssetNames() throws {
        try withTemporaryDirectory { directory in
            let destination = directory.appendingPathComponent("Board", isDirectory: true)
            #expect(throws: BoardStoreError.invalidFileName("../secret")) {
                try AtomicBoardPersistence.save(
                    BoardArchive(index: Data(), assets: ["../secret": Data()]),
                    to: destination
                )
            }
        }
    }
}

private struct InjectedFailure: Error {}

private func withTemporaryDirectory<T>(
    _ operation: (URL) async throws -> T
) async throws -> T {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    return try await operation(directory)
}

private func withTemporaryDirectory<T>(
    _ operation: (URL) throws -> T
) throws -> T {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    return try operation(directory)
}
