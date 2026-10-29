import Foundation

/// One preview per embedded asset, reused by every button. The caller is the
/// @concurrent importer/document opener; no UI objects or global caches are used.
enum SnapArtwork {
    static func preview(_ data: Data) throws -> SnapAsset {
        try Task.checkCancellation()
        do {
            let png = try MetafileRenderer.isMetafile(data)
                ? MetafileRenderer.png(data)
                : RasterImage(data: data, maximumDimension: 256).png()
            return SnapAsset(data: data, previewPNG: png)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            return SnapAsset(data: data, previewPNG: nil, previewFailure: String(describing: error))
        }
    }

    static func regenerateMissingPreviews(_ set: inout SnapPageSet) throws {
        for key in set.assets.keys.sorted() {
            try Task.checkCancellation()
            guard let asset = set.assets[key], asset.previewPNG == nil,
                  MetafileRenderer.isMetafile(asset.data) else { continue }
            set.assets[key] = try preview(asset.data)
        }
    }
}
