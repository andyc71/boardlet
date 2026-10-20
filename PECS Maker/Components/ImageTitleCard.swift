import SwiftUI
import SettingsFramework

/// Shared presentation for topic thumbnails and editable board cards.
struct ImageTitleCard: View {
    let image: UIImage?
    let title: String?
    var isTextOnly = false
    var isEmpty = false
    var squareImage = true
    var size: CGSize?
    var fillColor: Color = .white
    var titleColor: Color = .black
    var titleFont: Font = .caption
    var titlePosition: TopBottomPosition = .bottom
    var titleLineLimit = 2
    var isSelected = false

    private let shape = RoundedRectangle(cornerRadius: 10)

    var body: some View {
        Group {
            if isTextOnly {
                titleView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 4) {
                    if titlePosition == .top { titleView }
                    if squareImage {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                            .overlay { imageView }
                    } else {
                        imageView
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    if titlePosition == .bottom { titleView }
                }
            }
        }
        .padding(8)
        .frame(width: size?.width, height: size?.height)
        .background(fillColor, in: shape)
        .overlay {
            shape.strokeBorder(Color.secondary.opacity(0.7), lineWidth: 1.5)
        }
        .overlay {
            if isSelected {
                shape.fill(Color.accentColor.opacity(0.18))
                shape.strokeBorder(Color.accentColor, lineWidth: 2)
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.accentColor)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(shape)
    }

    @ViewBuilder
    private var imageView: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
        } else if isEmpty {
            Image(systemName: "plus")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var titleView: some View {
        if let title, !title.isEmpty {
            Text(title)
                .font(titleFont)
                .foregroundStyle(titleColor)
                .lineLimit(titleLineLimit, reservesSpace: squareImage)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
    }
}
