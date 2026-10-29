// Compile with App/Import/Metafile/*.swift on macOS.
// Read-only inspection of a local SPS; output is deliberately outside the repository.
import AppKit
import SQLite3

@main
enum MetafileInspection {
    @MainActor static func main() throws {
        let input = CommandLine.arguments[1], output = URL(fileURLWithPath: CommandLine.arguments[2])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        var db: OpaquePointer?
        guard sqlite3_open_v2(input, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else { fatalError("Cannot open input") }
        defer { sqlite3_close(db) }
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, "SELECT Id, Data FROM PageSetData ORDER BY Id", -1, &statement, nil) == SQLITE_OK else { fatalError("Missing assets") }
        defer { sqlite3_finalize(statement) }
        var previews: [(String, Data, Int)] = [], failures: [String: String] = [:], counts: [String: Int] = [:]
        while sqlite3_step(statement) == SQLITE_ROW {
            let id = String(sqlite3_column_int(statement, 0)), size = Int(sqlite3_column_bytes(statement, 1))
            let data = Data(bytes: sqlite3_column_blob(statement, 1)!, count: size)
            guard MetafileRenderer.isMetafile(data) else { continue }
            let kind = data.starts(with: [0xd7, 0xcd, 0xc6, 0x9a]) ? "WMF" : "EMF"
            do {
                let png = try MetafileRenderer.png(data)
                try png.write(to: output.appendingPathComponent("\(id).png"))
                previews.append((id, png, size)); counts[kind, default: 0] += 1
            } catch { failures[id] = String(describing: error) }
        }
        let summary: [String: Any] = ["rendered": counts, "failures": failures, "pngBytes": previews.reduce(0) { $0 + $1.1.count }]
        try JSONSerialization.data(withJSONObject: summary, options: [.prettyPrinted, .sortedKeys]).write(to: output.appendingPathComponent("summary.json"))
        print(String(data: try JSONSerialization.data(withJSONObject: summary, options: [.sortedKeys]), encoding: .utf8)!)
        let emfIDs: Set<String> = ["2713", "2714", "3216", "3510", "3579", "4235", "4236", "4238", "3825"]
        let chosen = previews.filter { emfIDs.contains($0.0) } + Array(previews.sorted { $0.2 > $1.2 }.prefix(15)) + previews.enumerated().filter { $0.offset % 113 == 0 }.map(\.element)
        let columns = 8, tile = 150, rows = (chosen.count + columns - 1) / columns
        let sheet = NSImage(size: NSSize(width: columns * tile, height: rows * tile))
        sheet.lockFocus()
        NSColor.white.setFill(); NSRect(x: 0, y: 0, width: columns * tile, height: rows * tile).fill()
        for (i, item) in chosen.enumerated() {
            let x = (i % columns) * tile, y = (rows - 1 - i / columns) * tile
            // Neutral checkerboard reveals transparent white navigation artwork as well.
            for row in 0..<8 {
                for col in 0..<8 {
                    NSColor(white: (row + col) % 2 == 0 ? 0.86 : 0.95, alpha: 1).setFill()
                    NSRect(x: x + 11 + col * 16, y: y + 23 + row * 16, width: 16, height: 16).fill()
                }
            }
            if let image = NSImage(data: item.1) {
                let ratio = min(128 / image.size.width, 123 / image.size.height)
                let size = NSSize(width: image.size.width * ratio, height: image.size.height * ratio)
                image.draw(in: NSRect(x: CGFloat(x) + (150 - size.width) / 2, y: CGFloat(y) + 23, width: size.width, height: size.height))
            }
            ("Asset \(item.0)" as NSString).draw(at: NSPoint(x: x + 8, y: y + 4), withAttributes: [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.black])
        }
        sheet.unlockFocus()
        let bitmap = NSBitmapImageRep(data: sheet.tiffRepresentation!)!
        try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("contact-sheet.png"))
    }
}
