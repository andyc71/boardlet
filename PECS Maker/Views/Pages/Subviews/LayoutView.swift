//
//  LayoutView.swift
//  PECS Maker
//
//  Created by Andy on 24/09/2021.
//

import SwiftUI
import SharedSwiftUI

struct LayoutView: View {
    let layout: PageLayoutType
    let aspectRatio: CGFloat
    let cardSize: Measurements?
    let isSelected: Bool
    let title: String?
    let titleHeightFraction: CGFloat

    var body: some View {
        VStack(spacing: 7) {
            PageGridPreview(
                layout: layout,
                aspectRatio: aspectRatio,
                isSelected: isSelected,
                title: title,
                titleHeightFraction: titleHeightFraction
            )
            .frame(height: 84)

            VStack(spacing: 2) {
                Text("\(layout.width) × \(layout.height)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(isSelected ? Color.mfVeryBrightBlue : Color.primary)

                Text(layout.localizedCellCount)
                    .font(.caption)
                    .foregroundStyle(isSelected ? Color.mfVeryBrightBlue : Color.secondary)

                if let cardSize {
                    Text(cardSize.formatAs(measurementType: .mm))
                        .font(.caption2)
                        .foregroundStyle(isSelected ? Color.mfVeryBrightBlue : Color.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(isSelected ? Color.mfVeryBrightBlue.opacity(0.08) : Color(uiColor: .systemBackground))
        .overlay {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(isSelected ? Color.mfVeryBrightBlue : Color(uiColor: .separator).opacity(0.28),
                        lineWidth: isSelected ? 1.5 : 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

private struct PageGridPreview: View {
    let layout: PageLayoutType
    let aspectRatio: CGFloat
    let isSelected: Bool
    let title: String?
    let titleHeightFraction: CGFloat

    var body: some View {
        Canvas { context, size in
            let color = isSelected ? Color.mfVeryBrightBlue : Color(uiColor: .secondaryLabel)
            let pageBounds = CGRect(origin: .zero, size: size).insetBy(dx: 0.75, dy: 0.75)
            let titleHeight = title == nil ? 0 : pageBounds.height * titleHeightFraction
            let titleBounds = CGRect(x: pageBounds.minX, y: pageBounds.minY,
                                     width: pageBounds.width, height: titleHeight)
            let contentBounds = CGRect(x: pageBounds.minX, y: pageBounds.minY + titleHeight,
                                       width: pageBounds.width, height: pageBounds.height - titleHeight)
            let gridBounds = gridBounds(in: contentBounds)
            if let title {
                let label = title.isEmpty ? L10n.FormattingView.BoardSection.title : title
                var titleContext = context
                titleContext.clip(to: Path(titleBounds.insetBy(dx: 2, dy: 0)))
                let text = context.resolve(
                    Text(label)
                        .font(.system(size: titleHeight * 0.65, weight: .semibold))
                        .foregroundColor(color)
                )
                let textSize = text.measure(in: CGSize(width: .greatestFiniteMagnitude,
                                                       height: titleHeight))
                let scale = min(1, max(0, titleBounds.width - 4) / max(1, textSize.width))
                titleContext.translateBy(x: titleBounds.midX, y: titleBounds.midY)
                titleContext.scaleBy(x: scale, y: scale)
                titleContext.draw(text, at: .zero)
            }
            let showsInsetCards = gridBounds != pageBounds

            context.stroke(
                Path(pageBounds),
                with: .color(showsInsetCards ? color.opacity(0.35) : color),
                lineWidth: 1.5
            )
            if showsInsetCards {
                context.stroke(Path(gridBounds), with: .color(color), lineWidth: 1.5)
            }

            if layout.width > 1 {
                for column in 1..<layout.width {
                    let x = gridBounds.minX
                        + gridBounds.width * CGFloat(column) / CGFloat(layout.width)
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: gridBounds.minY))
                    path.addLine(to: CGPoint(x: x, y: gridBounds.maxY))
                    context.stroke(path, with: .color(color), lineWidth: 1)
                }
            }

            if layout.height > 1 {
                for row in 1..<layout.height {
                    let y = gridBounds.minY
                        + gridBounds.height * CGFloat(row) / CGFloat(layout.height)
                    var path = Path()
                    path.move(to: CGPoint(x: gridBounds.minX, y: y))
                    path.addLine(to: CGPoint(x: gridBounds.maxX, y: y))
                    context.stroke(path, with: .color(color), lineWidth: 1)
                }
            }
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }

    private func gridBounds(in pageBounds: CGRect) -> CGRect {
        guard layout.fixedCardAspectRatio != nil else {
            return pageBounds
        }

        let cardSize = PageLayout.cardSize(pageSize: pageBounds.size, pageLayout: layout)

        let gridSize = CGSize(
            width: cardSize.width * CGFloat(layout.width),
            height: cardSize.height * CGFloat(layout.height)
        )
        return CGRect(
            x: pageBounds.midX - gridSize.width / 2,
            y: pageBounds.midY - gridSize.height / 2,
            width: gridSize.width,
            height: gridSize.height
        )
    }
}

extension PageLayoutType {
    var localizedCellCount: String {
        total == 1 ? L10n.LayoutScreen.oneCell : L10n.LayoutScreen.cellCount(total)
    }
}
