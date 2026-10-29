import Foundation
import Vision

struct CardTextRecognizer {
    /// Small labels can be missed in whole-board OCR. Retry a single card at a readable scale.
    static func recognize(in cell: CGRect, raster: RasterImage, language: String? = nil) throws -> [TextRegion] {
        let crop = try RasterImage(data: raster.png(crop: cell))
        let scale = max(1, 480.0 / Double(crop.image.width))
        let width = Int(Double(crop.image.width) * scale)
        let height = Int(Double(crop.image.height) * scale)
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8,
                                      bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { throw ScanError.invalidImage }
        context.interpolationQuality = .high
        context.draw(crop.image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else { throw ScanError.invalidImage }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        request.automaticallyDetectsLanguage = true
        request.minimumTextHeight = 0.04
        let handler = VNImageRequestHandler(cgImage: image)
        try handler.perform([request])
        if request.results?.isEmpty != false {
            // The accurate model sometimes rejects very short words. The fast model uses
            // a different recognizer and can recover them; retain its actual confidence.
            request.recognitionLevel = .fast
            request.automaticallyDetectsLanguage = false
            if let language, let supported = try request.supportedRecognitionLanguages().first(where: {
                $0 == language || $0.hasPrefix(language + "-")
            }) {
                request.recognitionLanguages = [supported]
            }
            try handler.perform([request])
        }
        return (request.results ?? []).compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else { return nil }
            let local = CGRect.fromVision(observation.boundingBox)
            return TextRegion(text: candidate.string, confidence: candidate.confidence,
                              bounds: CGRect(x: cell.minX + local.minX * cell.width, y: cell.minY + local.minY * cell.height,
                                             width: local.width * cell.width, height: local.height * cell.height))
        }
    }
}
