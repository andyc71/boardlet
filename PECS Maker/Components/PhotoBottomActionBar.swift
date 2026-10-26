import SwiftUI

struct PhotoBottomActionBar<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack(spacing: 0) { content }
            .padding(.vertical, 8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.secondary.opacity(0.3)))
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
    }
}

