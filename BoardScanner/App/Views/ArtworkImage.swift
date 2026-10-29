import SwiftUI

/// Display original artwork without adding a background to the symbol itself.
struct ArtworkImage: View {
    let image: UIImage

    var body: some View {
        Image(uiImage: image).resizable().scaledToFit()
    }
}
