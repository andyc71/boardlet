import Foundation
import Vision
import NaturalLanguage

struct BoardAnalyzer {
    /// Explicitly leaves the UI actor; Vision requests and pixel buffers never cross actor boundaries.
    @concurrent static func analyze(data: Data, grid override: GridOverride? = nil) async throws -> ScannedBoard {
        try Task.checkCancellation()
        let raster = try RasterImage(data: data)
        let handler = VNImageRequestHandler(cgImage: raster.image, options: [:])
        let grid: GridDetector.Grid
        if let override {
            guard (1...12).contains(override.rows), (1...12).contains(override.columns),
                  override.cells.allSatisfy(\.isUnitRect) else { throw ScanError.invalidBoard }
            grid = GridDetector.Grid(cells: override.cells, rows: override.rows,
                                     columns: override.columns, method: "Manual grid")
        } else if let detected = try CardSurfaceDetector.detect(raster) {
            grid = detected
        } else if let detected = GridDetector.infer(try GridDetector.edgeCells(raster), method: "Repeated edges") {
            grid = detected
        } else {
            let rectangles = VNDetectRectanglesRequest()
            rectangles.maximumObservations = 0
            rectangles.minimumSize = 0.045
            rectangles.minimumAspectRatio = 0.25
            rectangles.maximumAspectRatio = 1
            rectangles.minimumConfidence = 0.45
            rectangles.quadratureTolerance = 12
            try handler.perform([rectangles])
            try Task.checkCancellation()
            var candidates = (rectangles.results ?? []).map { CGRect.fromVision($0.boundingBox) }
            if let detected = GridDetector.infer(candidates, method: "Vision rectangles") {
                grid = detected
            } else {
                let contours = VNDetectContoursRequest()
                contours.maximumImageDimension = 1024
                contours.detectsDarkOnLight = true
                try handler.perform([contours])
                try Task.checkCancellation()
                if let observation = contours.results?.first {
                    for index in 0..<min(observation.contourCount, 4000) {
                        let contour = try observation.contour(at: index)
                        let path = contour.normalizedPath
                        let bounds = path.boundingBoxOfPath
                        guard bounds.width > 0.045, bounds.height > 0.045 else { continue }
                        // Rectangular contours have most of their path points near a bounding edge.
                        let points = contour.normalizedPoints
                        let nearEdge = points.filter { point in
                            let x = Double(point.x), y = Double(point.y)
                            return min(abs(x - bounds.minX), abs(x - bounds.maxX)) < bounds.width * 0.06
                                || min(abs(y - bounds.minY), abs(y - bounds.maxY)) < bounds.height * 0.06
                        }
                        if Double(nearEdge.count) / Double(max(1, points.count)) > 0.85 {
                            candidates.append(CGRect.fromVision(bounds))
                        }
                    }
                }
                guard let detected = GridDetector.infer(candidates, method: "Vision rectangles + contours") else {
                    throw ScanError.noGrid
                }
                grid = detected
            }
        }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        request.minimumTextHeight = 0.006
        try handler.perform([request])
        try Task.checkCancellation()
        let text = (request.results ?? []).compactMap { observation -> TextRegion? in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            return TextRegion(text: candidate.string, confidence: candidate.confidence,
                              bounds: .fromVision(observation.boundingBox))
        }
        let language = NLLanguageRecognizer.dominantLanguage(for: text.map(\.text).joined(separator: " "))?.rawValue
        var cards: [ScannedCard] = []
        for (index, cell) in grid.cells.enumerated() {
            try Task.checkCancellation()
            let occupied = grid.occupied?[index] ?? true
            var label = LabelExtractor.extract(in: cell, text: occupied ? text : [])
            if occupied && (label.label.isEmpty || label.confidence < 0.8) {
                let localText = try CardTextRecognizer.recognize(in: cell, raster: raster, language: language)
                let refined = LabelExtractor.extract(in: cell, text: localText)
                if !refined.label.isEmpty && (label.label.isEmpty || refined.confidence >= label.confidence) {
                    label = refined
                }
            }
            cards.append(ScannedCard(row: index / grid.columns, column: index % grid.columns,
                                     label: label.label, confidence: label.confidence, bounds: cell,
                                     pictureBounds: label.picture, imagePNG: try raster.png(crop: label.picture),
                                     needsReview: occupied && label.needsReview, included: occupied, isEmpty: !occupied))
        }
        return ScannedBoard(columns: grid.columns, rows: grid.rows, cards: cards,
                            sourcePNG: try raster.png(), method: grid.method)
    }

    @concurrent static func recrop(source: Data, card: ScannedCard) async throws -> ScannedCard {
        try Task.checkCancellation()
        guard card.pictureBounds.isUnitRect, card.bounds.contains(card.pictureBounds) else { throw ScanError.invalidBoard }
        var updated = card
        updated.imagePNG = try RasterImage(data: source).png(crop: card.pictureBounds)
        updated.needsReview = false
        return updated
    }
}
