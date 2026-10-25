import Foundation
import BoardLibrary
import Darwin

@main struct Benchmark {
    static func main() async throws {
        let base = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".build/board-hierarchy-search/benchmark")
        let root = base.appendingPathComponent("topics")
        try FileManager.default.createDirectory(at:root,withIntermediateDirectories:true)
        let count = 1000
        let started = Date()
        for i in 0..<count {
            try autoreleasepool {
            let id = DocumentPaths.provisionalID("board-\(i)")
            let directory = root.appendingPathComponent(id.uuidString)
            try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
            let cards: [[String:Any]] = (0..<100).map { j in
                ["id":DocumentPaths.provisionalID("card-\(i)-\(j)").uuidString,"localizedTitle":["key":"card-\(j)","sourceLanguage":"en","values":["en":"Apple fruit \(i) \(j)","es":"Manzana fruta \(i) \(j)"]],"imageFileName":"images/\(j).png"]
            }
            let json: [String:Any] = ["version":3,"id":id.uuidString,"contentRevision":UUID().uuidString,"topic":["topicName":"Board \(i)","imageFileName":"cover.png"],"photos":["photoItems":cards]]
            try JSONSerialization.data(withJSONObject:json).write(to:directory.appendingPathComponent("index.json"))
        }
        }
        print("fixture: 1000 boards, 100000 cards, 200000 card translations; \(Date().timeIntervalSince(started)) seconds")
        let library = try BoardLibraryStore(root:root,database:base.appendingPathComponent("catalog.sqlite"),language:"en")
        var start = Date(); let snapshot = try await library.reconcile(); print("index seconds=\(Date().timeIntervalSince(start)) boards=\(snapshot.boards.count) diagnostics=\(snapshot.diagnostics)")
        start = Date(); let unchanged = try await library.reconcile(); print("unchanged seconds=\(Date().timeIntervalSince(start)) decoded=\(unchanged.indexedDocuments)")
        for allLanguages in [false, true] {
            for query in ["Apple", "App", "fruit 20", "Manzana", "unlikely"] {
                var timings: [Double] = []
                for _ in 0..<50 { let start = Date(); _ = try await library.search(query,allLanguages:allLanguages); timings.append(Date().timeIntervalSince(start)*1000) }
                timings.sort(); print("query=\(query) all_languages=\(allLanguages) repetitions=50 median_ms=\(timings[25]) p95_ms=\(timings[47]) max_ms=\(timings[49])")
            }
        }
        let scope = snapshot.boards[0].id
        start = Date(); _ = try await library.search("App",scope:scope); print("subtree_ms=\(Date().timeIntervalSince(start)*1000)")
        start = Date(); let page = try await library.search("App",allLanguages:true,offset:40); print("second_page_ms=\(Date().timeIntervalSince(start)*1000) count=\(page.count)")
        // Fresh SQLite connections; OS filesystem caches remain warm.
        var cold: [Double] = []
        for _ in 0..<20 {
            let fresh = try BoardLibraryStore(root:root,database:base.appendingPathComponent("catalog.sqlite"),language:"en")
            let start = Date(); _ = try await fresh.search("App",allLanguages:true)
            cold.append(Date().timeIntervalSince(start)*1000)
        }
        cold.sort(); print("fresh_connection_query repetitions=20 median_ms=\(cold[10]) p95_ms=\(cold[18]) max_ms=\(cold[19])")
        let changedDirectory = try await library.location(scope)
        let changedIndex = changedDirectory.appendingPathComponent("index.json")
        var changed = try JSONSerialization.jsonObject(with:Data(contentsOf:changedIndex)) as! [String:Any]
        changed["contentRevision"] = UUID().uuidString
        try JSONSerialization.data(withJSONObject:changed).write(to:changedIndex,options:.atomic)
        start = Date(); let update = try await library.updateBoard(at:changedDirectory)
        print("incremental_board_ms=\(Date().timeIntervalSince(start)*1000) indexed=\(update.indexedDocuments)")
        var usage = rusage(); getrusage(RUSAGE_SELF,&usage); print("peak_resident_bytes=\(usage.ru_maxrss)")
    }
}
