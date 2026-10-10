import UIKit

struct ImportedPhoto: Identifiable {
    let id = UUID()
    let image: UIImage
    /// Prepared PNG data used by production persistence without re-encoding on the main actor.
    let pngData: Data
}
