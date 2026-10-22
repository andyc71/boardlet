import SwiftUI

struct TopicLayoutRecommendationPreview: View {
    let recommendation: TopicLayoutRecommendation
    let columns: Int
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Canvas { context, size in
                let gap: CGFloat = 3
                let ratio = recommendation.aspectRatio
                let width = min((size.width - CGFloat(columns - 1) * gap) / CGFloat(columns),
                                (size.height - gap) / 2 * ratio)
                let height = width / ratio
                let left = (size.width - CGFloat(columns) * (width + gap) + gap) / 2
                let top = (size.height - 2 * height - gap) / 2
                for row in 0..<2 {
                    for column in 0..<columns {
                        let rect = CGRect(x: left + CGFloat(column) * (width + gap),
                                          y: top + CGFloat(row) * (height + gap),
                                          width: width, height: height)
                        context.stroke(Path(roundedRect: rect, cornerRadius: 2),
                                       with: .color(isSelected ? .accentColor : .secondary), lineWidth: 1)
                    }
                }
            }
            .frame(height: 84)
            .accessibilityHidden(true)
            Text(columns == 1 ? L10n.LayoutScreen.oneColumn : L10n.LayoutScreen.columns(columns))
                .font(.subheadline.weight(.semibold))
            Text(recommendation.aspectRatio == 1 ? L10n.LayoutScreen.square : L10n.LayoutScreen.tallRectangle)
                .font(.caption)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.accentColor.opacity(0.08) : Color(uiColor: .secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: 13))
        .overlay {
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: 1.5)
        }
        .accessibilityElement(children: .combine)
    }
}
