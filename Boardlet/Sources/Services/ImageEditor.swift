import UIKit
import Vision
import CoreImage

actor ImageEditor {
    func crop(_ data: Data, x: Double, y: Double, width: Double, height: Double) throws -> Data {
        guard let image = UIImage(data: data) else { throw ImageImportError.invalidImage }
        // Crop the same orientation displayed by UIImage, including camera EXIF rotation.
        let format = UIGraphicsImageRendererFormat(); format.scale = image.scale
        let upright = UIGraphicsImageRenderer(size: image.size, format: format).image { _ in image.draw(at: .zero) }
        guard let cg = upright.cgImage else { throw ImageImportError.invalidImage }
        let rect = CGRect(x: x * Double(cg.width), y: y * Double(cg.height), width: width * Double(cg.width), height: height * Double(cg.height)).intersection(CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        guard rect.width >= 1, rect.height >= 1, let result = cg.cropping(to: rect), let png = UIImage(cgImage: result).pngData() else { throw ImageImportError.invalidImage }
        return png
    }
    @available(iOS 17, *)
    func removeBackground(_ data: Data) throws -> Data {
        let handler = VNImageRequestHandler(data: data)
        let request = VNGenerateForegroundInstanceMaskRequest()
        try handler.perform([request])
        guard let result = request.results?.first else { throw ImageImportError.invalidImage }
        let pixel = try result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: false)
        let image = CIImage(cvPixelBuffer: pixel)
        guard let cg = CIContext().createCGImage(image, from: image.extent), let png = UIImage(cgImage: cg).pngData() else { throw ImageImportError.invalidImage }
        return png
    }
}
