import SwiftUI

/// Native positioning keeps rendered cells, touch targets and accessibility
/// frames in the same coordinate space when a scroll view changes safe areas.
struct SourceGridLayout<Content: View>: View {
    let size: CGSize
    @ViewBuilder let content: () -> Content

    var body: some View {
        ZStack(alignment: .topLeading) {
            content()
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
    }
}
