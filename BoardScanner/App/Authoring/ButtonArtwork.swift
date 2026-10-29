import UIKit

struct ButtonArtwork {
    @MainActor static func symbol(_ symbol: BuiltinSymbol) throws -> Data {
        guard let image = UIImage(systemName: symbol.name, withConfiguration: UIImage.SymbolConfiguration(pointSize: 170, weight: .regular))?
            .withTintColor(.systemIndigo, renderingMode: .alwaysOriginal) else { throw AuthoringError.invalidImage }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let scale = min(192 / image.size.width, 192 / image.size.height)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let rendered = UIGraphicsImageRenderer(size: CGSize(width: 224, height: 224), format: format).image { _ in
            image.draw(in: CGRect(x: (224 - size.width) / 2, y: (224 - size.height) / 2, width: size.width, height: size.height))
        }
        guard let data = rendered.pngData() else { throw AuthoringError.invalidImage }
        return data
    }

    @concurrent static func normalize(_ data: Data) async throws -> Data {
        try Task.checkCancellation()
        let result = try RasterImage(data: data, maximumDimension: 512).png()
        try Task.checkCancellation()
        return result
    }
}
