import SwiftUI
import SharedSwiftUI

/// A small, decorative board that connects the digital and printed choices visually.
struct WelcomeArtwork: View {
    private let symbols = ["sun.max.fill", "heart.fill", "leaf.fill", "cup.and.saucer.fill"]
    private let colors: [Color] = [.orange, .pink, .green, .blue]

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Theme.selectionHighlightColor.opacity(0.65))
                .frame(width: 270, height: 146)
            board(isPaper: true)
                .rotationEffect(.degrees(12))
                .offset(x: 58, y: 5)
            board(isPaper: false)
                .rotationEffect(.degrees(-9))
                .offset(x: -48, y: -3)
            Image(systemName: "sparkle")
                .font(.title2)
                .foregroundStyle(Color.mfVeryBrightBlue)
                .offset(x: 123, y: -64)
            Image(systemName: "sparkle")
                .font(.caption)
                .foregroundStyle(Color.mfVeryBrightBlue)
                .offset(x: -133, y: 48)
        }
    }

    private func board(isPaper: Bool) -> some View {
        VStack(spacing: 9) {
            Capsule().fill(isPaper ? Color.gray.opacity(0.3) : Color.white.opacity(0.5))
                .frame(width: 34, height: 4)
            LazyVGrid(columns: [GridItem(.fixed(47)), GridItem(.fixed(47))], spacing: 7) {
                ForEach(symbols.indices, id: \.self) { index in
                    VStack(spacing: 5) {
                        Image(systemName: symbols[index])
                            .font(.system(size: 22))
                            .foregroundStyle(colors[index])
                        Capsule().fill(Color.black.opacity(0.12)).frame(width: 23, height: 3)
                    }
                    .frame(width: 47, height: 48)
                    .background(colors[index].opacity(0.10), in: RoundedRectangle(cornerRadius: 7))
                    .background(.white, in: RoundedRectangle(cornerRadius: 7))
                }
            }
        }
        .padding(12)
        .background(isPaper ? Color.white : Color.mfVeryBrightBlue,
                    in: RoundedRectangle(cornerRadius: isPaper ? 8 : 19))
        .overlay {
            RoundedRectangle(cornerRadius: isPaper ? 8 : 19)
                .strokeBorder(Color.black.opacity(0.07), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 8)
        .frame(width: 125)
    }
}
