import SwiftUI

/// A populated board and a fresh picture card introduce the two starting points.
struct GetStartedArtwork: View {
    private let symbols = ["sun.max.fill", "heart.fill", "leaf.fill", "cup.and.saucer.fill"]
    private let colors: [Color] = [.orange, .pink, .green, .blue]

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Theme.selectionHighlightColor)
                .frame(width: 260, height: 126)

            RoundedRectangle(cornerRadius: 22)
                .fill(Theme.cardBackgroundColor)
                .frame(width: 120, height: 124)
                .rotationEffect(.degrees(-16))
                .offset(x: -43, y: 2)

            LazyVGrid(columns: [GridItem(.fixed(43)), GridItem(.fixed(43))], spacing: 8) {
                ForEach(symbols.indices, id: \.self) { index in
                    Image(systemName: symbols[index])
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(colors[index])
                        .frame(width: 43, height: 43)
                        .background(.white, in: RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(12)
            .frame(width: 118)
            .background(Color("mfBoardActionBlue"), in: RoundedRectangle(cornerRadius: 20))
            .rotationEffect(.degrees(-8))
            .shadow(color: Color.mfVeryBrightBlue.opacity(0.16), radius: 10, y: 6)
            .offset(x: -29, y: -5)

            Image(systemName: "plus")
                .font(.system(size: 30, weight: .medium, design: .rounded))
                .foregroundStyle(Color("mfBoardActionBlue"))
                .frame(width: 68, height: 78)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.mfVeryBrightBlue.opacity(0.22), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                }
                .rotationEffect(.degrees(10))
                .shadow(color: Color.mfVeryBrightBlue.opacity(0.12), radius: 8, y: 5)
                .offset(x: 65, y: 22)

            Image(systemName: "sparkle")
                .font(.title3)
                .foregroundStyle(Color.mfVeryBrightBlue)
                .offset(x: 100, y: -48)
        }
    }
}
