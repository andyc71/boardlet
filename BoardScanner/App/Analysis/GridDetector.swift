import Foundation

struct GridDetector {
    struct Grid {
        var cells: [CGRect]
        var rows: Int
        var columns: Int
        var method: String
        var occupied: [Bool]? = nil
    }

    /// Repeated long dark lines are stronger evidence than individual symbol rectangles.
    static func edgeCells(_ raster: RasterImage) throws -> [CGRect] {
        let (pixels, width, height) = try raster.grayscale()
        var vertical = [Double](repeating: 0, count: width)
        var horizontal = [Double](repeating: 0, count: height)
        for y in 0..<height {
            if y % 50 == 0 { try Task.checkCancellation() }
            for x in 0..<width where pixels[y * width + x] < 165 {
                vertical[x] += 1 / Double(height)
                horizontal[y] += 1 / Double(width)
            }
        }
        let xs = peaks(vertical)
        let ys = peaks(horizontal)
        guard xs.count >= 2, ys.count >= 2, xs.count <= 30, ys.count <= 30 else { return [] }
        var cells: [CGRect] = []
        for (x1, x2) in zip(xs, xs.dropFirst()) where x2 - x1 >= Double(width) * 0.045 {
            for (y1, y2) in zip(ys, ys.dropFirst()) where y2 - y1 >= Double(height) * 0.045 {
                let ratio = (x2 - x1) / (y2 - y1)
                guard (0.3...3.2).contains(ratio) else { continue }
                cells.append(CGRect(x: x1 / Double(width), y: y1 / Double(height),
                                    width: (x2 - x1) / Double(width), height: (y2 - y1) / Double(height)))
            }
        }
        return cells
    }

    private static func peaks(_ values: [Double]) -> [Double] {
        let threshold = max(0.28, (values.max() ?? 0) * 0.64)
        var groups: [[Int]] = []
        for index in values.indices where values[index] >= threshold {
            if let last = groups.last?.last, index - last <= 3 {
                groups[groups.count - 1].append(index)
            } else { groups.append([index]) }
        }
        return groups.map { Double($0.reduce(0, +)) / Double($0.count) }
    }

    /// Select a repeated-size family, reject nested artwork, then reconstruct its row/column lattice.
    static func infer(_ candidates: [CGRect], method: String, preserveEmptyCells: Bool = false) -> Grid? {
        let valid = candidates.filter { $0.isUnitRect && $0.width > 0.045 && $0.height > 0.045 && $0.width * $0.height < 0.9 }
        var best: [CGRect] = []
        var bestScore = 0.0
        for seed in valid {
            var family: [CGRect] = []
            for rect in valid where abs(rect.width - seed.width) < seed.width * 0.22
                && abs(rect.height - seed.height) < seed.height * 0.22 {
                if !family.contains(where: { abs($0.midX - rect.midX) < seed.width * 0.35 && abs($0.midY - rect.midY) < seed.height * 0.35 }) {
                    family.append(rect)
                }
            }
            let score = Double(family.count) * seed.width * seed.height
            if family.count >= 2 && score > bestScore {
                best = family
                bestScore = score
            }
        }
        guard best.count >= 2 else { return nil }
        let width = median(best.map { Double($0.width) })
        let height = median(best.map { Double($0.height) })
        let xs = clusters(best.map { Double($0.midX) }, tolerance: width * 0.35)
        let ys = clusters(best.map { Double($0.midY) }, tolerance: height * 0.35)
        guard xs.count <= 12, ys.count <= 12, best.count >= Int(ceil(Double(xs.count * ys.count) * (preserveEmptyCells ? 0.2 : 0.65))),
              regular(xs, size: width), regular(ys, size: height) else { return nil }
        let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
        var cells: [CGRect] = []
        var occupied: [Bool] = []
        for y in ys {
            for x in xs {
                let match = best.first { abs(Double($0.midX) - x) < width * 0.35 && abs(Double($0.midY) - y) < height * 0.35 }
                let inferred = CGRect(x: x - width / 2, y: y - height / 2, width: width, height: height).intersection(unit)
                cells.append(match ?? inferred)
                occupied.append(match != nil)
            }
        }
        return Grid(cells: cells, rows: ys.count, columns: xs.count, method: method,
                    occupied: preserveEmptyCells ? occupied : nil)
    }

    private static func clusters(_ values: [Double], tolerance: Double) -> [Double] {
        var groups: [[Double]] = []
        for value in values.sorted() {
            if let group = groups.last, abs(value - median(group)) < tolerance {
                groups[groups.count - 1].append(value)
            } else { groups.append([value]) }
        }
        return groups.map(median)
    }

    private static func regular(_ centers: [Double], size: Double) -> Bool {
        let gaps = zip(centers, centers.dropFirst()).map { $1 - $0 }
        guard !gaps.isEmpty else { return true }
        let typical = median(gaps)
        return gaps.allSatisfy { $0 > size * 0.7 && abs($0 - typical) < typical * 0.25 }
    }

    private static func median(_ values: [Double]) -> Double { values.sorted()[values.count / 2] }
}
