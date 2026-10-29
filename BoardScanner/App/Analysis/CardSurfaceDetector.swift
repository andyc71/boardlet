import Foundation

/// Finds filled card surfaces against a common surrounding color, including sparse boards.
/// Unlike full-image line projections, empty areas cannot become giant grid boundaries.
struct CardSurfaceDetector {
    static func detect(_ raster: RasterImage) throws -> GridDetector.Grid? {
        let (pixels, width, height) = try raster.grayscale()
        var histogram = [Int](repeating: 0, count: 32)
        for x in 0..<width {
            histogram[Int(pixels[x]) / 8] += 1
            histogram[Int(pixels[(height - 1) * width + x]) / 8] += 1
        }
        for y in 0..<height {
            histogram[Int(pixels[y * width]) / 8] += 1
            histogram[Int(pixels[y * width + width - 1]) / 8] += 1
        }
        guard let backgroundBin = histogram.indices.max(by: { histogram[$0] < histogram[$1] }) else { return nil }
        let background = backgroundBin * 8 + 4
        var visited = [Bool](repeating: false, count: pixels.count)
        var rectangles: [CGRect] = []
        for start in pixels.indices {
            if start % (width * 40) == 0 { try Task.checkCancellation() }
            guard !visited[start], abs(Int(pixels[start]) - background) > 24 else { continue }
            var queue = [start]
            visited[start] = true
            var cursor = 0
            var minX = start % width, maxX = minX
            var minY = start / width, maxY = minY
            while cursor < queue.count {
                let position = queue[cursor]
                cursor += 1
                let x = position % width, y = position / width
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
                for neighbor in [x > 0 ? position - 1 : -1, x + 1 < width ? position + 1 : -1,
                                 y > 0 ? position - width : -1, y + 1 < height ? position + width : -1] {
                    if neighbor >= 0, !visited[neighbor], abs(Int(pixels[neighbor]) - background) > 24 {
                        visited[neighbor] = true
                        queue.append(neighbor)
                    }
                }
            }
            let boxWidth = maxX - minX + 1, boxHeight = maxY - minY + 1
            let fill = Double(queue.count) / Double(boxWidth * boxHeight)
            guard Double(boxWidth) > Double(width) * 0.045, Double(boxHeight) > Double(height) * 0.045,
                  fill > 0.55, boxWidth < width / 2, boxHeight < height / 2 else { continue }
            rectangles.append(CGRect(x: Double(minX) / Double(width), y: Double(minY) / Double(height),
                                     width: Double(boxWidth) / Double(width), height: Double(boxHeight) / Double(height)))
        }
        // Several matching surfaces are required to distinguish a grid from isolated artwork.
        guard rectangles.count >= 6 else { return nil }
        return GridDetector.infer(rectangles, method: "Card surfaces", preserveEmptyCells: true)
    }
}
