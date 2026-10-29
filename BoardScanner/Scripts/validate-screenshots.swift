import Foundation
import Vision

/// Compile with the app's Analysis sources and its plain model files (see README).
@main
struct ScreenshotValidation {
    static func main() async throws {
        let arguments = CommandLine.arguments
        guard arguments.count == 3 else {
            print("Usage: validate-screenshots <input-directory> <output-directory>")
            return
        }
        let input = URL(fileURLWithPath: arguments[1])
        let output = URL(fileURLWithPath: arguments[2])
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        let files = try FileManager.default.contentsOfDirectory(at: input, includingPropertiesForKeys: nil)
            .filter { ["jpg", "png", "jpeg"].contains($0.pathExtension.lowercased()) }.sorted { $0.lastPathComponent < $1.lastPathComponent }
        for file in files {
            let data = try Data(contentsOf: file)
            let destination = output.appendingPathComponent(file.deletingPathExtension().lastPathComponent)
            try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
            do {
                let board = try await BoardAnalyzer.analyze(data: data)
                try board.validate()
                try JSONEncoder().encode(board).write(to: destination.appendingPathComponent("board.boardscan"))
                let labels = board.cards.map { "\($0.row),\($0.column)\t\($0.included ? "present" : "empty")\t\($0.needsReview ? "review" : "ok")\t\($0.label)" }.joined(separator: "\n")
                try labels.write(to: destination.appendingPathComponent("labels.tsv"), atomically: true, encoding: .utf8)
                for card in board.cards {
                    if card.included && card.label.isEmpty {
                        let diagnostic = try CardTextRecognizer.recognize(in: card.bounds, raster: RasterImage(data: data))
                        print("UNREAD \(card.row),\(card.column) local=\(diagnostic.map(\.text))")
                    }
                    try card.imagePNG.write(to: destination.appendingPathComponent("card-\(card.row)-\(card.column).png"))
                }
                print("\(file.lastPathComponent): \(board.rows)x\(board.columns), \(board.cards.filter(\.included).count) present, \(board.cards.filter(\.needsReview).count) review, \(board.method)")
                print(labels)
            } catch {
                print("\(file.lastPathComponent): FAILED \(error)")
            }
            let raster = try RasterImage(data: data)
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.automaticallyDetectsLanguage = true
            try VNImageRequestHandler(cgImage: raster.image).perform([request])
            let regions = (request.results ?? []).compactMap { observation -> String? in
                guard let text = observation.topCandidates(1).first else { return nil }
                return "\(text.string)\t\(text.confidence)\t\(CGRect.fromVision(observation.boundingBox))"
            }
            try regions.joined(separator: "\n").write(to: destination.appendingPathComponent("ocr.tsv"), atomically: true, encoding: .utf8)
        }
    }
}
