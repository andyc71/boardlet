import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Extract sprite cells without flattening their generated alpha channel.
let root = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
let fm = FileManager.default
let expansion = CommandLine.arguments.contains("--expansion")
let rowCount = expansion ? 4 : 3
let columnCount = 3
let artworkDirectory = expansion ? "artwork/expansion" : "artwork"
let symbolPrefix = expansion ? "expansion-" : ""
let sheets = try fm.contentsOfDirectory(at: root.appendingPathComponent(artworkDirectory), includingPropertiesForKeys: nil).filter { $0.pathExtension == "png" }.sorted { $0.path < $1.path }
var report: [[String: Any]] = []
func boundary(_ counts: [Int], near fraction: Double) -> Int? {
    let target = Int(Double(counts.count) * fraction)
    let radius = counts.count / 12
    let range = max(1, target-radius)...min(counts.count-2, target+radius)
    let minimum = range.map { counts[$0] }.min()!
    // Choose the centre of the widest empty gutter, nearest the nominal grid line.
    var runs: [(Int,Int)] = []; var start: Int?
    for x in range {
        if counts[x] == minimum { if start == nil { start = x } }
        else if let s = start { runs.append((s,x-1)); start = nil }
    }
    if let s = start { runs.append((s,range.upperBound)) }
    let best = runs.sorted {
        if $0.1-$0.0 != $1.1-$1.0 { return $0.1-$0.0 > $1.1-$1.0 }
        return abs(($0.0+$0.1)/2-target) < abs(($1.0+$1.1)/2-target)
    }.first!
    guard minimum == 0 else { return nil }
    return (best.0+best.1)/2
}
for sheet in sheets {
    FileHandle.standardError.write(Data("Checking \(sheet.lastPathComponent)\n".utf8))
    let source = CGImageSourceCreateWithURL(sheet as CFURL, nil)!
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)!
    let w = image.width, h = image.height
    var pixels = [UInt8](repeating: 0, count: w*h*4)
    pixels.withUnsafeMutableBytes { bytes in
        let context = CGContext(data: bytes.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w*4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)!
        context.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
    }
    func alpha(_ x: Int, _ y: Int) -> UInt8 { pixels[(y*w+x)*4+3] }
    func divisions(_ counts: [Int], parts: Int) -> [Int]? {
        var result = [0]
        for index in 1..<parts {
            guard let cut = boundary(counts, near: Double(index) / Double(parts)) else { return nil }
            result.append(cut)
        }
        return result + [counts.count]
    }
    func cells(rowsFirst: Bool) -> [Int: CGRect]? {
        let outerCount = rowsFirst ? h : w
        let innerCount = rowsFirst ? w : h
        var counts = [Int](repeating: 0, count: outerCount)
        for y in 0..<h { for x in 0..<w { if alpha(x,y) > 32 { counts[rowsFirst ? y : x] += 1 } } }
        guard let outer = divisions(counts, parts: rowsFirst ? rowCount : columnCount) else { return nil }
        var result: [Int: CGRect] = [:]
        for band in 0..<(rowsFirst ? rowCount : columnCount) {
            var innerCounts = [Int](repeating: 0, count: innerCount)
            for a in outer[band]..<outer[band+1] { for b in 0..<innerCount {
                if alpha(rowsFirst ? b : a, rowsFirst ? a : b) > 32 { innerCounts[b] += 1 }
            } }
            guard let inner = divisions(innerCounts, parts: rowsFirst ? columnCount : rowCount) else { return nil }
            for item in 0..<(rowsFirst ? columnCount : rowCount) {
                let row = rowsFirst ? band : item, column = rowsFirst ? item : band
                result[row*columnCount+column] = rowsFirst
                  ? CGRect(x: inner[item], y: outer[band], width: inner[item+1]-inner[item], height: outer[band+1]-outer[band])
                  : CGRect(x: outer[band], y: inner[item], width: outer[band+1]-outer[band], height: inner[item+1]-inner[item])
            }
        }
        return result
    }
    guard let rectangles = cells(rowsFirst: true) ?? cells(rowsFirst: false) else {
        fatalError("No safe gutters in \(sheet.lastPathComponent)")
    }
    let out = root.appendingPathComponent("symbols/"+symbolPrefix+sheet.deletingPathExtension().lastPathComponent)
    try fm.createDirectory(at: out, withIntermediateDirectories: true)
    for index in 0..<(rowCount * columnCount) {
            let rect = rectangles[index]!
            let cell = image.cropping(to: rect)!
            var clear = 0, solid = 0, nearlySolid = 0
            for y in Int(rect.minY)..<Int(rect.maxY) { for x in Int(rect.minX)..<Int(rect.maxX) {
                if alpha(x,y) == 0 { clear += 1 }; if alpha(x,y) == 255 { solid += 1 }; if alpha(x,y) >= 250 { nearlySolid += 1 }
            } }
            precondition(clear > Int(rect.width*rect.height*0.1) && nearlySolid > 100, "Missing transparency or artwork in \(sheet.lastPathComponent) cell \(index + 1)")
            let name = String(format: "%02d.png", index+1)
            let dest = CGImageDestinationCreateWithURL(out.appendingPathComponent(name) as CFURL, UTType.png.identifier as CFString, 1, nil)!
            CGImageDestinationAddImage(dest, cell, nil)
            precondition(CGImageDestinationFinalize(dest))
            report.append(["symbol": symbolPrefix+sheet.deletingPathExtension().lastPathComponent+"/"+name, "width": cell.width,"height":cell.height,"fullyTransparentPixels":clear,"fullyOpaquePixels":solid,"nearlyOpaquePixels":nearlySolid])
    }
    print("Extracted and verified transparency: \(sheet.lastPathComponent)")
}
try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted,.sortedKeys]).write(to: root.appendingPathComponent(expansion ? "expansion-alpha-validation.json" : "alpha-validation.json"))
print("Verified \(report.count) transparent symbols")
