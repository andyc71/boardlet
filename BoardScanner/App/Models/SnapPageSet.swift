import Foundation

/// Pages form a graph: IDs preserve shared destinations, cycles and disconnected pages.
struct SnapPageSet: Codable, Sendable {
    var title: String
    var schemaVersion: String
    var homePageID: String
    var pages: [SnapPage]
    var buttons: [String: SnapButton] // ElementReferenceId, shared across layouts
    var assets: [String: SnapAsset]
    var backgroundARGB: UInt32? = nil

    func page(_ id: String) -> SnapPage? { pages.first { $0.id == id } }
    var linkCount: Int { buttons.values.reduce(0) { $0 + $1.destinationIDs.count } }
    var missingLinkCount: Int {
        let ids = Set(pages.map(\.id))
        return buttons.values.reduce(0) { $0 + $1.destinationIDs.filter { !ids.contains($0) }.count }
    }
    /// Only destinations used by the button's current behavior can block navigation.
    /// Keep missingLinkCount as the full source inventory for lossless import/export.
    var unavailableNavigationLinkCount: Int {
        let ids = Set(pages.map(\.id))
        return buttons.values.reduce(0) { count, button in
            let missing = button.destinationIDs.filter { !ids.contains($0) }.count
            guard missing > 0, SnapCommunicationBehavior.resolve(button) == .destinations else { return count }
            return count + missing
        }
    }
    var unavailableImageCount: Int {
        buttons.values.filter { button in
            guard let key = button.assetKey else { return false }
            return assets[key]?.previewPNG == nil
        }.count
    }

    var renderedAssetCount: Int { assets.values.filter { $0.previewPNG != nil }.count }
    var unavailableAssetCount: Int { assets.count - renderedAssetCount }
    var missingAssetReferenceCount: Int {
        buttons.values.filter { button in
            guard let key = button.assetKey else { return false }
            return assets[key] == nil
        }.count
    }

    func validate() throws {
        guard !pages.isEmpty, pages.count <= 5_000, buttons.count <= 100_000,
              assets.count <= 100_000, Set(pages.map(\.id)).count == pages.count,
              page(homePageID) != nil else { throw ScanError.invalidPageSet }
        var placementCount = 0
        for page in pages {
            guard !page.id.isEmpty, page.layouts.count <= 100,
                  Set(page.layouts.map(\.id)).count == page.layouts.count else { throw ScanError.invalidPageSet }
            for layout in page.layouts {
                guard (1...128).contains(layout.columns), (1...128).contains(layout.rows),
                      Set(layout.placements.map(\.id)).count == layout.placements.count else { throw ScanError.invalidPageSet }
                placementCount += layout.placements.count
                guard placementCount <= 200_000 else { throw ScanError.invalidPageSet }
                for placement in layout.placements {
                    guard placement.column >= 0, placement.row >= 0,
                          placement.columnSpan > 0, placement.rowSpan > 0,
                          placement.columnSpan <= 128, placement.rowSpan <= 128,
                          placement.column <= 256 - placement.columnSpan,
                          placement.row <= 256 - placement.rowSpan else { throw ScanError.invalidPageSet }
                }
            }
        }
        for asset in assets.values {
            guard asset.data.count <= 40_000_000, (asset.previewPNG?.count ?? 0) <= 10_000_000 else {
                throw ScanError.invalidPageSet
            }
        }
    }
}
